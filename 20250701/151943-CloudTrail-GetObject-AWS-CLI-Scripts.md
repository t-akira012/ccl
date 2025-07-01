# CloudTrail-GetObject-AWS-CLI-Scripts

**User**:
OK。Cloudtrailでhoge-bcuketのGetObject証跡を取るのと、あと、AWS CLIで当月Getログを全て取得するスクリプトを作っておいてくれ
追加で、AWSCLIで、Orgに存在するアカウントXのAWS IICによる当月のログインを取得するAWS CLIも作って。

**Claude**:
```terraform
# CloudTrail設定（GetObjectのみ）
resource "aws_cloudtrail" "hoge" {
  name           = "hoge-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id

  event_selector {
    read_write_type = "Read"  # GetObjectのみ
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::hoge-bucket/*"]
    }
  }
}
```

```bash
#\!/bin/bash
# 当月のGetObjectログ取得スクリプト

# 当月の開始日と終了日を取得
START_DATE=$(date -u +%Y-%m-01T00:00:00Z)
END_DATE=$(date -u +%Y-%m-%dT23:59:59Z)

# CloudTrailからGetObjectイベントを検索
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GetObject \
  --start-time "$START_DATE" \
  --end-time "$END_DATE" \
  --query 'Events[?Resources[?ResourceName==`arn:aws:s3:::hoge-bucket/*`]]' \
  --output json > get_object_logs_$(date +%Y%m).json
```

```bash
#\!/bin/bash
# OrganizationのアカウントXのAWS Identity Center当月ログイン取得

# 変数設定
ACCOUNT_ID="123456789012"  # アカウントXのID
START_DATE=$(date -u +%Y-%m-01T00:00:00Z)
END_DATE=$(date -u +%Y-%m-%dT23:59:59Z)

# AWS SSOログインイベントを検索
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=Authenticate \
  --start-time "$START_DATE" \
  --end-time "$END_DATE" \
  --query "Events[?contains(EventName, 'Authenticate') && contains(UserIdentity.accountId, '$ACCOUNT_ID')]" \
  --output json > sso_login_logs_${ACCOUNT_ID}_$(date +%Y%m).json
```

