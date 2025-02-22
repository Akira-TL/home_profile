#!/bin/bash
# 获取登录IP地址
login_ip=$(last $(whoami) | grep -oP ".*(\d*\.\d*\.\d*\.\d*).*still logged in" | grep -oP "(\d*\.\d*\.\d*\.\d*)" | head -n 1)
# 设置代理端口
port=7899
tag=""
# 判断输入参数

ARGS=$(getopt -o si:p: -l status,ip:,port: -n "$0" -- "$@")
ARGS=$(echo $ARGS | tr -d "'")
eval set -- "${ARGS}"
while true; do
    case "$1" in
    -p | --port)
        shift
        port="$1"
        shift
        ;;
    -i | --ip)
        shift
        login_ip="$1"
        shift
        ;;
    -s | --status)
        if [ $proxy_status ]; then
            echo "代理服务已开启，地址：$login_ip:$port"
        else
            echo "代理服务已关闭"
        fi
        tag=true
        shift
        ;;
    --)
        # echo $ARGS
        shift
        break
        ;;
    *)
        shift
        echo "请输入正确参数！"
        exit 1
        ;;
    esac
done

if [ $tag ]; then
    true
elif [[ "$1" == "on" ]]; then
    # 启用代理
    export ALL_PROXY="http://$login_ip:$port/"
    export http_proxy="http://$login_ip:$port/"
    export https_proxy="http://$login_ip:$port/"
    export ftp_proxy="http://$login_ip:$port/"
    export no_proxy="127.0.0.1,localhost"
    # For curl
    export HTTP_PROXY="http://$login_ip:$port/"
    export HTTPS_PROXY="http://$login_ip:$port/"
    export FTP_PROXY="http://$login_ip:$port/"
    export NO_PROXY="127.0.0.1,localhost"
    proxy_status=true
    echo "代理已启用，地址：$login_ip:$port"
elif [[ "$1" == "off" ]]; then
    # 关闭代理
    unset ALL_PROXY https_proxy http_proxy ftp_proxy no_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY NO_PROXY proxy_status
    # unset https_proxy
    echo "代理已关闭"
else
    # 提示用法
    echo "用法：-p(可选) <端口> -i(可选) <ip> [ on | off ]"
fi
