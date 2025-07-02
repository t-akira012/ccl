# arch-linux-mail-notification-tools

**User**:
Arch Linuxでメール通知を送信するための軽量なツールを調査:
1. msmtp - SMTPクライアント
2. ssmtp - シンプルなSMTPクライアント
3. mailx/mail - 標準的なメールクライアント
4. sendmail代替ツール

コンテナ環境での使用に適したツールを確認してください。

**Claude**:
Arch Linuxでメール通知を送信するための軽量なツールについて調査しました。コンテナ環境での使用を考慮した結果を以下にまとめます。

## 調査結果サマリー

### 1. **msmtp - 最も推奨される選択肢**

**特徴:**
- 非常にシンプルで使いやすいSMTPクライアント
- sendmail互換性が高い
- デーモンとして動作しない（コンテナに最適）
- 設定ファイルは `~/.msmtprc` または `$XDG_CONFIG_HOME/msmtp/config`
- OAuth2認証対応

**インストール:**
```bash
# Arch Linux
pacman -S msmtp msmtp-mta

# Alpine Linux（コンテナでよく使用）
apk add msmtp
```

### 2. **ssmtp - 非推奨（メンテナンス終了）**

**重要な注意:**
- sSMTPはメンテナンスされていません
- 代わりにmsmtpまたはOpenSMTPDの使用を推奨

### 3. **mailx/mail - 標準的なメールクライアント**

**推奨パッケージ:**
- `s-nail` パッケージ（mailxコマンドも提供）
- msmtpと組み合わせて使用

```bash
pacman -S s-nail
```

### 4. **コンテナ環境での推奨構成**

**最小構成例（/etc/msmtprc）:**

#### 認証なしリレー（内部ネットワーク）
```
defaults
port 25
tls on

account default
auth off
host smtp-relay.local
domain mycontainer
from notifications@mycontainer
add_missing_date_header on
```

#### Gmail SMTP使用例
```
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile /var/log/msmtp.log

account gmail
host smtp.gmail.com
port 587
from your-email@gmail.com
user your-email@gmail.com
password your-app-password

account default : gmail
```

#### Alpineコンテナ用最小構成
```
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
syslog on

account smtp
from notifications@localhost
auth off
tls off
host 172.17.0.1
port 25

account default : smtp
```

### 5. **コンテナ向けDockerfile例**

```dockerfile
FROM alpine:latest

# msmtpのインストール
RUN apk add --no-cache msmtp mailx ca-certificates

# 設定ファイルのコピー
COPY msmtprc /etc/msmtprc
RUN chmod 600 /etc/msmtprc

# sendmailシンボリックリンク作成
RUN ln -sf /usr/bin/msmtp /usr/sbin/sendmail
```

### 6. **使用例**

```bash
# コマンドラインから送信
echo "Test message"  < /dev/null |  mail -s "Test Subject" recipient@example.com

# msmtp直接使用
printf "Subject: Test\nThis is a test\n" | msmtp recipient@example.com

# PHPからの使用（php.ini設定）
sendmail_path = "/usr/bin/msmtp -t"
```

## 推奨事項

1. **現代的なデプロイメント**: **msmtp** + **msmtp-mta**パッケージを使用
2. **mailコマンド**: **s-nail**パッケージをmsmtpと併用
3. **コンテナ環境**: msmtpが最適（デーモン不要）
4. **ssmtpは避ける**: メンテナンスされていない
5. **ローカル配送が必要な場合**: OpenSMTPDを検討

## セキュリティ考慮事項

- パスワードは環境変数やDockerシークレットで管理
- 設定ファイルのパーミッションは600に設定
- TLS/SSL接続を必ず使用
- Gmailの場合はアプリパスワードを使用（2要素認証必須）

これらのツールは、フルメールサーバーデーモンを実行せずに通知/アラートのみを送信する必要があるコンテナや軽量システムに最適です。

