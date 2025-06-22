# Claude-Code-MCP設定調査

**User**:
Claude CodeのMCP設定について、公式ドキュメントから正確な情報を収集してください。特に以下の点を確認：
1. Claude Code CLIでのMCP設定ファイルの正確な場所
2. 設定ファイルの正しいフォーマット
3. 利用可能なMCPサーバーの種類と設定方法
4. 設定後の動作確認方法

https://docs.anthropic.com/en/docs/claude-code のサブページから関連情報を探してください。

**Claude**:
Claude Code CLIのMCP（Model Context Protocol）設定について、公式ドキュメントと関連情報から収集した情報をまとめます。

## Claude Code CLIのMCP設定について

### 1. MCP設定ファイルの場所

現在の調査結果では、**Claude Code CLI専用のMCP設定ファイルの場所について、公式ドキュメントに明確な記載が見つかりませんでした**。

ただし、関連情報から以下のことが分かっています：

- **Claude Desktop**の場合：`~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)
- **Claude Code CLI**の場合：プロジェクトごとの設定か、環境変数での設定が示唆されている

### 2. 環境変数設定

Claude Code CLIでは、以下のMCP関連の環境変数が利用可能です：

- `MCP_TIMEOUT`: MCPサーバー起動のタイムアウト（ミリ秒）
- `MCP_TOOL_TIMEOUT`: MCPツール実行のタイムアウト（ミリ秒）

### 3. 利用可能なMCPサーバー

GitHubで公開されているClaude Code用MCPサーバーの例：

#### a) KunihiroS/claude-code-mcp


#### b) steipete/claude-code-mcp


### 4. その他のMCPサーバー

- **filesystem**: ファイルシステムアクセス
- **DesktopCommanderMCP**: ターミナル制御とファイル編集機能

### 5. 設定に関する重要な注意点

1. **Claude Code CLIは、MCPサーバーとクライアントの両方として機能する**
2. プロジェクト設定での接続が可能（ディレクトリごとの設定）
3. 環境変数 `~/.claude-code-mcp.env` または実行ディレクトリの `.env` ファイルで追加設定が可能

### 6. 現状の制限事項

- **Claude Code CLI固有のMCP設定ドキュメントが不足している**
- 公式ドキュメントの多くはClaude Desktop向けの内容
- CLI専用の設定方法については、より詳細な公式ドキュメントの公開が待たれる

### 推奨される次のステップ

1. Claude Code CLIのヘルプコマンドで最新の設定方法を確認
2. GitHubのClaude Code関連リポジトリで最新情報をチェック
3. Anthropicのサポートに直接問い合わせて、CLI固有の設定方法を確認

現時点では、Claude Desktop向けの設定情報は豊富ですが、CLI専用の詳細な設定ドキュメントは限定的であることが分かりました。

