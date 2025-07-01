# aws-cross-account-s3-access

**User**:
aws mcpサーバを使って以下を調べろ

AWS アカウントA から AWS アカウントBに立てた s3 にファイルを保存をする
AWS アカウントB厳密に管理されたプライベート環境であり、Aからのログ保存に限る最小権限が必須だ
YAGNIで実装しろ

**Claude**:
AWS MCP サーバーを使って、クロスアカウントS3アクセスの設定方法を調査します。

## アカウントB（ログ保存先）のS3バケットポリシー

YAGNIで最小権限のバケットポリシー:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAccountALogWrite",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::111111111111:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::account-b-log-bucket/logs/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
```

## アカウントA側のIAMロール設定

アカウントB側でIAMロールを作成（アカウントAが引き受け可能）:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::111111111111:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-external-id-12345"
        }
      }
    }
  ]
}
```

ロールに付与するポリシー:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::account-b-log-bucket/logs/*"
    }
  ]
}
```

## アカウントA側のIAMポリシー設定

アカウントAのEC2インスタンスやLambda関数に付与するポリシー:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::222222222222:role/LogWriterRole"
    }
  ]
}
```

## 実装コード例（Python）

```python
import boto3
import json
from datetime import datetime

def write_log_to_cross_account_s3(log_data):
    # AssumeRoleでアカウントBのロールを引き受ける
    sts = boto3.client('sts')
    assumed_role = sts.assume_role(
        RoleArn='arn:aws:iam::222222222222:role/LogWriterRole',
        RoleSessionName='LogWriterSession',
        ExternalId='unique-external-id-12345'
    )
    
    # 一時的な認証情報を取得
    credentials = assumed_role['Credentials']
    
    # アカウントBのS3クライアントを作成
    s3 = boto3.client(
        's3',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken']
    )
    
    # ログファイルをアップロード
    log_key = f"logs/{datetime.now().strftime('%Y/%m/%d')}/app-{datetime.now().strftime('%Y%m%d-%H%M%S')}.log"
    
    s3.put_object(
        Bucket='account-b-log-bucket',
        Key=log_key,
        Body=json.dumps(log_data),
        ACL='bucket-owner-full-control'  # 必須：バケット所有者に完全な制御を付与
    )
    
    return log_key
```

## まとめ

最小権限でのクロスアカウントS3アクセス設定：

1. **アカウントB（222222222222）のS3バケットポリシー**
   - アカウントAからの`s3:PutObject`のみ許可
   - `/logs/*`配下のみ書き込み可能
   - `bucket-owner-full-control` ACL必須

2. **アカウントBのIAMロール（LogWriterRole）**
   - アカウントAからのAssumeRoleのみ許可
   - ExternalIdで追加のセキュリティ確保
   - S3への最小限の書き込み権限のみ

3. **アカウントA（111111111111）のIAMポリシー**
   - 特定のロールへのAssumeRoleのみ許可

これによりアカウントAからアカウントBのS3への最小権限でのログ保存が実現できます。

