# Cloudflare Tunnel SSH 完全ガイド

## 概要

Cloudflare Tunnelを使用してSSHサーバーに安全にアクセスする方法の完全ガイドです。インバウンドポートを開くことなく、インターネット経由でSSHアクセスを可能にします。

## 重要な前提知識

### Cloudflare Tunnelの仕組み
- **独自プロトコル**: HTTP/2やQUICベースの独自プロトコルを使用
- **認証機構**: Cloudflare Access使用時はJWT認証が必要
- **暗号化**: TLS内でさらに独自の暗号化を実施

### 制限事項
- **cloudflaredクライアントは必須**: 独自プロトコルのため、専用クライアントなしでは接続不可
- **通常のnetcat/telnetでは疎通確認不可**: Cloudflare Tunnel経由のポートは通常の方法では確認できない

## セットアップ方法

### 前提条件
- Cloudflareアカウントに登録済みのドメイン
- Cloudflare Zero Trustアカウント（無料プランでも可）
- SSHサーバーが稼働しているマシン
- cloudflaredのインストール権限

### サーバー側セットアップ

#### 1. cloudflaredのインストール

```bash
# Linux (Debian/Ubuntu)
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Linux (直接バイナリ)
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

# macOS
brew install cloudflare/cloudflare/cloudflared
```

#### 2. 認証とトンネル作成

```bash
# Cloudflareにログイン
cloudflared tunnel login

# トンネルの作成
cloudflared tunnel create <TUNNEL_NAME>
```

#### 3. 設定ファイルの作成

`~/.cloudflared/config.yml`:
```yaml
tunnel: <TUNNEL_ID>
credentials-file: /home/user/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: ssh.example.com
    service: ssh://localhost:22
  - service: http_status:404
```

#### 4. DNSレコードの設定

```bash
cloudflared tunnel route dns <TUNNEL_NAME> ssh.example.com
```

#### 5. トンネルの起動

```bash
# 手動起動
cloudflared tunnel run <TUNNEL_NAME>

# システムサービスとして設定
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

### クライアント側セットアップ

#### 1. cloudflaredのインストール（クライアント側）

サーバー側と同じ方法でインストール

#### 2. SSH接続方法

##### 方法1: コマンドラインで直接指定
```bash
ssh -o ProxyCommand="cloudflared access ssh --hostname %h" user@ssh.example.com
```

##### 方法2: SSH設定ファイルを使用（推奨）
`~/.ssh/config`:
```
Host ssh.example.com
    ProxyCommand cloudflared access ssh --hostname %h
    User your-username
```

以降は通常のSSHコマンドで接続:
```bash
ssh ssh.example.com
```

##### 方法3: ローカルポートフォワーディング
```bash
# ターミナル1でトンネル開始
cloudflared access tcp --hostname ssh.example.com --url localhost:2222

# ターミナル2で接続
ssh -p 2222 user@localhost
```

## トラブルシューティング

### 接続できない場合のチェックリスト

1. **トンネルのステータス確認**
```bash
cloudflared tunnel list
cloudflared tunnel info <TUNNEL_NAME>
```

2. **ログの確認**
```bash
# サーバー側
journalctl -u cloudflared -f

# クライアント側（デバッグモード）
cloudflared access ssh --hostname ssh.example.com --loglevel debug
```

3. **DNS解決の確認**
```bash
dig ssh.example.com
nslookup ssh.example.com
```

### よくあるエラーと対処法

#### "Unable to reach the origin service"
- SSHサービスが起動しているか確認: `sudo systemctl status ssh`
- ファイアウォール設定を確認
- config.ymlのservice設定が正しいか確認

#### "Authentication failed"
- SSH鍵が正しく設定されているか確認
- cloudflaredの認証が有効か確認
- Zero Trustダッシュボードでアクセスポリシーを確認

#### "Tunnel not found"
- トンネルが正しく作成されているか確認
- 設定ファイルのトンネルIDが正しいか確認

## 代替案

### cloudflaredを使いたくない場合

残念ながら、Cloudflare Tunnelの独自プロトコルのため、cloudflaredなしでは接続できません。以下の代替サービスを検討してください：

#### 1. Tailscale
```bash
tailscale ssh user@hostname
```

#### 2. ngrok
```bash
# サーバー側
ngrok tcp 22

# クライアント側
ssh -p [ngrok_port] user@[ngrok_domain]
```

#### 3. Webブラウザ経由のSSH
サーバー側でWeb SSHを設定すれば、ブラウザからアクセス可能

### 一時的な使用方法

#### Dockerコンテナで実行
```bash
docker run -it --rm cloudflare/cloudflared:latest \
  access ssh --hostname ssh.example.com -- user@ssh.example.com
```

#### メモリ上で一時実行
```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 | \
  sh -c 'cat > /tmp/cloudflared && chmod +x /tmp/cloudflared && \
  /tmp/cloudflared access ssh --hostname ssh.example.com -- user@ssh.example.com && \
  rm /tmp/cloudflared'
```

## セキュリティベストプラクティス

1. **アクセスポリシーの設定**
   - Zero Trustダッシュボードで厳格なアクセスポリシーを設定
   - 特定のメールドメインやIPアドレスからのみアクセスを許可

2. **二要素認証の有効化**
   - Cloudflare AccessでMFAを必須に設定

3. **監査ログの確認**
   - Zero Trustダッシュボードでアクセスログを定期的に確認

4. **SSH鍵の管理**
   - 定期的にSSH鍵をローテーション
   - 不要な鍵は削除

## 最も簡単なセットアップ方法

```bash
# 1. cloudflaredを~/.local/binにインストール
mkdir -p ~/.local/bin
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o ~/.local/bin/cloudflared
chmod +x ~/.local/bin/cloudflared

# 2. SSH設定に追加
echo 'Host ssh.example.com
    ProxyCommand ~/.local/bin/cloudflared access ssh --hostname %h' >> ~/.ssh/config

# 3. 接続
ssh user@ssh.example.com
```

## 参考リンク

- [Cloudflare Zero Trust Documentation](https://developers.cloudflare.com/cloudflare-one/)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [SSH Use Cases](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/use-cases/ssh/)