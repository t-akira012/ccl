# slack-webhook-修正

**User**:
#\!/bin/bash

# Slack Webhook URLを環境変数から取得
WEBHOOK_URL="${SLACK_WEBHOOK_URL}"

if [ -z "$WEBHOOK_URL" ]; then
    echo "Error: SLACK_WEBHOOK_URL environment variable is not set"
    exit 1
fi

# 最新の日付ディレクトリを取得
LATEST_DIR=$(ls -d [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] 2>/dev/null  < /dev/null |  sort -r | head -1)

if [ -z "$LATEST_DIR" ]; then
    echo "Error: No log directory found"
    exit 1
fi

# 最新のログファイルを取得
LATEST_LOG=$(ls -t "$LATEST_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "Error: No log file found in $LATEST_DIR"
    exit 1
fi

# ファイル名とタイトルを取得
FILENAME=$(basename "$LATEST_LOG")
TITLE=$(head -1 "$LATEST_LOG" | sed 's/^# //')

# ログ内容を取得
CONTENT=$(cat "$LATEST_LOG")

# JSONペイロードを作成
PAYLOAD=$(cat <<EOF
{
    "text": "Latest Log: $TITLE",
    "attachments": [
        {
            "color": "#36a64f",
            "title": "$FILENAME",
            "text": "$CONTENT",
            "footer": "From: $LATEST_DIR",
            "ts": $(date +%s)
        }
    ]
}
EOF
)

# Slackに送信
RESPONSE=$(curl -s -X POST -H 'Content-type: application/json' \
    --data "$PAYLOAD" \
    "$WEBHOOK_URL")

if [ "$RESPONSE" = "ok" ]; then
    echo "Successfully sent log to Slack: $LATEST_LOG"
else
    echo "Error sending to Slack: $RESPONSE"
    exit 1
fi

直せ

**Claude**:
JSONエスケープの問題だけ修正：

```bash
# ログ内容を取得
CONTENT=$(cat "$LATEST_LOG" | jq -Rs .)

# ファイル名とタイトルもエスケープ
FILENAME=$(basename "$LATEST_LOG" | jq -Rs .)
TITLE=$(head -1 "$LATEST_LOG" | sed 's/^# //' | jq -Rs .)

# JSONペイロードを作成
PAYLOAD=$(cat <<EOF
{
    "text": "Latest Log: $TITLE",
    "attachments": [
        {
            "color": "#36a64f",
            "title": $FILENAME,
            "text": $CONTENT,
            "footer": "From: $LATEST_DIR",
            "ts": $(date +%s)
        }
    ]
}
EOF
)
```

変更点：
- `jq -Rs .`で各変数をJSONエスケープ
- エスケープ後は`"$VAR"`ではなく`$VAR`（jqが引用符も付けるため）

