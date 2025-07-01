# Claude-Code-MCP設定手順

**User**:
claude codeにmcpを設定したい。その手順を取りまとめて欲しい

**Claude**:
Claude CodeでMCP（Model Context Protocol）を設定する手順をまとめます。

## MCP設定手順

### 1. MCPサーバーの追加方法

#### a) Stdioサーバー（標準的な方法）
```bash
claude mcp add <name> <command> [args...]
# 例: claude mcp add my-server -e API_KEY=123 -- /path/to/server
```

#### b) SSEサーバー（Server-Sent Events）
```bash
claude mcp add --transport sse <name> <url>
# 例: claude mcp add --transport sse sse-server https://example.com/sse-endpoint
```

#### c) HTTPサーバー
```bash
claude mcp add --transport http <name> <url>
# 例: claude mcp add --transport http http-server https://example.com/mcp
```

### 2. サーバースコープの設定

- **local**（デフォルト）: プロジェクト固有、プライベート設定
- **project**: .mcp.jsonファイルで共有、チームに公開
- **user**: すべてのプロジェクトで利用可能

### 3. 認証設定

- `/mcp`コマンドでリモートサーバーの認証を実行
- OAuth 2.0フローをサポート
- トークンは安全に保存され、自動更新される

### 4. 実用的な設定例

#### 環境変数を含む設定
```bash
claude mcp add my-api-server -e API_KEY=$MY_API_KEY -- node /path/to/server.js
```

#### タイムアウトの設定
サーバー起動時のタイムアウトも設定可能

### 5. 管理コマンド

- サーバーステータス確認: `/mcp`
- 複数の専門的なサーバーを同時に利用可能

### 注意事項
- サードパーティのMCPサーバーは自己責任で使用してください
- プロジェクトごとに適切なスコープを選択することが重要

**User**:
初めから、jsonで管理したい

**Claude**:
Claude CodeでMCPをJSONファイルで管理する方法をご説明します。

## JSONファイルでのMCP管理

### 1. .mcp.jsonファイルの作成

プロジェクトルートに`.mcp.json`ファイルを作成します：

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["/path/to/server.js"],
      "env": {
        "API_KEY": "your-api-key"
      }
    },
    "http-server": {
      "transport": "http",
      "url": "https://example.com/mcp"
    },
    "sse-server": {
      "transport": "sse",
      "url": "https://example.com/sse-endpoint"
    }
  }
}
```

### 2. 設定項目の詳細

#### Stdioサーバーの設定
```json
{
  "server-name": {
    "command": "実行コマンド",
    "args": ["引数1", "引数2"],
    "env": {
      "環境変数名": "値"
    },
    "timeout": 30000
  }
}
```

#### HTTPサーバーの設定
```json
{
  "http-server": {
    "transport": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer token"
    }
  }
}
```

#### SSEサーバーの設定
```json
{
  "sse-server": {
    "transport": "sse",
    "url": "https://api.example.com/sse",
    "headers": {
      "Authorization": "Bearer token"
    }
  }
}
```

### 3. 実用的な設定例

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/username/Documents"]
    },
    "database": {
      "command": "python",
      "args": ["/path/to/database-server.py"],
      "env": {
        "DB_URL": "postgresql://localhost:5432/mydb",
        "DB_PASSWORD": "password"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxx"
      }
    }
  }
}
```

### 4. JSONファイルの利点

- **バージョン管理**: Gitで管理可能
- **チーム共有**: プロジェクトメンバーと設定を共有
- **可読性**: 設定内容が一目で分かる
- **編集しやすさ**: IDEのJSON補完機能を活用

### 5. 設定の確認

```bash
# 現在のMCP設定を確認
claude mcp list

# 特定のサーバーの詳細確認
/mcp
```

この方法で、最初からJSONベースでMCPサーバーを管理できます。

