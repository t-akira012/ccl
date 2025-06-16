#!/bin/bash

# Claude Code会話ログ一覧表示
# Usage: ./list-chats.sh [yyyymmdd]

LOG_DIR="/Users/t-akira012/tmp/claude-code-log"

if [ -n "$1" ]; then
    TARGET_DATE="$1"
else
    TARGET_DATE=$(date +%Y%m%d)
fi

DATE_DIR="$LOG_DIR/$TARGET_DATE"

if [ ! -d "$DATE_DIR" ]; then
    echo "指定日のログディレクトリが見つかりません: $DATE_DIR"
    echo ""
    echo "利用可能な日付:"
    ls -1 "$LOG_DIR" | grep -E '^[0-9]{8}$' | sort -r | head -10
    exit 1
fi

echo "=== $TARGET_DATE の会話ログ ==="
echo ""

if [ -z "$(ls -A "$DATE_DIR"/*.md 2>/dev/null)" ]; then
    echo "この日の会話ログはありません。"
    exit 0
fi

for file in "$DATE_DIR"/*.md; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file" .md)
        echo "📝 $basename_file"
        
        # ファイルの最初の数行から情報を抽出
        head -10 "$file" | grep -E "^\*\*Date\*\*:" | sed 's/\*\*Date\*\*: /  作成日時: /'
        head -10 "$file" | grep -E "^\*\*Topics\*\*:" | sed 's/\*\*Topics\*\*: /  トピック: /'
        
        echo "  ファイル: $file"
        echo ""
    fi
done

echo ""
echo "合計: $(ls -1 "$DATE_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')件の会話ログ"