# Claude-Code-MCP設定手順

**User**:
~/.config/claude/の下にmcp jsonを配置する場合は

**Claude**:
~/.config/claude/の下にMCP JSONを配置する場合の設定方法をご説明します。

## グローバル設定としてのMCP JSON配置

### 1. 設定ファイルの場所

```bash
~/.config/claude/mcp_servers.json
```

または

```bash
~/.config/claude/config.json
```

### 2. mcp_servers.jsonの形式

`~/.config/claude/mcp_servers.json`として作成：

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "~/Documents"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_TOKEN"
      }
    },
    "database": {
      "command": "python3",
      "args": ["~/scripts/database-mcp-server.py"],
      "env": {
        "DB_CONNECTION_STRING": "$DATABASE_URL"
      }
    }
  }
}
```

### 3. config.jsonに統合する場合

`~/.config/claude/config.json`として作成：

```json
{
  "defaults": {
    "model": "claude-3-5-sonnet-20241022"
  },
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "~/Documents"]
    },
    "web-search": {
      "transport": "http",
      "url": "https://api.example.com/mcp/search",
      "headers": {
        "Authorization": "Bearer $SEARCH_API_KEY"
      }
    }
  },
  "environment": {
    "GITHUB_TOKEN": "ghp_your_token_here",
    "DATABASE_URL": "postgresql://localhost:5432/mydb",
    "SEARCH_API_KEY": "your_search_api_key"
  }
}
```

### 4. 環境変数の管理

グローバル設定では環境変数を活用：

```bash
# ~/.bashrc または ~/.zshrc
export GITHUB_TOKEN="ghp_your_personal_access_token"
export DATABASE_URL="postgresql://localhost:5432/mydb"
export OPENAI_API_KEY="sk-your-openai-key"
```

### 5. 設定の優先順位

1. **プロジェクト固有**: `./mcp.json` (最優先)
2. **ユーザーグローバル**: `~/.config/claude/mcp_servers.json`
3. **システム全体**: `/etc/claude/mcp_servers.json` (存在する場合)

### 6. 実用的なグローバル設定例

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "~/workspace"],
      "description": "ワークスペースファイルアクセス"
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"],
      "description": "Git操作サポート"
    },
    "terminal": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-terminal"],
      "description": "ターミナルコマンド実行"
    },
    "web": {
      "transport": "http",
      "url": "http://localhost:3000/mcp",
      "description": "ローカルWebサービス"
    }
  }
}
```

### 7. 設定の確認とテスト

```bash
# 設定確認
claude mcp list

# 特定サーバーのテスト
claude mcp test filesystem

# デバッグモードで起動
claude --debug
```

この方法により、全プロジェクトで共通して使用するMCPサーバーをグローバルに管理できます。

