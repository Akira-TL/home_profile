#!/usr/bin/env python
# -*- encoding: utf-8 -*-
import sys
import time
import subprocess


def main():
    if len(sys.argv) < 1:
        print("用法: time.py <命令> [参数...]")
        sys.exit(1)

    command = sys.argv[1:]
    start_time = time.time()  # 记录开始时间

    # 执行命令
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()

    end_time = time.time()  # 记录结束时间
    elapsed_time = end_time - start_time  # 计算耗时

    # 输出命令的标准输出和标准错误
    sys.stdout.write(stdout.decode())
    sys.stderr.write(stderr.decode())

    # 输出执行时间
    print(f"\n程序执行时间：{elapsed_time:.6f} 秒")


if __name__ == "__main__":
    main()
