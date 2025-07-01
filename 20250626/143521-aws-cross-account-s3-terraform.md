# aws-cross-account-s3-terraform

**User**:
アカウントB（ログ保存先）のS3バケットポリシーとアカウントA側のIAMロール設定をTerraformで記述してください。

**Claude**:
```hcl
# アカウントB側のリソース（ログ保存先）

resource "aws_s3_bucket" "log_bucket" {
  bucket = "account-b-log-bucket"
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountALogWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::111111111111:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/logs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "log_writer_role" {
  name = "LogWriterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::111111111111:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "unique-external-id-12345"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "log_writer_policy" {
  name = "LogWriterPolicy"
  role = aws_iam_role.log_writer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/logs/*"
      }
    ]
  })
}
```

```hcl
# アカウントA側のリソース

resource "aws_iam_policy" "assume_log_writer_role" {
  name = "AssumeLogWriterRolePolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::222222222222:role/LogWriterRole"
      }
    ]
  })
}

# EC2インスタンスプロファイル用のロール
resource "aws_iam_role" "ec2_log_writer" {
  name = "EC2LogWriterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_log_writer_attach" {
  role       = aws_iam_role.ec2_log_writer.name
  policy_arn = aws_iam_policy.assume_log_writer_role.arn
}

# Lambda関数用のロール
resource "aws_iam_role" "lambda_log_writer" {
  name = "LambdaLogWriterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_log_writer_attach" {
  role       = aws_iam_role.lambda_log_writer.name
  policy_arn = aws_iam_policy.assume_log_writer_role.arn
}
```

