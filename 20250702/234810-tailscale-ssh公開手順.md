# tailscale-ssh公開手順

**User**:
cloudflred ではなく Tailscale でホスト端末のsshを公開する手順を作れ

**Claude**:
# Tailscaleを使用してホスト端末のSSHを公開する手順

## 1. Tailscaleのインストール

### Ubuntu/Debian系
```bash
# パッケージリストを更新
sudo apt update

# 必要なパッケージをインストール
sudo apt install curl

# Tailscaleの公式リポジトリを追加
curl -fsSL https://tailscale.com/install.sh  < /dev/null |  sh
```

### CentOS/RHEL/Fedora系
```bash
# Tailscaleリポジトリを追加
sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo

# Tailscaleをインストール
sudo dnf install tailscale
```

### macOS
```bash
# Homebrewを使用
brew install tailscale
```

### Windows
- [Tailscale公式サイト](https://tailscale.com/download)からインストーラーをダウンロード
- インストーラーを実行してセットアップ

## 2. Tailscaleサービスの開始

```bash
# Tailscaleデーモンを開始・有効化
sudo systemctl enable --now tailscaled
```

## 3. Tailscaleへの認証・接続

```bash
# Tailscaleネットワークに接続
sudo tailscale up
```

- ブラウザが開くので、Tailscaleアカウントでログイン
- 初回の場合はアカウントを作成
- 認証が完了するとTailscaleネットワークに参加

## 4. SSH設定の確認・有効化

### SSHサーバーのインストール（未インストールの場合）
```bash
# Ubuntu/Debian
sudo apt install openssh-server

# CentOS/RHEL/Fedora
sudo dnf install openssh-server
```

### SSHサービスの開始・有効化
```bash
sudo systemctl enable --now ssh
# または
sudo systemctl enable --now sshd
```

### SSH設定の確認
```bash
# SSH設定ファイルを確認
sudo nano /etc/ssh/sshd_config
```

重要な設定項目：
```
# ポート設定（デフォルトは22）
Port 22

# パスワード認証の許可（セキュリティ要件に応じて設定）
PasswordAuthentication yes

# 公開鍵認証の有効化
PubkeyAuthentication yes

# rootログインの制御（推奨：無効化）
PermitRootLogin no
```

設定変更後はSSHサービスを再起動：
```bash
sudo systemctl restart ssh
```

## 5. Tailscale IPアドレスの確認

```bash
# 自分のTailscale IPアドレスを確認
tailscale ip -4
```

## 6. 接続テスト

### 同一Tailscaleネットワーク内の他端末から接続
```bash
# Tailscale IPアドレスを使用してSSH接続
ssh username@100.x.x.x

# 例：ユーザー名がuser、Tailscale IPが100.64.0.1の場合
ssh user@100.64.0.1
```

## 7. セキュリティ設定（推奨）

### ファイアウォール設定
```bash
# UFWの場合（Ubuntu）
sudo ufw allow from 100.64.0.0/10 to any port 22
sudo ufw enable

# firewalldの場合（CentOS/RHEL/Fedora）
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='100.64.0.0/10' port protocol='tcp' port='22' accept"
sudo firewall-cmd --reload
```

### 公開鍵認証の設定（推奨）
```bash
# 接続元端末で鍵ペアを生成
ssh-keygen -t ed25519 -C "your_email@example.com"

# 公開鍵をホスト端末に転送
ssh-copy-id username@100.x.x.x
```

## 8. Tailscale管理設定

### ACL（アクセス制御リスト）の設定
- [Tailscale Admin Console](https://login.tailscale.com/admin)にアクセス
- 「Access Controls」でACLを設定し、必要な端末のみSSHアクセスを許可

### デバイス認証の管理
```bash
# 現在のデバイス状態を確認
tailscale status

# デバイスの承認期限を延長（必要に応じて）
tailscale up --accept-routes
```

## 9. トラブルシューティング

### 接続できない場合の確認項目
```bash
# Tailscale接続状態の確認
tailscale status

# SSH サービス状態の確認
sudo systemctl status ssh

# ポートリスニング状態の確認
sudo netstat -tlnp | grep :22

# ファイアウォール状態の確認
sudo ufw status
# または
sudo firewall-cmd --list-all
```

### ログの確認
```bash
# SSH接続ログの確認
sudo journalctl -u ssh -f

# Tailscaleログの確認
sudo journalctl -u tailscaled -f
```

## 利点

- **シンプルな設定**: 複雑なポートフォワーディング不要
- **セキュア**: WireGuardベースの暗号化通信
- **NAT越え**: NATやファイアウォール背後からでもアクセス可能
- **管理が容易**: Web管理画面でデバイス管理
- **マルチプラットフォーム**: Windows、macOS、Linux、モバイル対応

この手順でTailscaleを使用してセキュアなSSHアクセスが設定できます。

