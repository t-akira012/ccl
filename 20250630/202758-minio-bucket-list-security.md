# minio-bucket-list-security

**User**:
minioでバケットのリスト一覧が見えている。
publicにはバケットリスト一覧を非公開にしたい。
手順を教えろ

**Claude**:
MinIOでバケット一覧を非公開にする手順：

## 1. MinIO管理コンソールでの設定

### 方法1: バケットポリシーで制限
```bash
# MinIO Client (mc) を使用してバケットリストを非公開に
mc anonymous set none myminio/
```

### 方法2: IAMポリシーでの制御
1. MinIO管理コンソール（通常は :9001 ポート）にアクセス
2. **Identity** → **Policies** で新しいポリシーを作成
3. 以下のようなポリシーを設定：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    }
  ]
}
```

## 2. 設定ファイルでの制御

### docker-compose.yml での環境変数設定
```yaml
environment:
  - MINIO_BROWSER_REDIRECT_URL=off
  - MINIO_API_CORS_ALLOW_ORIGIN=
```

## 3. nginx リバースプロキシでの制限

```nginx
location /minio/ {
    if ($request_uri ~* "^/minio/?$") {
        return 403;
    }
    proxy_pass http://minio:9000/;
}
```

## 4. 確認方法

```bash
# バケット一覧の取得を試行（拒否されることを確認）
curl -X GET http://your-minio-server:9000/
```

最も効果的なのは **IAMポリシー** での制御です。

