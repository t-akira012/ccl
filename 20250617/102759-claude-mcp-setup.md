# claude-mcp-setup

**User**:
claude codeでclaude-mcpを使う方法を取りまとめて。設定手順もお願い。可能ならbashで設定を容易にするスクリプトも作って

**Claude**:
Claude CodeでMCP（Model Context Protocol）を使用する方法について説明します。

## Claude MCPとは
MCPは、Claude Codeが外部ツールやサービスと連携するためのプロトコルです。データベース接続、API統合、ファイルシステム操作などの機能を拡張できます。

## 設定手順

### 1. 設定ファイルの作成
Claude Codeの設定ファイル `~/Library/Application Support/Claude/claude_desktop_config.json`（macOS）または `%APPDATA%\Claude\claude_desktop_config.json`（Windows）を作成します。

### 2. MCP設定の記述
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/directory"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-github-token"
      }
    }
  }
}
```

### 3. 利用可能なMCPサーバー
- **filesystem**: ファイルシステムアクセス
- **github**: GitHub API連携
- **postgres**: PostgreSQLデータベース接続
- **sqlite**: SQLiteデータベース操作
- **slack**: Slack連携
- **google-drive**: Google Drive連携

## 自動設定スクリプト

```bash
#\!/bin/bash
# setup-claude-mcp.sh - Claude MCP自動設定スクリプト

set -e

# OS判定
if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    CONFIG_DIR="$APPDATA/Claude"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CONFIG_DIR="$HOME/.config/Claude"
else
    echo "サポートされていないOSです: $OSTYPE"
    exit 1
fi

CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

# ディレクトリ作成
mkdir -p "$CONFIG_DIR"

# 既存の設定をバックアップ
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "既存の設定をバックアップしました"
fi

# MCPサーバーの選択
echo "設定するMCPサーバーを選択してください:"
echo "1) Filesystem (ローカルファイルアクセス)"
echo "2) GitHub (GitHub API連携)"
echo "3) PostgreSQL (データベース接続)"
echo "4) SQLite (SQLiteデータベース)"
echo "5) すべて設定"

read -p "選択 (1-5): " choice

# 基本設定の作成
cat > "$CONFIG_FILE" << 'EOF'
{
  "mcpServers": {
EOF

case $choice in
    1)
        read -p "アクセスを許可するディレクトリパス: " dir_path
        cat >> "$CONFIG_FILE" << EOF
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$dir_path"]
    }
EOF
        ;;
    2)
        read -p "GitHub Personal Access Token: " github_token
        cat >> "$CONFIG_FILE" << EOF
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "$github_token"
      }
    }
EOF
        ;;
    3)
        read -p "PostgreSQL接続文字列 (例: postgresql://user:pass@localhost/db): " pg_conn
        cat >> "$CONFIG_FILE" << EOF
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "$pg_conn"]
    }
EOF
        ;;
    4)
        read -p "SQLiteデータベースパス: " sqlite_path
        cat >> "$CONFIG_FILE" << EOF
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "$sqlite_path"]
    }
EOF
        ;;
    5)
        # すべて設定
        read -p "ファイルシステムアクセスディレクトリ: " dir_path
        read -p "GitHub Personal Access Token (スキップする場合は空): " github_token
        
        cat >> "$CONFIG_FILE" << EOF
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$dir_path"]
    }
EOF
        
        if [ -n "$github_token" ]; then
            cat >> "$CONFIG_FILE" << EOF
,
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "$github_token"
      }
    }
EOF
        fi
        ;;
esac

# 設定ファイルを閉じる
cat >> "$CONFIG_FILE" << 'EOF'
  }
}
EOF

echo "設定が完了しました: $CONFIG_FILE"
echo ""
echo "次の手順:"
echo "1. Claude Desktopアプリを再起動してください"
echo "2. 会話で 'mcp__' で始まるツールが利用可能になります"
echo ""
echo "例: mcp__filesystem__read_file, mcp__github__create_issue など"

# Node.jsの確認
if \! command -v node &> /dev/null; then
    echo ""
    echo "警告: Node.jsがインストールされていません。"
    echo "MCPサーバーを実行するにはNode.jsが必要です。"
    echo "https://nodejs.org/ からインストールしてください。"
