# Go言語開発ベストプラクティスCLAUDE.md作成

**User**:
Go言語を書くためのclaude.mdを検索で調査して、ベストプラクティスで作成して

**Claude**:
Go言語のベストプラクティスに基づいたCLAUDE.mdを作成しました：

```markdown
# Go言語開発のベストプラクティス

## 基本指針

- 常にEffective Goガイドラインに従う
- シンプルさを重視し、必要以上に複雑にしない
- 読みやすく保守しやすいコードを心がける
- Go本来の特徴を活かした設計を行う

## コーディング規約

### フォーマット
- gofmtを必ず使用する
- インデントはタブを使用（スペースは特別な場合のみ）
- 行長制限はなし（必要に応じて改行し、追加タブでインデント）

### 命名規則
- パッケージ名：短く、小文字、アンダースコア不使用
- 関数名：CamelCase（公開）、camelCase（非公開）
- 変数名：短く明確、略語は避ける
- 定数名：CamelCase（ALL_CAPSは使わない）

### エラーハンドリング
- エラーは早期にチェックし、適切に処理する
- panic/recoverは例外的な場合のみ使用
- カスタムエラー型を適切に活用
```go
if err \!= nil {
    return fmt.Errorf("operation failed: %w", err)
}
```

## プロジェクト構造

### 基本構成
```
project/
├── cmd/           # メインアプリケーション
│   └── myapp/
│       └── main.go
├── internal/      # 内部パッケージ（外部からimport不可）
├── pkg/          # 外部から利用可能なライブラリ
├── api/          # API定義（OpenAPI、Protocol Buffers）
├── configs/      # 設定ファイル
├── docs/         # ドキュメント
├── scripts/      # ビルド・デプロイスクリプト
├── test/         # テストデータ・ヘルパー
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

### 成長戦略
- 小さく始める（main.go + go.modのみ）
- 必要に応じて段階的に構造化
- importサイクルを避ける設計
- パッケージの責任を明確に分離

## 開発プラクティス

### インターfaces設計
- 小さなinterfaceを推奨（1-3メソッド）
- 使用する側で定義する（依存関係の逆転）
- 具象型ではなくinterfaceで受け取る

### 並行処理
- goroutineとchannelを適切に活用
- sync.WaitGroup、context.Contextを使った制御
- データ競合を避ける設計
- "Don't communicate by sharing memory; share memory by communicating"

### テスト戦略
- テスト駆動開発（TDD）を実践
- テーブル駆動テストを活用
- モックは最小限に抑制
- ベンチマークテストで性能測定
```go
func TestFunction(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        expected string
    }{
        {"case1", "input1", "expected1"},
        {"case2", "input2", "expected2"},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Function(tt.input)
            if result \!= tt.expected {
                t.Errorf("got %v, want %v", result, tt.expected)
            }
        })
    }
}
```

## 品質管理

### 静的解析ツール
- `go vet`: 基本的な問題を検出
- `golangci-lint`: 包括的なlinting
- `go mod tidy`: 依存関係の整理
- `govulncheck`: セキュリティ脆弱性チェック

### CI/CD統合
```yaml
# .github/workflows/go.yml
name: Go
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    - run: go mod tidy
    - run: go vet ./...
    - run: go test -race -coverprofile=coverage.out ./...
    - run: golangci-lint run
```

## パフォーマンス最適化

### プロファイリング
- `go tool pprof`でCPU・メモリプロファイル
- ベンチマークテストで測定
- アロケーション最適化

### 最適化ポイント
- 不要なアロケーションを避ける
- string操作でstrings.Builderを活用
- sync.Poolでオブジェクト再利用
- 適切なデータ構造選択

## セキュリティ

### 基本対策
- 入力値検証の徹底
- SQL injection対策
- CSRF、XSS対策
- 機密情報のハードコード禁止

### 暗号化
- crypto/tlsでセキュア通信
- 適切なハッシュ関数選択
- 乱数生成はcrypto/randを使用

## 依存関係管理

### Go Modules
- semantic versioningに従う
- 最小バージョン選択の理解
- replace directiveの適切な使用
- vendoringの検討

### サードパーティライブラリ
- 必要最小限に抑制
- ライセンス確認
- セキュリティアップデート追跡
- 代替ライブラリの評価

## ドキュメント

### コメント規約
- 公開関数・型には必ずコメント
- パッケージドキュメントはdoc.goに記述
- exampleテストでAPI使用例を提供

### API設計
- RESTful設計原則
- OpenAPI仕様書の作成
- バージョニング戦略
- 後方互換性の維持

## デバッグ・ログ

### ログ設計
- 構造化ログ（JSON形式）
- ログレベルの適切な設定
- 機密情報の除外
- パフォーマンスへの影響考慮

### デバッグツール
- delveデバッガーの活用
- `go tool trace`でgoroutine分析
- メトリクス収集（Prometheus等）

## デプロイメント

### コンテナ化
```dockerfile
# Multi-stage buildの例
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o main cmd/myapp/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
CMD ["./main"]
```

### 設定管理
- 環境変数での設定外部化
- 設定ファイルの階層化
- 機密情報の分離管理
- 設定検証の実装

## モニタリング

### ヘルスチェック
- `/health`エンドポイント実装
- 依存サービスの状態確認
- graceful shutdown実装

### メトリクス
- アプリケーションメトリクス収集
- SLI/SLO定義
- アラート設定
- ダッシュボード作成

この設定により、Go言語での開発において品質、保守性、パフォーマンスを重視したベストプラクティスに従った開発が可能になります。
```

