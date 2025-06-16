#!/bin/bash

# 最新のログファイルを表示するスクリプト
# Usage: ./showlog.sh

LOG_DIR="$(cd "$(dirname "$0")" && pwd)"
DATE=$(date +%Y%m%d)
DATE_DIR="$LOG_DIR/$DATE"

# 今日のディレクトリが存在しない場合は、最新のディレクトリを探す
if [ ! -d "$DATE_DIR" ]; then
    # 最新の日付ディレクトリを取得
    LATEST_DATE_DIR=$(find "$LOG_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]" | sort -r | head -1)
    if [ -n "$LATEST_DATE_DIR" ]; then
        DATE_DIR="$LATEST_DATE_DIR"
    else
        echo "ログファイルが見つかりません"
        exit 1
    fi
fi

# 最新のログファイルを取得（更新時間順）
LATEST_LOG=$(find "$DATE_DIR" -name "*.md" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

if [ -z "$LATEST_LOG" ]; then
    echo "ログファイルが見つかりません: $DATE_DIR"
    exit 1
fi

echo "最新のログファイル: $LATEST_LOG"
echo "----------------------------------------"
cat "$LATEST_LOG"