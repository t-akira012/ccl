# Makefile-mise移行ベストプラクティス集

**User**:
Makefileワークフローをmiseに変えた場合の汎用的なベストプラクティス集を調査してまとめなさい

**Claude**:
# Makefileワークフローをmiseに変えた場合の汎用的なベストプラクティス集

## 1. mise vs make の基本的な違い

### miseの特徴
- **統合的な開発環境管理**: ツールバージョン管理、環境変数管理、タスク実行を統合
- **現代的な開発ワークフロー**: 多言語プロジェクト、複数バージョン管理に対応
- **高速性**: Rust製で、~10ms程度の低オーバーヘッド
- **設定ファイル**: `mise.toml`形式でのシンプルな設定

### makeの特徴
- **従来型ビルドツール**: 主にタスク実行とビルド自動化に特化
- **歴史と安定性**: 48年の歴史を持つ成熟したツール
- **設定ファイル**: `Makefile`形式

## 2. 移行の基本戦略

### 段階的移行アプローチ
1. **現在のMakefileを完全に理解する**
   - 全てのターゲット、依存関係、変数を文書化
   - 各タスクの目的と実行順序を把握

2. **シンプルなタスクから開始**
   - ビルドコマンドやテストコマンドなど基本的なタスクから移行
   - 複雑な依存関係を持つタスクは後回し

3. **並行運用期間を設ける**
   - MakefileとMise設定を両方維持
   - チームが慣れるまでの移行期間を確保

4. **完全な移行とクリーンアップ**
   - 全てのワークフローが正常に動作することを確認後、Makefileを削除

## 3. 具体的な移行パターン

### 3.1 基本的なタスク移行

**従来のMakefile:**
```makefile
build:
	cargo build

test:
	cargo test

clean:
	cargo clean
```

**mise.toml:**
```toml
[tasks.build]
description = "Build the project"
run = "cargo build"

[tasks.test]
description = "Run tests"
run = "cargo test"

[tasks.clean]
description = "Clean build artifacts"
run = "cargo clean"
```

### 3.2 依存関係付きタスクの移行

**従来のMakefile:**
```makefile
test: build
	cargo test

deploy: test
	./deploy.sh
```

**mise.toml:**
```toml
[tasks.build]
run = "cargo build"

[tasks.test]
depends = ["build"]
run = "cargo test"

[tasks.deploy]
depends = ["test"]
run = "./deploy.sh"
```

### 3.3 複数コマンドの移行

**従来のMakefile:**
```makefile
setup:
	npm install
	npm run build
	chmod +x ./bin/myapp
```

**mise.toml:**
```toml
[tasks.setup]
description = "Set up the development environment"
run = [
    "npm install",
    "npm run build",
    "chmod +x ./bin/myapp"
]
```

### 3.4 環境変数とツールバージョン管理

**mise.toml（miseの強み）:**
```toml
[tools]
node = "18.17.0"
python = "3.11"
terraform = "1.5.0"

[env]
NODE_ENV = "development"
API_URL = "http://localhost:3000"
DB_HOST = "localhost"

[tasks.start]
description = "Start development server"
env = { DEBUG = "true" }
run = "npm start"
```

## 4. ベストプラクティス

### 4.1 設定ファイルの構成

```toml
# ツールバージョンを明確に指定
[tools]
node = "18.17.0"        # 具体的なバージョンを指定
python = "3.11"         # メジャーバージョンも可
go = "latest"           # 最新バージョンも使用可能

# プロジェクト固有の環境変数
[env]
PROJECT_NAME = "myapp"
LOG_LEVEL = "debug"

# タスクの論理的グループ化
[tasks.build]
description = "Build the application"
run = "go build -o bin/myapp"

[tasks.test]
description = "Run all tests"
depends = ["build"]
run = "go test ./..."

[tasks.lint]
description = "Run linting"
run = "golangci-lint run"

[tasks.ci]
description = "Run CI pipeline"
depends = ["lint", "test"]
run = "echo 'CI pipeline completed'"
```

