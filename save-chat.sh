#!/bin/bash

# Claude Code会話ログ保存スクリプト
# Usage: ./save-chat.sh [chat-title] <<'CONTENT_EOF'
# conversation content here
# CONTENT_EOF

LOG_DIR="$(cd "$(dirname "$0")" && pwd)"
DATE=$(date +%Y%m%d)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_DIR="$LOG_DIR/$DATE"
# ディレクトリ作成
mkdir -p "$DATE_DIR"

# チャットタイトルの処理
CHAT_TITLE="${1:-claude-chat-$(date +%H%M%S)}"

# ファイル名の安全化（日本語対応）
SAFE_TITLE=$(echo "$CHAT_TITLE" | sed 's/ /-/g' | tr -d '/\\:*?"<>|')

# 空のタイトルチェック
if [ -z "$SAFE_TITLE" ] || [ "$SAFE_TITLE" = "-" ]; then
    SAFE_TITLE="claude-chat-$(date +%H%M%S)"
fi

# 既存のhhmmss-プレフィックスが付いているかチェック
if [[ ! "$SAFE_TITLE" =~ ^[0-9]{6}- ]]; then
    # タイトルに時刻を先頭に追記（新規セッションの場合のみ）
    TIME_PREFIX=$(date +%H%M%S)
    SAFE_TITLE="${TIME_PREFIX}-${SAFE_TITLE}"
fi

FILENAME="$DATE_DIR/${SAFE_TITLE}.md"

# 会話内容の処理は直接$2を使用

# ファイルが存在しない場合は新規作成
if [ ! -f "$FILENAME" ]; then
    # ファイル名からタイトル部分を抽出（hhmmss-を除去）
    BASENAME=$(basename "$FILENAME" .md)
    DISPLAY_TITLE=$(echo "$BASENAME" | sed 's/^[0-9]\{6\}-//')
    cat > "$FILENAME" <<HEADER_EOF
# $DISPLAY_TITLE

HEADER_EOF
fi

# 会話内容を標準入力から読み取って追記
cat >> "$FILENAME"
echo >> "$FILENAME"

echo "会話ログが保存されました: $FILENAME"
