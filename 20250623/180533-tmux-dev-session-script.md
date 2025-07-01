# tmux-dev-session-script

**User**:
tmuxで以下を起動するスクリプトを作れ

1: dev-editor
2: dev-document
7: other
8: environment
9: doc

**Claude**:
tmuxセッションを起動するスクリプトを作成します。

```bash
#!/bin/bash

# tmuxセッション名
SESSION_NAME="dev"

# セッションが既に存在するかチェック
tmux has-session -t $SESSION_NAME 2>/dev/null

if [ $? \!= 0 ]; then
    # セッションが存在しない場合、新規作成
    
    # ウィンドウ1: dev-editor
    tmux new-session -d -s $SESSION_NAME -n "dev-editor"
    
    # ウィンドウ2: dev-document
    tmux new-window -t $SESSION_NAME:2 -n "dev-document"
    
    # ウィンドウ7: other
    tmux new-window -t $SESSION_NAME:7 -n "other"
    
    # ウィンドウ8: environment
    tmux new-window -t $SESSION_NAME:8 -n "environment"
    
    # ウィンドウ9: doc
    tmux new-window -t $SESSION_NAME:9 -n "doc"
    
    # 最初のウィンドウを選択
    tmux select-window -t $SESSION_NAME:1
fi

# セッションにアタッチ
tmux attach-session -t $SESSION_NAME
```

実行権限を付与して使用:
```bash
chmod +x tmux-dev.sh
./tmux-dev.sh
```

