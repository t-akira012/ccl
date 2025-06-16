# Claude Code Development Environment
FROM node:lts

# 追加パッケージをインストール
RUN apt-get update && apt-get install -y \
    # 基本ツール
    curl \
    wget \
    git \
    make \
    unzip \
    # エディタとユーティリティ
    nano \
    vim \
    ripgrep \
    # Python環境
    python3 \
    python3-pip \
    # ブラウザ認証用
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLIをグローバルインストール
RUN npm install -g @anthropic-ai/claude-code

# 非rootユーザーを作成（セキュリティ強化）
RUN useradd -m -s /bin/bash developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 作業ディレクトリ設定
WORKDIR /workspace

# プロジェクトファイルをコピー
COPY --chown=developer:developer . .

# スクリプトに実行権限付与
RUN chmod +x *.sh

# 開発ユーザーに切り替え
USER developer

# Claude Code設定ディレクトリを作成
RUN mkdir -p /home/developer/.claude

# Claude Codeの動作確認
RUN claude --version || echo "Claude Code installed, auth required"

# デフォルトコマンド（対話型bash）
CMD ["bash", "-l"]
