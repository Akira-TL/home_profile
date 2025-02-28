#!/bin/bash

basepath=$(realpath $(dirname "$0"))
if [ $# -eq 0 ]; then
    p=$basepath
else
    p=.
fi
# 对当前文件的当前目录进行循环
for file in $(ls -a $p); do
    file=${file#$HOME/}
    # 如果是目录
    if [[ $file == .git* ]] || [[ $file == "init.sh" ]] || [[ $file == "." ]] || [[ $file == ".." ]] || [[ $file == backup* ]]; then
        continue
    fi
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
            if [ "$(stat -c '%d:%i' "$HOME/$filepath")" == "$(stat -c '%d:%i' "$a")" ]; then
                echo "文件存在且是硬链接到 $a"
            else
                echo "文件存在，但不是硬链接到 $a"
                backup_path=$basepath/backup$(date +%Y-%m-%d_%H_%M_%S)
                mkdir -p $backup_path/$(dirname $filepath)
                mv $HOME/$filepath $backup_path/$filepath
                echo 已备份到 $backup_path/$filepath
                ln $a $HOME/$filepath
                echo "ln -s $a $HOME/$filepath"
            fi
        fi
    fi
done
