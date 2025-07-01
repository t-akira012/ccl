# aws-s3-log-analysis

**User**:
aws s3サーバーアクセスログを保存している。GetObjectのログを取得したいが、Athenaの利用が推奨されている。ただ、それは面倒だ。もっと楽にできないか？単にAPIを叩けば良いのではないかと思う

**Claude**:
AWS S3サーバーアクセスログからGetObjectのログを取得する、より簡単な方法をいくつか提案します：

## 1. AWS CLI + jq による直接フィルタリング
```bash
# S3からログファイルをダウンロードして直接grep
aws s3 cp s3://your-log-bucket/logs/ . --recursive
grep "GET.*GetObject" *.log  < /dev/null |  head -20
```

## 2. S3 Select を使用（推奨）
```bash
# S3 Selectで直接SQL実行（Athenaより軽量）
aws s3api select-object-content \
  --bucket your-log-bucket \
  --key "logs/2024/01/01/log-file.log" \
  --expression "SELECT * FROM S3Object s WHERE s._2 LIKE '%GET%' AND s._7 LIKE '%GetObject%'" \
  --expression-type SQL \
  --input-serialization '{"CSV":{"FileHeaderInfo":"NONE"}}' \
  --output-serialization '{"CSV":{}}' \
  output.csv
```

## 3. Lambda + EventBridge での自動処理
```python
# Lambda関数でリアルタイム処理
import boto3
import re

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        # ログファイル取得
        obj = s3.get_object(Bucket=bucket, Key=key)
        logs = obj['Body'].read().decode('utf-8')
        
        # GetObjectログのみ抽出
        get_object_logs = [line for line in logs.split('\n') 
                          if 'GET' in line and 'GetObject' in line]
        
        # 結果を別のS3バケットに保存
        filtered_key = f"filtered/{key}"
        s3.put_object(Bucket='filtered-logs-bucket', 
                     Key=filtered_key, 
                     Body='\n'.join(get_object_logs))
```

## 4. 最も簡単な方法：AWS CloudShell
```bash
# CloudShellで直接実行
aws s3 sync s3://your-log-bucket/logs/ ./logs/
find ./logs -name "*.log" -exec grep -l "GetObject" {} \; | \
  xargs grep "GET.*GetObject" > getobject_logs.txt
```

**推奨**: S3 Selectが最もバランスが良く、Athenaより簡単でコスト効率も良いです。

**User**:
S3 Selectか。それは良い手だ。そもそもS3サーバーアクセスログではなく、CloudTrailでGetObjectのログは取れないのか

**Claude**:
CloudTrailでGetObjectのログを取得することについて説明します：

## CloudTrailとGetObjectの関係

**残念ながら、CloudTrailはデフォルトでGetObjectを記録しません。**

### 理由
1. **データイベントとして分類**: GetObjectは「データイベント」に分類される
2. **デフォルトで無効**: 管理イベントのみがデフォルトで有効
3. **コストの問題**: GetObjectは大量に発生するため、全て記録するとコストが高い

## CloudTrailでGetObjectを記録する方法

### 1. データイベントを有効化
```bash
# 特定のバケットのデータイベントを有効化
aws cloudtrail put-event-selectors \
  --trail-name my-trail \
  --event-selectors '[{
    "ReadWriteType": "ReadOnly",
    "IncludeManagementEvents": true,
    "DataResources": [{
      "Type": "AWS::S3::Object",
      "Values": ["arn:aws:s3:::my-bucket/*"]
    }]
  }]'
```

### 2. CloudTrail Lake（推奨）
```sql
-- CloudTrail Lake でクエリ
SELECT 
    eventTime,
    userIdentity.principalId,
    requestParameters,
    sourceIPAddress
FROM 
    my_event_data_store
WHERE 
    eventName = 'GetObject'
    AND eventTime > '2024-01-01'
```

## コスト比較

 < /dev/null |  方法 | コスト | 詳細度 | 設定の簡単さ |
|------|--------|--------|--------------|
| S3サーバーアクセスログ | 低 | 高 | 簡単 |
| CloudTrail データイベント | 高 | 中 | やや複雑 |
| S3 Select + ログ | 中 | 高 | 簡単 |

## 結論

**GetObjectの監視にはS3サーバーアクセスログ + S3 Selectが最適です。**

CloudTrailは以下の場合のみ推奨：
- セキュリティ監査が主目的
- 特定のバケット/オブジェクトのみ監視
- AWS全体の統合監視が必要

**User**:
いや、データイベントを有効化すればできるなら、そっちが推奨では？

**Claude**:
おっしゃる通りです！CloudTrailのデータイベントを有効化する方が実は推奨される場合が多いです。

## CloudTrailデータイベントのメリット

### 1. **統合管理**
- AWS全体のログを一元管理
- 他のAWSサービスと同じ形式
- セキュリティ分析ツールとの連携が容易

### 2. **リアルタイム性**
- EventBridgeと連携可能
- 即座にアラート設定可能
- Lambda での自動処理が簡単

