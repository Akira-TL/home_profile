#!/usr/bin/env bash
set -euo pipefail

# 配置
WORK_DIR="$HOME/.downloader"
LOG_DIR="$WORK_DIR/logs"
LIST_PREFIX="$WORK_DIR/downloadList"
MAX_LINES=1000
START_HOUR=0      # 0点开始
END_HOUR=8        # 8点结束（可调整）
SLEEP_INTERVAL=60 # 检查间隔秒数
DEFAULT_MODE="aria2"
DATE_FMT="+%Y_%m_%d"
LOG_FILE="$LOG_DIR/$(date "$DATE_FMT").log"

mkdir -p "$WORK_DIR" "$LOG_DIR"

# 下载命令分派
download_file() {
    local mode="$1"
    local target="$2"
    local out_dir="$3"

    mkdir -p "$out_dir"
    case "$mode" in
    aria2)
        aria2c -x 8 -s 8 -d "$out_dir" "$target" >>"$LOG_FILE" 2>&1 && return 0
        ;;
    wget)
        wget -P "$out_dir" "$target" >>"$LOG_FILE" 2>&1 && return 0
        ;;
    curl)
        cd "$out_dir" && curl -LO "$target" >>"$LOG_FILE" 2>&1 && cd - >/dev/null
        return 0
        ;;
    *)
        echo "Unknown mode: $mode" >>"$LOG_FILE"
        return 1
        ;;
    esac
    return 1
}

run_cmd() {
    local cmd="$1"
    local work_dir="$2"
    mkdir -p "$work_dir"
    (cd "$work_dir" && bash -c "$cmd" >>"$LOG_FILE" 2>&1)
    return $?
}

# 处理列表文件分表
get_current_list_file() {
    local idx=0
    while true; do
        local list_file="${LIST_PREFIX}${idx}.csv"
        if [[ ! -f "$list_file" ]] || [[ $(wc -l <"$list_file") -lt $MAX_LINES ]]; then
            echo "$list_file"
            return
        fi
        ((idx++))
    done
}

# 检查当前时间是否在下载区间
is_in_time_range() {
    local hour
    hour=$(date +%H)
    if ((hour >= START_HOUR && hour < END_HOUR)); then
        return 0
    else
        return 1
    fi
}

# 主循环
main_loop() {
    while true; do
        if is_in_time_range; then
            echo "$(date): Checking download tasks..." >>"$LOG_FILE"
            # 遍历所有列表文件
            for list_file in "$WORK_DIR"/downloadList*.csv; do
                [[ -e "$list_file" ]] || continue
                local tmp_file="${list_file}.tmp"
                mv "$list_file" "$tmp_file"
                while IFS=, read -r mode target status out_dir; do
                    [[ "$status" == "done" ]] && echo "$mode,$target,$status,$out_dir" >>"$list_file" && continue
                    if [[ "$mode" == "cmd" ]]; then
                        run_cmd "$target" "$out_dir" &&
                            {
                                echo "$mode,$target,done,$out_dir" >>"$list_file"
                                echo "$(date): [OK-cmd] $target" >>"$LOG_FILE"
                            } ||
                            {
                                echo "$mode,$target,fail,$out_dir" >>"$list_file"
                                echo "$(date): [FAIL-cmd] $target" >>"$LOG_FILE"
                            }
                    else
                        download_file "$mode" "$target" "$out_dir" &&
                            {
                                echo "$mode,$target,done,$out_dir" >>"$list_file"
                                echo "$(date): [OK] $target" >>"$LOG_FILE"
                            } ||
                            {
                                echo "$mode,$target,fail,$out_dir" >>"$list_file"
                                echo "$(date): [FAIL] $target" >>"$LOG_FILE"
                            }
                    fi
                done <"$tmp_file"
                rm -f "$tmp_file"
            done
        fi
        echo "$(date): Sleeping for $SLEEP_INTERVAL seconds..." >>"$LOG_FILE"
        sleep "$SLEEP_INTERVAL"
    done
}

# 参数判断分支
# 命令行模式
if [[ "${1:-}" == "-c" ]]; then
    shift
    if [[ $# -lt 2 ]]; then
        echo "用法: $0 -c \"command\" workdir"
        exit 1
    fi
    cmd="$1"
    work_dir="$2"
    list_file=$(get_current_list_file)
    echo "cmd,$cmd,pending,$work_dir" >>"$list_file"
    echo "Added cmd task: $cmd -> $work_dir"
    exit 0
elif [[ $# -ge 2 ]]; then
    url="$1"
    if [[ $# -eq 3 ]]; then
        mode="$2"
        out_dir="$3"
    else
        mode="$DEFAULT_MODE"
        out_dir="$2"
    fi
    list_file=$(get_current_list_file)
    echo "$mode,$url,pending,$out_dir" >>"$list_file"
    echo "Added download task: $url -> $out_dir"
    exit 0
elif [[ $# -eq 0 ]]; then
    main_loop
elif [[ $# -lt 2 ]]; then
    echo "用法: $0 url [mode] out_dir"
    echo "例: $0 https://xx/file.zip aria2 /data/downloads"
    exit 1
fi
