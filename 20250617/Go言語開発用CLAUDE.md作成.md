# Go言語開発用CLAUDE.md作成

**User**:
Go言語開発用CLAUDE.mdをあなたの知識から作りなさい

**Claude**:
Go言語開発のベストプラクティスと開発環境設定を含むCLAUDE.mdファイルを作成します。

```markdown
# Go言語開発用CLAUDE.md

## 開発環境設定

### 必須ツール
- Go 1.21以上
- gofmt, goimports（コードフォーマット）
- golangci-lint（静的解析）
- go mod（依存関係管理）

### エディタ設定
```json
{
  "go.formatTool": "goimports",
  "go.lintTool": "golangci-lint",
  "go.testFlags": ["-v", "-race"],
  "go.buildFlags": ["-race"],
  "editor.formatOnSave": true
}
```

## コーディング規約

### 命名規則
- パッケージ名: 小文字のみ、短く簡潔に
- 関数名: キャメルケース、エクスポートは大文字開始
- 変数名: キャメルケース、短いスコープでは短い名前
- 定数: キャメルケース、エクスポートは大文字開始

### ディレクトリ構造
```
project/
├── cmd/                 # アプリケーションエントリーポイント
│   └── myapp/
│       └── main.go
├── internal/            # プライベートパッケージ
│   ├── config/
│   ├── handler/
│   └── service/
├── pkg/                 # 外部公開可能なパッケージ
├── api/                 # API定義（OpenAPI, protobuf等）
├── web/                 # Webアセット
├── scripts/             # ビルド・デプロイスクリプト
├── deployments/         # デプロイ設定
├── test/                # テストデータ・ヘルパー
├── docs/                # ドキュメント
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

## テスト戦略

### テストファイル命名
- `*_test.go`
- テーブル駆動テスト推奨
- テストヘルパーは`testing.T.Helper()`を使用

### テスト例
```go
func TestCalculate(t *testing.T) {
    tests := []struct {
        name     string
        input    int
        expected int
        wantErr  bool
    }{
        {
            name:     "positive number",
            input:    5,
            expected: 25,
            wantErr:  false,
        },
        {
            name:     "negative number",
            input:    -1,
            expected: 0,
            wantErr:  true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := Calculate(tt.input)
            
            if tt.wantErr {
                assert.Error(t, err)
                return
            }
            
            assert.NoError(t, err)
            assert.Equal(t, tt.expected, result)
        })
    }
}
```

## エラーハンドリング

### エラー設計
```go
// カスタムエラー型
type AppError struct {
    Code    string
    Message string
    Cause   error
}

func (e *AppError) Error() string {
    if e.Cause \!= nil {
        return fmt.Sprintf("%s: %s: %v", e.Code, e.Message, e.Cause)
    }
    return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error {
    return e.Cause
}

// エラーラッピング
func processData(data []byte) error {
    if err := validate(data); err \!= nil {
        return fmt.Errorf("validation failed: %w", err)
    }
    return nil
}
```

## パフォーマンス最適化

### メモリ管理
- スライスの事前容量確保: `make([]T, 0, capacity)`
- sync.Pool活用でオブジェクト再利用
- context.Contextでタイムアウト制御

### 並行処理
```go
// ワーカープール パターン
func workerPool(jobs <-chan Job, results chan<- Result) {
    const numWorkers = 10
    
    var wg sync.WaitGroup
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobs {
                results <- processJob(job)
            }
        }()
    }
    
    go func() {
        wg.Wait()
        close(results)
    }()
}
```

## セキュリティ

### 入力検証
```go
import (
    "github.com/go-playground/validator/v10"
)

type User struct {
    Email    string `validate:"required,email"`
    Password string `validate:"required,min=8"`
    Age      int    `validate:"gte=0,lte=130"`
}

func validateUser(u User) error {
    validate := validator.New()
    return validate.Struct(u)
}
```

### SQL インジェクション対策
```go
// 危険
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)

// 安全
query := "SELECT * FROM users WHERE id = ?"
rows, err := db.Query(query, userID)
```

## ロギング