### 4.2 ファイル変更検知の活用

```toml
[tasks.build]
description = "Build when source files change"
run = "cargo build"
sources = ["Cargo.toml", "src/**/*.rs"]
outputs = ["target/debug/myapp"]
```

### 4.3 タスクの可視性制御

```toml
[tasks.public-task]
description = "This task is visible to users"
run = "echo 'Hello World'"

[tasks.internal-helper]
description = "Internal helper task"
hide = true
run = "echo 'This is hidden'"

[tasks.quiet-task]
description = "Task with minimal output"
quiet = true
run = "echo 'Only script output shows'"
```

### 4.4 複数環境対応

```toml
# 開発環境
[env]
NODE_ENV = "development"
API_URL = "http://localhost:3000"

# 本番環境用のオーバーライド
[tasks.deploy-prod]
description = "Deploy to production"
env = { NODE_ENV = "production", API_URL = "https://api.example.com" }
run = "npm run deploy"
```

## 5. 高度な移行テクニック

### 5.1 複数言語プロジェクトの統合

```toml
[tools]
node = "18.17.0"
python = "3.11"
go = "1.21"
rust = "1.70"

[tasks.setup-all]
description = "Setup all language environments"
run = [
    "npm install",
    "pip install -r requirements.txt",
    "go mod download",
    "cargo build"
]

[tasks.test-all]
description = "Run tests for all languages"
run = [
    "npm test",
    "python -m pytest",
    "go test ./...",
    "cargo test"
]
```

### 5.2 条件付き実行

```toml
[tasks.deploy]
description = "Deploy with environment check"
run = '''
if [ "$NODE_ENV" = "production" ]; then
    npm run build:prod
    npm run deploy:prod
else
    echo "Not in production environment"
    exit 1
fi
'''
```

### 5.3 並列タスク実行

```toml
[tasks.parallel-tasks]
description = "Run tasks in parallel"
run = [
    "mise run lint &",
    "mise run test &",
    "mise run build &",
    "wait"
]
```

## 6. 移行時の注意点

### 6.1 互換性の確保
- **Makefileの`: `を`depends`に変換**
- **変数の置き換え**: `$(VAR)`を`{{env.VAR}}`に変更
- **シェル構文**: より明示的なシェルスクリプトに変更

### 6.2 チーム導入時の配慮
- **ドキュメント作成**: 移行ガイドとコマンド対応表の作成
- **段階的導入**: 全員が一度に移行する必要はない
- **トレーニング**: miseの基本的な使い方の共有

### 6.3 CI/CDパイプラインの更新
```yaml
# GitHub Actions例
- name: Install mise
  run: curl https://mise.run  < /dev/null |  sh
  
- name: Setup tools
  run: mise install

- name: Run tests
  run: mise run test
```

## 7. 移行後のメリット

### 7.1 開発効率の向上
- **一貫した開発環境**: チーム全体で同じツールバージョンを使用
- **環境構築の簡素化**: `mise install`だけで全ツールが設定される
- **高速な環境切り替え**: プロジェクト間でのツールバージョン自動切り替え

### 7.2 保守性の向上
- **設定の一元化**: ツール、環境、タスクが1つのファイルで管理
- **可読性**: TOML形式での直感的な設定
- **拡張性**: 新しいツールやタスクの追加が容易

## 8. トラブルシューティング

### 8.1 一般的な問題と解決策
- **パフォーマンス**: `mise doctor`コマンドで健康状態を確認
- **ツールインストール**: `mise install`でツールが正しくインストールされているか確認
- **環境変数**: `mise env`で環境変数が正しく設定されているか確認

### 8.2 デバッグ手法
```bash
# 詳細なログ出力
MISE_LOG_LEVEL=debug mise run task-name

# 設定の確認
mise config
mise env
mise list
```

この移行ガイドに従って、段階的にMakefileからmiseへの移行を行うことで、より現代的で効率的な開発ワークフローを構築できます。

