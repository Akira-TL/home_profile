#!/bin/bash

basepath=$(realpath $(dirname "$0"))
if [ $# -eq 0 ]; then
    p=$basepath
    cd $p
else
    p=.
fi
# exit 0
# 对当前文件的当前目录进行循环
backup_path=$basepath/backup$(date +%Y-%m-%d_%H_%M_%S)
for file in $(ls -a $p); do
    file=${file#$HOME/}
    # 如果是目录
    [[ $file == ".gitignore" ]] || [[ $file == ".git" ]] || [[ $file == "init.sh" ]] || [[ $file == "." ]] || [[ $file == ".." ]] || [[ $file == backup* ]] && continue
    if [ -d $file ]; then
        # 进入目录
        a=$(realpath $file)
        echo "cd file: ${a#$basepath/}"
        cd $file
        # 执行脚本
        $basepath/init.sh _
        # 返回上级目录
        cd ..
    elif [ -f $file ]; then
        # 如果是文件
        a=$(realpath $file)
        filepath=${a#$basepath/}
        if [[ -f "$HOME/$filepath" ]]; then
            if [ "$(readlink "$HOME/$filepath")" == "$a" ]; then
                echo "文件存在且是软链接到 $a"
            else
                echo "文件存在，但不是软链接到 $a"
                mkdir -p $backup_path/$(dirname $filepath)
                mv $HOME/$filepath $backup_path/$filepath
                echo 已备份到 $backup_path/$filepath
                ln -s $a $HOME/$filepath
                echo "ln $a -s $HOME/$filepath"
            fi
        else
            echo "文件不存在，正在创建软链接"
            mkdir -p $HOME/$(dirname $filepath)
            ln -s $a $HOME/$filepath
            echo "ln -s $a $HOME/$filepath"
        fi
    fi
done