### 構造化ログ
```go
import (
    "go.uber.org/zap"
)

func setupLogger() *zap.Logger {
    config := zap.Config{
        Level:       zap.NewAtomicLevelAt(zap.InfoLevel),
        Development: false,
        Encoding:    "json",
        EncoderConfig: zap.NewProductionEncoderConfig(),
        OutputPaths: []string{"stdout"},
    }
    
    logger, _ := config.Build()
    return logger
}
```

## 依存関係管理

### go.mod ベストプラクティス
```go
module github.com/user/project

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/stretchr/testify v1.8.4
)

require (
    // indirect dependencies
)
```

### ベンダリング
```bash
# 依存関係を vendor/ に保存
go mod vendor

# ベンダー ディレクトリを使用してビルド
go build -mod=vendor
```

## Docker化

### マルチステージビルド
```dockerfile
# ビルドステージ
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/myapp

# 実行ステージ
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/main .

CMD ["./main"]
```

## CI/CD

### GitHub Actions
```yaml
name: Go CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v3
      with:
        go-version: 1.21
    
    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: ~/go/pkg/mod
        key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
    
    - name: Install dependencies
      run: go mod download
    
    - name: Run tests
      run: go test -v -race -coverprofile=coverage.out ./...
    
    - name: Run linter
      uses: golangci/golangci-lint-action@v3
      with:
        version: latest
    
    - name: Build
      run: go build -v ./...
```

## Makefile

```makefile
.PHONY: build test lint clean

# ビルド
build:
	go build -o bin/myapp ./cmd/myapp

# テスト実行
test:
	go test -v -race -coverprofile=coverage.out ./...

# リント実行
lint:
	golangci-lint run

# フォーマット
fmt:
	gofmt -s -w .
	goimports -w .

# 依存関係更新
deps:
	go mod tidy
	go mod download

# クリーンアップ
clean:
	go clean
	rm -f bin/myapp
	rm -f coverage.out

# 開発環境起動
dev:
	air -c .air.toml

# Docker ビルド
docker-build:
	docker build -t myapp .

# すべて実行
all: fmt lint test build
```

## 推奨ライブラリ

### Web フレームワーク
- **Gin**: 軽量で高速
- **Echo**: ミドルウェア豊富
- **Fiber**: Express.js ライク

### データベース
- **GORM**: ORM
- **sqlx**: SQLビルダー
- **migrate**: マイグレーション

### テスト
- **testify**: アサーション
- **gomock**: モック生成
- **httptest**: HTTPテスト

### ユーティリティ
- **cobra**: CLI構築
- **viper**: 設定管理
- **zap**: 高性能ログ
- **uuid**: UUID生成

## デバッグ・プロファイリング

### pprof使用例
```go
import (
    _ "net/http/pprof"
    "net/http"
)

func main() {
    // pprof エンドポイント有効化
    go func() {
        log.Println(http.ListenAndServe("localhost:6060", nil))
    }()
    
    // アプリケーションロジック
}
```

### デバッグコマンド
```bash
# CPU プロファイル
go tool pprof http://localhost:6060/debug/pprof/profile

# メモリ プロファイル
go tool pprof http://localhost:6060/debug/pprof/heap

# レース検出でテスト
go test -race ./...
```

## 設定管理

### 環境変数とファイル
```go
type Config struct {
    Database struct {
        Host     string `mapstructure:"host"`
        Port     int    `mapstructure:"port"`
        User     string `mapstructure:"user"`
        Password string `mapstructure:"password"`
    } `mapstructure:"database"`
    
    Server struct {
        Port int `mapstructure:"port"`
    } `mapstructure:"server"`
}

func LoadConfig() (*Config, error) {
    viper.SetConfigName("config")
    viper.SetConfigType("yaml")
    viper.AddConfigPath(".")
    viper.AddConfigPath("./config")
    
    // 環境変数を優先
    viper.AutomaticEnv()
    viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
    
    var config Config
    if err := viper.ReadInConfig(); err \!= nil {
        return nil, err
    }
    
    if err := viper.Unmarshal(&config); err \!= nil {
        return nil, err
    }
    
    return &config, nil
}
```
```
