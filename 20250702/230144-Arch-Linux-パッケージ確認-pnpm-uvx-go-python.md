# Arch-Linux-パッケージ確認-pnpm-uvx-go-python

**User**:
Arch LinuxのpacmanとAURで以下のパッケージが利用可能か確認:
1. pnpm - Node.jsのパッケージマネージャー
2. uvx - Python用のツール（uvの一部）
3. go - Go言語
4. python - Python実行環境

正確な最新のパッケージ名を確認してください。

**Claude**:
Arch LinuxのpacmanとAURでの各パッケージの利用可能性について、最新情報を確認しました。

## 1. pnpm - Node.jsのパッケージマネージャー

### 公式リポジトリ（pacman）
- **パッケージ名**: `pnpm`
- **リポジトリ**: extra
- **インストール**: `sudo pacman -S pnpm`
- **状態**: ✅ 利用可能

### AUR
- **pnpm-bin**: Node.js依存なしのスタンドアロン版
- **yarn-pnpm-corepack**: corepack経由でpnpmを提供

## 2. uvx - Python用のツール（uvの一部）

### 公式リポジトリ（pacman）
- **パッケージ名**: `python-uv`
- **リポジトリ**: extra
- **バージョン**: 0.7.17-1
- **インストール**: `sudo pacman -S python-uv`
- **状態**: ✅ 利用可能（uvとuvxコマンドの両方を含む）

※ uvxは`uv tool run`のエイリアスとして機能します

## 3. go - Go言語

### 公式リポジトリ（pacman）
- **パッケージ名**: `go`
- **リポジトリ**: extra
- **インストール**: `sudo pacman -S go`
- **状態**: ✅ 利用可能

### 関連パッケージ
- **gcc-go**: GCCフロントエンド版のGoコンパイラ
- **tinygo**: 組み込みシステム向けLLVMベースコンパイラ
- **go-tools**: 静的解析ツールなど

## 4. python - Python実行環境

### 公式リポジトリ（pacman）
- **パッケージ名**: `python`
- **リポジトリ**: core
- **バージョン**: 3.13.5-1
- **インストール**: `sudo pacman -S python`
- **状態**: ✅ 利用可能

### 関連パッケージ
- **python-pip**: pipパッケージマネージャー（extraリポジトリ）

## まとめ

 < /dev/null |  パッケージ | 公式リポジトリ名 | コマンド | 状態 |
|-----------|----------------|----------|------|
| pnpm | pnpm | `sudo pacman -S pnpm` | ✅ |
| uvx | python-uv | `sudo pacman -S python-uv` | ✅ |
| go | go | `sudo pacman -S go` | ✅ |
| python | python | `sudo pacman -S python` | ✅ |

すべてのパッケージがArch Linuxの公式リポジトリで利用可能です。AURを使用する必要はありません。

