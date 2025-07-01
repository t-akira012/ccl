# CloudTrail-Terraform-YAGNI化

**User**:
[CloudTrail用のTerraformコード提示]
Yagniで書き直せ

**Claude**:
```terraform
# S3バケット（CloudTrail用）
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "cloudtrail-${data.aws_caller_identity.current.account_id}"
}

# バケットポリシー
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action = ["s3:GetBucketAcl", "s3:PutObject"]
        Resource = [
          aws_s3_bucket.cloudtrail.arn,
          "${aws_s3_bucket.cloudtrail.arn}/*"
        ]
      }
    ]
  })
}

# CloudTrail
resource "aws_cloudtrail" "hoge" {
  name           = "hoge-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id

  event_selector {
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::hoge-bucket/*"]
    }
  }
}
```

