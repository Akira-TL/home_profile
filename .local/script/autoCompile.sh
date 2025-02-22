#!/bin/bash


if [ $# -ne 1 ]; then
    echo "Usage: $0 [package_name]"
    exit 1
fi
package_name=$1

# 定义一个函数，用于根据首字母对字符串进行分类
classify() {
  # 获取字符串的第一个字符
  first=$(echo $1 | cut -c 1)
  # 判断第一个字符是否在a~k之间
  if [[ $first =~ [a-k] ]]; then
    # 如果是，就输出/a/字符串的形式
    echo "/$first/$1"
  # 判断第一个字符是否在m~z之间
  elif [[ $first =~ [m-z] ]]; then
    # 如果是，就输出/z/字符串的形式
    echo "/$first/$1"
  # 判断第一个字符是否是lib
  elif [[ $first == "l" && $(echo $1 | cut -c 1-3) == "lib" ]]; then
    # 如果是，就获取lib后面的第一个字符
    second=$(echo $1 | cut -c 4)
    # 判断第二个字符是否在a~z之间
    if [[ $second =~ [a-z] ]]; then
      # 如果是，就输出/libg/libgxxx的形式
      echo "/lib$second/$1"
    else
      # 如果不是，就输出无效输入的提示信息
      echo "/l/$1"
    fi
  else
    # 如果都不是，就输出无效输入的提示信息
    echo "Invalid input: $1"
  fi
}

url=https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/main
url=$url$(classify $package_name)
htmlPath=~/Downloads/$package_name.html
s="/?C=M&O=A"
wget -O $htmlPath $url$s
if [[  $? == "0" ]] ;then
  filename=$(grep -o "$package_name_[0-9.]*.[^\>]*.tar.xz" $htmlPath | grep -v " title=" | grep -v "debian" |tail -n 1)
  filename=${filename:1:`expr ${#filename} - 1`}
  url=$url/$filename
  rm $htmlPath
  wget -O ~/Downloads/$filename $url
  if [[  $? == "0" ]]; then
  echo ok
    installName=$(tar -tf ~/Downloads/$filename | awk -F "/" '{print $1}' | sort | uniq)
    mkdir ~/Archive/$installName
    cd ~/Archive
    tar -xf ~/Downloads/$filename
    echo $(test -e ~/Archive/$installName/configure)
    if test -e ~/Archive/$installName/configure; then
      # ~/Archive/$installName/configure --prefix=/home/$USER/.local/$package_name
      # make -j && make install
      echo  软件$package_name已安装到/home/$USER/.local/$package_name
    else
      echo "包没有配置文件（configure）是否删除已解压文件？(y/n)"
      read choice
      if [[ $choice == "y" ]]
      then
        rm -rf ~/Archive/$installName
      fi
    rm ~/Downloads/$filename
    fi
  else
    echo 没有合适的包
  fi
else
  echo 包不存在
fi
rm $htmlPath
