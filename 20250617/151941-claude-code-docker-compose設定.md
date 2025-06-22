# claude-code-docker-compose設定

**User**:
claude codeをubuntuコンテナ内部で動かしたときに、ホストの$HOME/.claudeのファイルをどこにbindすれば良いのか。compose.yamlの例を出せ

**Claude**:
Docker ComposeでClaude Codeを実行する際の、ホストの`~/.claude`ディレクトリをコンテナにバインドマウントする設定例を示します。

```yaml
version: '3.8'

services:
  claude-code:
    image: ubuntu:latest
    container_name: claude-code-container
    volumes:
      # ホストの~/.claudeディレクトリをコンテナにバインドマウント
      - ${HOME}/.claude:/root/.claude
      # 別の記法
      # - ~/.claude:/root/.claude
      
      # 別のユーザーのホームディレクトリにマウントする場合
      # - ${HOME}/.claude:/home/ubuntu/.claude
      
      # ワークスペースディレクトリのマウント
      - ./workspace:/workspace
    
    # コンテナを起動状態に保つ
    command: tail -f /dev/null
    
    # オプション: 作業ディレクトリの設定
    working_directory: /workspace
    
    # オプション: 環境変数
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    
    # オプション: ネットワークアクセスが必要な場合
    networks:
      - claude-network

networks:
  claude-network:
    driver: bridge
```

非rootユーザーでClaude Codeを実行する場合の設定:

```yaml
version: '3.8'

services:
  claude-code:
    image: ubuntu:latest
    container_name: claude-code-container
    user: "1000:1000"  # ユーザーのUID:GID
    volumes:
      # 非rootユーザー用
      - ${HOME}/.claude:/home/ubuntu/.claude
      - ./workspace:/workspace
    command: tail -f /dev/null
    working_directory: /workspace
```

重要なポイント:
- `${HOME}/.claude:/root/.claude` - rootユーザーで実行する場合
- `${HOME}/.claude:/home/ubuntu/.claude` - ubuntuユーザーのホームにマウント
- `${HOME}`または`~`でホストのホームディレクトリを参照

**User**:
検討は全て日本語で。

