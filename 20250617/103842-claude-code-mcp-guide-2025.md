# claude-code-mcp-guide-2025

**User**:
OK.ここまでの情報で確かな最新の厳密に正しい方法で、claude codeでmcpを使う方法と、bashスクリプトを取りまとめよう。また、会話ログも新規作成で。

**Claude**:
# Claude Code CLI MCP設定ガイド（2025年1月版）

## 現在判明している正確な情報

### MCP設定の現状
- Claude Code CLIのMCP設定ドキュメントは限定的
- `claude mcp`コマンドで設定状況を確認可能
- 環境変数での制御が可能

### 確認済みの設定方法

#### 1. 環境変数設定
```bash
export MCP_TIMEOUT=30000        # MCPサーバー起動タイムアウト（30秒）
export MCP_TOOL_TIMEOUT=600000  # MCPツール実行タイムアウト（10分）
```

#### 2. 設定確認コマンド
```bash
claude mcp  # MCP設定状況を表示
```

### 利用可能なMCPサーバー例
- **filesystem**: ローカルファイルアクセス
- **github**: GitHub API連携
- **postgres/sqlite**: データベース接続

## 設定確認・セットアップスクリプト

```bash
#\!/bin/bash
# claude-code-mcp-check.sh - Claude Code MCP設定確認・セットアップ補助スクリプト

set -e

echo "=== Claude Code MCP 設定確認ツール ==="
echo ""

# 1. Claude Codeインストール確認
if \! command -v claude &> /dev/null; then
    echo "❌ Claude Codeがインストールされていません"
    echo "インストール方法: https://claude.ai/download"
    exit 1
else
    echo "✅ Claude Code: $(claude --version 2>/dev/null || echo 'インストール済み')"
fi

# 2. Node.js確認
if \! command -v node &> /dev/null; then
    echo "❌ Node.jsがインストールされていません"
    echo "MCPサーバーの実行にはNode.jsが必要です"
else
    echo "✅ Node.js: $(node --version)"
fi

# 3. 現在のMCP設定確認
echo ""
echo "=== 現在のMCP設定 ==="
claude mcp 2>/dev/null || echo "MCPサーバーが設定されていません"

# 4. 環境変数確認
echo ""
echo "=== MCP関連環境変数 ==="
echo "MCP_TIMEOUT: ${MCP_TIMEOUT:-未設定}"
echo "MCP_TOOL_TIMEOUT: ${MCP_TOOL_TIMEOUT:-未設定}"

# 5. 推奨される設定場所の確認
echo ""
echo "=== 設定ファイル候補 ==="
POSSIBLE_CONFIGS=(
    "$HOME/.config/claude-code/config.json"
    "$HOME/.claude/config.json"
    "./claude-config.json"
)

for config in "${POSSIBLE_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        echo "✅ 発見: $config"
        echo "内容:"
        cat "$config"  < /dev/null |  head -10
    else
        echo "❌ 存在しない: $config"
    fi
done

# 6. 推奨設定の提案
echo ""
echo "=== 推奨設定 ==="
echo ""
echo "1. 環境変数の設定（~/.bashrc or ~/.zshrc に追加）:"
echo "   export MCP_TIMEOUT=30000"
echo "   export MCP_TOOL_TIMEOUT=600000"
echo ""
echo "2. MCPサーバーの設定:"
echo "   現在、Claude Code CLIのMCP設定方法は公式ドキュメントで"
echo "   明確に示されていません。以下を試してください："
echo ""
echo "   a) claude mcp コマンドで表示される指示に従う"
echo "   b) プロジェクトルートにclaude-config.jsonを作成"
echo "   c) Anthropicサポートに最新情報を確認"
echo ""
echo "3. 利用可能なMCPサーバーの例:"
echo "   - @modelcontextprotocol/server-filesystem"
echo "   - @modelcontextprotocol/server-github"
echo "   - その他のコミュニティ製MCPサーバー"

# 7. 次のステップ
echo ""
echo "=== 次のステップ ==="
echo "1. 上記の推奨設定を適用"
echo "2. claude mcp コマンドで再度確認"
echo "3. 必要に応じてMCPサーバーをnpxで実行"
echo ""
echo "詳細情報:"
echo "- https://github.com/anthropics/claude-code"
echo "- https://modelcontextprotocol.io/"
```

## 重要な注意事項

1. **公式ドキュメントの状況**
   - Claude Code CLI専用のMCP設定方法は明確に文書化されていない
   - 多くの情報はClaude Desktop向け

2. **確実な方法**
   - `claude mcp`コマンドで現在の設定を確認
   - 表示される指示に従って設定

3. **代替アプローチ**
   - プロジェクトごとの設定ファイル
   - 環境変数での制御
   - 直接MCPサーバーを起動

4. **最新情報の入手**
   - Anthropic公式サポート
   - GitHubのissues/discussions
   - コミュニティフォーラム

