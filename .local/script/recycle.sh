#!/bin/bash

trashbinPath=~/.trashbin/
tmp="$trashbinPath"tmp
log=$trashbinPath"log"
mkdir -p $trashbinPath
touch $tmp
touch $log

logcon="$*"

ARGS=$(getopt -o hlfcr -l help,list,force,clear,rollback,recycle,log -n "$0" -- "$@")
ARGS=$(echo $ARGS | tr -d "'")
eval set -- "${ARGS}"
ARGS=${ARGS#*--}

if [ $1 != "--" ]; then
    case "$1" in
    -r | --recycle)
        # 为防止习惯了使用-rf,和一些程序使用-rf,再加个判断
        if [[ $2 == "-f" ]]; then
            echo "多余参数-f"
            bash $0 -f $ARGS
            shift 2
        else
            # 判断参数是否是空的，空的就仅撤回一次，带有参数就根据参数撤回
            if [ "$ARGS" != "" ]; then
                for file in $ARGS; do
                    if [ "$(cat $tmp | wc -l)" -eq 0 ]; then
                        echo 无可撤回文件
                    else
                        # * 整行完全匹配并输出
                        # grep -Fx "$file" $tmp
                        roll=$(grep -Fxn "$(basename $file)" $tmp | cut -d : -f 1 | sort -r -n | head -n 1)
                        mv -i "$trashbinPath""$(sed -n "$(($roll - 1))p" $tmp)" "$(sed -n "$(($roll - 2))p" $tmp)"
                        if [ $? -eq 0 ]; then
                            name=$(sed -n "$roll""p" $tmp)
                            p=$(sed -n "$(($roll - 2))""p" $tmp)
                            sed -i "$(($roll - 2)),""$roll""d" $tmp
                            echo "已将$name""恢复到$p"
                        fi
                    fi
                done
            else
                roll=$(cat $tmp | wc -l)
                mv -i "$trashbinPath""$(sed -n "$(($roll - 1))""p" $tmp)" "$(sed -n "$(($roll - 2))""p" $tmp)"
                if [ $? -eq 0 ]; then
                    name=$(sed -n "$roll""p" $tmp)
                    p=$(sed -n "$(($roll - 2))""p" $tmp)
                    sed -i "$(($roll - 2)),""$roll""d" $tmp
                    echo "已将$name""恢复到$p"
                fi
            fi
            shift
        fi
        ;;
    --rollback)
        # *操作回滚 这里是根据日志内容进行回退，仅回退删除文件
        roll=$(cat $log | wc -l)
        for ((i = $roll; i >= 1; i--)); do
            str=$(sed -n "$i""p" $log | cut -c 1)
            if [[ $str != "*"* ]] && [[ $str != "-" ]]; then
                args=$(sed -n "$i""p" $log)
                sed -i "$i""d" $log
                bash $0 -r $args
                break
            fi
        done
        shift
        ;;
    --log)
        # 显示日志
        cat $log
        shift
        ;;
    -c | --clear)
        # 清空回收站
        if [ "$ARGS" == "" ]; then
            echo "确定清空回收站？(y/n)"
            read tag
            if [[ $tag == "y" ]]; then
                /bin/rm -rf ~/.trashbin/*
            fi
        else
            echo "请输入正确参数(-c 后不接参数)"
        fi
        shift
        ;;
    -f | --force)
        if [[ $2 == "-r" ]]; then
            echo "多余参数-r"
            bash $0 -f $ARGS
            shift 2
        else
            # 直接删除，不放入回收站
            if [ "$ARGS" != "" ]; then
                for file in $ARGS; do
                    /bin/rm -rf $file
                done
            else
                echo "请输入正确参数(-f 后必接参数)"
            fi
            shift
        fi
        ;;
    -l | --list)
        # 查看回收站内容
        ls $trashbinPath -lahI tmp -I log
        shift
        ;;
    -h | --help)
        echo "-r | --recycle [文件/文件夹](可选) 撤销最后一次所删除文件/指定文件"
        echo "--rollback 回滚操作"
        echo "--log 显示命令历史"
        echo "-c | --clear 清理回收站"
        echo "-f | --force [文件/文件夹](必选) 完全删除"
        echo "-l | --list 查看回收站内容"
        echo "-h | --help 显示当前内容"
        shift
        ;;
    --)
        echo $ARGS
        ;;
    *)
        shift
        echo "请输入正确参数！"
        # exit 1
        ;;
    esac
    if [ $1 != "--" ]; then
        echo 多余参数将会忽略
        while [ $1 != "--" ]; do
            echo $1
            shift
        done
    fi
else
    for file in $ARGS; do
        # 防止套娃
        if [[ $file == $(realpath $trashbinPath)* ]]; then
            echo 不能从回收站删除
        else
            p=$(realpath $file)
            name=$(basename $file)
            newname="$name-""$(date +"%y%m%d%H%M%S")" # 防止文件重复，有点小问题，就是怕同名并且同一时间删除，这里只精确到了秒
            # 存储很简单，就一行路径，一行别名，一行原名
            # path
            # fakename
            # realname
            # 2>/dev/null || :  抑制报错用根据需要安排
            mv $file $trashbinPath$newname # 2>/dev/null || :
            if [ $? -eq 0 ]; then
                echo $p >>$tmp
                echo $newname >>$tmp
                echo $name >>$tmp
            else
                echo "$file""不存在"
            fi
        fi
    done
fi

# 日志记录，希望不会出错吧
if [ $? -eq 0 ]; then
    echo "$logcon" >>$log
else
    echo "*$logcon" >>$log
fi
