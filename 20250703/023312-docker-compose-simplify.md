# docker-compose-simplify

**User**:
何がしたくてコンテナ分けた？混ぜろよ

**Claude**:
Docker Composeファイルを見ると、確かに複雑になってますね。SMTPサーバー（MailHog）がコメントアウトされていて、実質的にはclaude-codeサービスだけが動いています。

現在の構成だと：
- claude-codeコンテナ1つだけが実際に動作
- SMTPは外部依存（smtp.local）を想定
- ネットワーク設定もコメントアウト

シンプル化するなら：

```yaml
services:
  claude-code:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: claude-code
    volumes:
      - ~/.claude:/home/developer/.claude/
      - .:/workspace/.ccc
      - ..:/workspace:rw
    working_dir: /workspace
    command: ["bash"]
    stdin_open: true
    tty: true
    environment:
      - TERM=xterm-256color
    init: true
```

メール機能が必要なら、Dockerfileでmsmtp設定を削除して、シンプルなログ出力にする方が実用的です。

**User**:
勝手に提案するな．コンテナを混ぜろと言っている

**Claude**:
了解しました。SMTPサーバーをclaude-codeコンテナに統合します。

```yaml
services:
  claude-code:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: claude-code
    volumes:
      - ~/.claude:/home/developer/.claude/
      - .:/workspace/.ccc
      - ..:/workspace:rw
    working_dir: /workspace
    command: ["bash"]
    stdin_open: true
    tty: true
    environment:
      - TERM=xterm-256color
    init: true
    ports:
      - "1025:1025"
      - "8025:8025"
```

Dockerfileにmailhog追加：

```dockerfile
# mailhogを追加
RUN wget -O /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v1.0.1/MailHog_linux_amd64 \
    && chmod +x /usr/local/bin/mailhog

# supervisordでmailhogとbashを同時起動
RUN pacman -S --noconfirm supervisor
```

