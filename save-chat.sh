#!/bin/bash

# Claude Code会話ログ保存スクリプト
# Usage: ./save-chat.sh [chat-title] [conversation-content]

LOG_DIR="$(cd "$(dirname "$0")" && pwd)"
DATE=$(date +%Y%m%d)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_DIR="$LOG_DIR/$DATE"

# ディレクトリ作成
mkdir -p "$DATE_DIR"

# チャットタイトルの処理
if [ -n "$1" ]; then
    CHAT_TITLE="$1"
else
    echo "会話のタイトルを入力してください:"
    read CHAT_TITLE
    if [ -z "$CHAT_TITLE" ]; then
        CHAT_TITLE="claude-chat-$(date +%H%M%S)"
    fi
fi

# ファイル名の安全化（日本語対応）
SAFE_TITLE=$(echo "$CHAT_TITLE" | sed 's/ /-/g' | tr -d '/\\:*?"<>|')

# 空のタイトルチェック
if [ -z "$SAFE_TITLE" ] || [ "$SAFE_TITLE" = "-" ]; then
    SAFE_TITLE="claude-chat-$(date +%H%M%S)"
fi

FILENAME="$DATE_DIR/${SAFE_TITLE}.md"

# 会話内容の処理（here documentを使用）
if [ -n "$2" ]; then
    CONVERSATION_CONTENT="$2"
else
    echo "会話内容を入力してください（Ctrl+Dで終了）:"
    CONVERSATION_CONTENT=$(cat)
fi

# ファイルが存在しない場合は新規作成
if [ ! -f "$FILENAME" ]; then
    cat > "$FILENAME" <<HEADER_EOF
# $CHAT_TITLE

HEADER_EOF
fi

# 会話内容を追記（here documentを使用）
cat >> "$FILENAME" <<CONTENT_EOF
$CONVERSATION_CONTENT

CONTENT_EOF

echo "会話ログが保存されました: $SAFE_TITLE"
