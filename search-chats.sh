#!/bin/bash

# Claude Code会話ログ検索
# Usage: ./search-chats.sh [keyword]

LOG_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$1" ]; then
    echo "検索キーワードを指定してください:"
    read KEYWORD
    if [ -z "$KEYWORD" ]; then
        echo "キーワードが空です。"
        exit 1
    fi
else
    KEYWORD="$1"
fi

echo "=== '$KEYWORD' の検索結果 ==="
echo ""

FOUND_COUNT=0

# 日付ディレクトリを日付順（降順）で検索
for date_dir in $(ls -1d "$LOG_DIR"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] 2>/dev/null | sort -r); do
    date_name=$(basename "$date_dir")
    
    # 各日付ディレクトリ内のmdファイルを検索
    for file in "$date_dir"/*.md; do
        if [ -f "$file" ] && grep -qi "$KEYWORD" "$file"; then
            basename_file=$(basename "$file" .md)
            echo "📅 $date_name - 📝 $basename_file"
            
            # マッチした行を表示（前後1行含む）
            echo "  マッチした内容:"
            grep -i -A1 -B1 "$KEYWORD" "$file" | head -6 | sed 's/^/    /'
            echo ""
            
            ((FOUND_COUNT++))
        fi
    done
done

if [ $FOUND_COUNT -eq 0 ]; then
    echo "キーワード '$KEYWORD' に一致する会話ログが見つかりませんでした。"
    echo ""
    echo "利用可能な日付:"
    ls -1 "$LOG_DIR" | grep -E '^[0-9]{8}$' | sort -r | head -10
else
    echo ""
    echo "合計: $FOUND_COUNT 件の会話ログで見つかりました。"
fi