fi
```

## 使用方法

1. スクリプトを保存して実行権限を付与:
```bash
chmod +x setup-claude-mcp.sh
./setup-claude-mcp.sh
```

2. Claude Desktopを再起動

3. 会話内で`mcp__`プレフィックスのツールが使用可能に

## 注意事項
- Node.jsのインストールが必要
- セキュリティトークンは環境変数で管理することを推奨
- ファイルシステムアクセスは信頼できるディレクトリのみに制限
- Claude Desktopの再起動が必要

**User**:
claude codeで使う方法は？

**Claude**:
Claude CodeでMCPを使う具体的な方法を説明します。

## Claude CodeでのMCP使用方法

### 1. 設定完了後の確認
MCPが正しく設定されると、Claude Codeで`mcp__`プレフィックスのツールが使用可能になります。

### 2. 利用可能なMCPツール例

#### Filesystemツール
```
mcp__filesystem__read_file - ファイルを読む
mcp__filesystem__write_file - ファイルを書く
mcp__filesystem__list_directory - ディレクトリ一覧
mcp__filesystem__create_directory - ディレクトリ作成
mcp__filesystem__delete - ファイル/ディレクトリ削除
mcp__filesystem__move - ファイル/ディレクトリ移動
```

#### GitHubツール
```
mcp__github__create_issue - Issue作成
mcp__github__list_issues - Issue一覧
mcp__github__create_pull_request - PR作成
mcp__github__list_repositories - リポジトリ一覧
mcp__github__get_file_contents - ファイル内容取得
```

### 3. 実際の使用例

#### ファイル操作の例
```
「mcp__filesystem__read_fileツールを使って/home/user/project/README.mdを読んでください」
「mcp__filesystem__list_directoryで現在のディレクトリの内容を表示して」
```

#### GitHub操作の例
```
「mcp__github__create_issueを使ってバグレポートのIssueを作成して」
「mcp__github__list_issuesでopen状態のIssueを確認して」
```

### 4. Claude Codeでの呼び出し方

1. **直接指定**: ツール名を明示的に指定
   ```
   「mcp__filesystem__read_fileを使ってconfig.jsonを読んで」
   ```

2. **自然な表現**: Claude Codeが適切なMCPツールを選択
   ```
   「GitHubのIssueを確認して」（mcp__github__list_issuesが使われる）
   ```

3. **複合的な操作**: 複数のMCPツールを組み合わせ
   ```
   「プロジェクトのREADMEを読んで、その内容を基にGitHub Issueを作成して」
   ```

### 5. トラブルシューティング

#### MCPツールが表示されない場合
1. Claude Desktopを完全に終了して再起動
2. 設定ファイルのJSON構文を確認
3. Node.jsがインストールされているか確認

#### エラーが発生する場合
```bash
# 設定ファイルの検証
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json  < /dev/null |  jq .

# Node.jsバージョン確認
node --version

# npmパッケージの手動インストール（必要な場合）
npm install -g @modelcontextprotocol/server-filesystem
```

### 6. セキュリティ注意事項
- ファイルシステムアクセスは最小限の権限で設定
- GitHubトークンは最小限のスコープで作成
- 本番環境のデータベースには接続しない
- 機密情報を含むディレクトリへのアクセスは避ける

**User**:
claude codeのmcp directoryはclaude desktopと同じで良いのですか

**Claude**:
いいえ、Claude CodeとClaude Desktopは別の設定ディレクトリを使用します。

## Claude CodeのMCP設定場所

### 設定ディレクトリの違い

**Claude Desktop**:
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

**Claude Code (CLI)**:
- すべてのOS: `~/.config/claude-code/config.json`

### Claude Code用の設定方法

1. **設定ディレクトリの作成**:
```bash
mkdir -p ~/.config/claude-code
```

2. **設定ファイルの作成**:
```bash
cat > ~/.config/claude-code/config.json << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/directory"]
    }
  }
}
EOF
```

3. **設定の確認**:
```bash
claude mcp
```

### 修正版セットアップスクリプト

```bash
#\!/bin/bash
# setup-claude-code-mcp.sh - Claude Code MCP設定スクリプト

set -e

# Claude Code用の設定ディレクトリ
CONFIG_DIR="$HOME/.config/claude-code"
CONFIG_FILE="$CONFIG_DIR/config.json"

# ディレクトリ作成
mkdir -p "$CONFIG_DIR"

# 既存設定のバックアップ
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "既存の設定をバックアップしました"
fi

# MCP設定
echo "Claude Code用のMCP設定を開始します"
read -p "アクセスを許可するディレクトリパス: " dir_path

cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$dir_path"]
    }
  }
}
EOF

echo "設定完了: $CONFIG_FILE"
echo ""
echo "設定を確認するには: claude mcp"
echo "MCPツールを使用するには通常通りClaude Codeを使用してください"
```

### 重要な違い
- Claude DesktopとClaude Codeは独立した設定
- 両方使う場合は、それぞれに設定が必要
- Claude Codeは`~/.config/claude-code/`を使用