### 3. **詳細な情報**
- IAMユーザー/ロール情報
- セッショントークン
- リクエストの完全な詳細

### 4. **クエリが簡単**
```bash
# CloudTrail Insights でシンプルにクエリ
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GetObject \
  --start-time 2024-01-01T00:00:00Z
```

## コスト最適化のコツ

```json
{
  "EventSelectors": [{
    "ReadWriteType": "ReadOnly",
    "IncludeManagementEvents": false,
    "DataResources": [{
      "Type": "AWS::S3::Object",
      "Values": [
        "arn:aws:s3:::prod-bucket/sensitive/*",
        "arn:aws:s3:::audit-bucket/*"
      ]
    }]
  }]
}
```

**特定のプレフィックスのみ監視することでコスト削減**

## 結論

**セキュリティ・コンプライアンス重視なら CloudTrail データイベントが推奨です。**

S3アクセスログは補助的に使用する位置付けが良いでしょう。

**User**:
では、s3://hoge-bucket/のデータイベント証跡を有効化して、簡単に取得させろ

**Claude**:
S3バケット「hoge-bucket」のデータイベント証跡を有効化して、簡単に取得する手順を示します：

## 1. CloudTrail証跡の作成・更新

```bash
# 既存の証跡がある場合は更新、なければ作成
aws cloudtrail create-trail \
  --name hoge-bucket-trail \
  --s3-bucket-name cloudtrail-logs-bucket

# 証跡を開始
aws cloudtrail start-logging \
  --name hoge-bucket-trail

# データイベントを有効化
aws cloudtrail put-event-selectors \
  --trail-name hoge-bucket-trail \
  --event-selectors '[{
    "ReadWriteType": "All",
    "IncludeManagementEvents": false,
    "DataResources": [{
      "Type": "AWS::S3::Object",
      "Values": ["arn:aws:s3:::hoge-bucket/*"]
    }]
  }]'
```

## 2. 簡単な取得スクリプト

```bash
#\!/bin/bash
# get-s3-access.sh

# 直近24時間のGetObjectイベントを取得
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=arn:aws:s3:::hoge-bucket \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
  --query 'Events[?EventName==`GetObject`].[EventTime,UserIdentity.principalId,RequestParameters]' \
  --output table
```

## 3. リアルタイム監視（EventBridge）

```bash
# EventBridge ルール作成
aws events put-rule \
  --name hoge-bucket-getobject \
  --event-pattern '{
    "source": ["aws.s3"],
    "detail": {
      "eventSource": ["s3.amazonaws.com"],
      "eventName": ["GetObject"],
      "requestParameters": {
        "bucketName": ["hoge-bucket"]
      }
    }
  }'
```

## 4. 即座に使える取得コマンド

```bash
# 最新10件のGetObjectを表示
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GetObject \
  --max-results 10 \
  --query 'Events[*].[EventTime,Username,Resources[0].ResourceName]' \
  --output table  < /dev/null |  grep hoge-bucket
```

これで設定完了です。数分後からログが記録され始めます。

**User**:
Terraformにしろ。

**Claude**:
hoge-bucketのCloudTrailデータイベント設定をTerraformで実装します：

```hcl
# CloudTrail用のS3バケット
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "cloudtrail-logs-bucket-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail用バケットポリシー
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudTrail証跡
resource "aws_cloudtrail" "hoge_bucket_trail" {
  name                          = "hoge-bucket-trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = false
  is_multi_region_trail        = false
  enable_logging               = true

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::hoge-bucket/*"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}

# EventBridge ルール（オプション）
resource "aws_cloudwatch_event_rule" "hoge_bucket_getobject" {
  name        = "hoge-bucket-getobject"
  description = "Capture GetObject events for hoge-bucket"

  event_pattern = jsonencode({
    source = ["aws.s3"]
    detail = {
      eventSource = ["s3.amazonaws.com"]
      eventName   = ["GetObject"]
      requestParameters = {
        bucketName = ["hoge-bucket"]
      }
    }
  })
}

# データ取得用のLambda関数（オプション）
resource "aws_lambda_function" "get_s3_access" {
  filename         = "get-s3-access.zip"
  function_name    = "get-hoge-bucket-access"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      BUCKET_NAME = "hoge-bucket"
    }
  }
}

# Lambda用IAMロール
resource "aws_iam_role" "lambda_role" {
  name = "hoge-bucket-access-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda用IAMポリシー
resource "aws_iam_role_policy" "lambda_policy" {
  name = "hoge-bucket-access-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:LookupEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# 必要なデータソース
data "aws_caller_identity" "current" {}

# 出力
output "trail_name" {
  value = aws_cloudtrail.hoge_bucket_trail.name
}

output "cloudtrail_bucket" {
  value = aws_s3_bucket.cloudtrail_logs.id
}
```

適用コマンド：
```bash
terraform init
terraform plan
terraform apply
```

