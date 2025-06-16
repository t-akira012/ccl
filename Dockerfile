# Claude Code Log Management System
FROM public.ecr.aws/ubuntu/ubuntu

# 基本パッケージのインストール
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    ripgrep \
    make \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLIのインストール
RUN npm install -g @anthropic-ai/claude-code

# 作業ディレクトリの設定
WORKDIR /workspace

# プロジェクトファイルのコピー
COPY . .

# スクリプトに実行権限を付与
RUN chmod +x *.sh

# デフォルトコマンド
CMD ["bash"]
