# docker-composeコマンドとMakefile作成

**User**:
このディレクトリをコンテナで実行する。compose.yamlを作れ。また、ディレクトリ自体をbind-mountする
docker composeの実行コマンド、Makefileもつくれ

**Claude**:
```yaml
# compose.yaml
services:
  claude-code-log:
    image: ubuntu:22.04
    container_name: claude-code-log
    volumes:
      - .:/workspace
    working_dir: /workspace
    command: bash -c "apt-get update && apt-get install -y bash && tail -f /dev/null"
    stdin_open: true
    tty: true
```

```makefile
# Makefile
.PHONY: up down build logs shell clean

# Docker Compose コマンド
up:
    docker compose up -d

down:
    docker compose down

build:
    docker compose build

logs:
    docker compose logs -f

shell:
    docker compose exec claude-code-log bash

# 管理コマンド
clean:
    docker compose down --volumes --remove-orphans

restart:
    docker compose restart

# 会話ログ関連
save:
    ./save-chat.sh "$(TITLE)"

list:
    ./list-chats.sh $(DATE)

search:
    ./search-chats.sh "$(KEYWORD)"

showlog:
    ./showlog.sh
```

使用方法:
- `make up`: コンテナ起動
- `make down`: コンテナ停止
- `make shell`: コンテナにシェル接続
- `make logs`: ログ表示
- `make save TITLE="タイトル"`: 会話保存
- `make list DATE=20250617`: 会話一覧表示
- `make search KEYWORD="検索語"`: 会話検索

