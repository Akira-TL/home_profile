#!/bin/bash

logf="${HOME}/.shell_log/pts$(tty | cut -d'/' -f4)_$(date +%Y-%m-%d_%H:%M:%S).log" # 单终端的临时输出文件
export logf
# 自动记录函数，用来记录输出到指定文件
mtee() {
    ts '[%Y-%m-%d %H:%M:%S]' | tee -a $logf
}
# 这里an链接到了py脚本上的
alias aa='an -a $logf -c '"'$(h | grep -v "^\s*[0-9][*] " | tail -n 1)'"'&& export logf="${HOME}/.shell_log/pts$(tty | cut -d'/' -f4)_$(date +%Y-%m-%d_%H:%M:%S).log"'
