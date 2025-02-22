#!/bin/bash
# alias sgl=singularity
alias qiime2='conda activate qiime2'
# alias et='echo OK'

## get rid of command not found ##
alias cd..='cd ..'

## a quick way to get out of current directory ##
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias .1='cd ../'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'

alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'
alias pron='. proxy.sh on'
alias proff='. proxy.sh off'
alias proxy='. proxy.sh $*'
alias ping='ping -c 4 $*'
alias wsl='ssh akiratl@$(last | grep tanlang | head -n 1 | awk '\''NR==1 {print $3}'\'' ) -p 22222  -i ~/.ssh/id_rsa $*'
alias win='ssh akiratl@$(last | grep tanlang | head -n 1 | awk '\''NR==1 {print $3}'\'' ) -p 22  -i ~/.ssh/id_rsa $*'
alias aria='aria2c -s 16 -x 16 --check-certificate=false -c $*'

alias t='top -d 1 -i -c $*'
alias n='ncdu --color dark --exclude-kernfs $*'
alias r='radian'
alias c='clear'
alias h='history'

alias pi='pip install $*'
alias pu='pip uninstall $*'
alias ca='conda activate base'
alias cda='conda deactivate'
alias mm='make -j && make install'
alias ht='htop $*'
# alias python=python3
# alias pip=pip3
alias l='ls -lah --group-directories-first $*'
alias ll='ls -lh --group-directories-first $*'
alias lt='ls -ltah --group-directories-first $*'
alias llt='ls -lth --group-directories-first $*'

alias gc='git clone $*'

alias da='deactivate'
va() {
    if [ $# -eq 0 ]; then
        source env/bin/activate
    else
        source $@/bin/activate
    fi
}
pv() {
    if [ $# -eq 0 ]; then
        python -m venv "__venv_env__"
        echo -n "export VENV_VIRTUAL_ENV=env" >>'__venv_env__/bin/activate'
        sed -i '/    unset VIRTUAL_ENV/c\    unset VIRTUAL_ENV VENV_VIRTUAL_ENV' '__venv_env__/bin/activate'
    else
        python -m venv "__venv_$1__"
        echo -n "export VENV_VIRTUAL_ENV=$1" >>'__venv_'$1'__/bin/activate'
        sed -i '/    unset VIRTUAL_ENV/c\    unset VIRTUAL_ENV VENV_VIRTUAL_ENV' '__venv_'$1'__/bin/activate'
    fi
}
# 自动记录函数，用来记录输出到指定文件
mtee() {
    "$@" 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $logf
}
alias aa='an -a $logf -c '"'$(h | grep -v "^\s*[0-9][*] " | tail -n 1)'"'&& export logf="${HOME}/.shell_log/pts$(tty | cut -d'/' -f4)_$(date +%Y-%m-%d_%H:%M:%S).log"'
