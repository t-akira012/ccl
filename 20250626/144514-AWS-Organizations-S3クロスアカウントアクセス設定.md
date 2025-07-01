# AWS-Organizations-S3クロスアカウントアクセス設定

**User**:
AWSである。一つのaws orgで、アカウントAから、アカウントBに、S3バケットにオブジェクトをputしたい。

この場合はどのようなIAM設定が必要か。なおaws orgではIAMユーザーを利用せず、AWS IICでログインしている。

**Claude**:
AWS Organizations環境で、アカウントAからアカウントBのS3バケットにオブジェクトをPUTする場合、以下のIAM設定が必要です：

## 1. アカウントB側の設定（S3バケット所有者）

### S3バケットポリシー
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCrossAccountPutObject",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::アカウントAのID:root"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::バケット名/*"
    }
  ]
}
```

## 2. アカウントA側の設定（アクセス元）

### IAMロールまたはユーザーのポリシー
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::アカウントBのバケット名/*"
    }
  ]
}
```

## AWS SSO（IAM Identity Center）利用時の追加考慮事項

1. **Permission Setの設定**
   - アカウントAのPermission SetにS3 PutObject権限を付与
   - カスタムポリシーまたはAWS管理ポリシーを使用

2. **AssumeRole構成**（必要に応じて）
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": "sts:AssumeRole",
         "Resource": "arn:aws:iam::アカウントBのID:role/CrossAccountS3Role"
       }
     ]
   }
   ```

## オブジェクト所有権の考慮事項

アカウントBのS3バケット設定で「バケット所有者強制」を有効化することを推奨：
- これによりアカウントAがPUTしたオブジェクトの所有権が自動的にアカウントBに移る
- ACL関連の権限設定が簡素化される

**User**:
aws mcpを使い、ドキュメント的な正しさも精査すること

**Claude**:
AWS MCPを使用して、クロスアカウントS3アクセスに関する公式ドキュメントを確認します。

[AWS公式ドキュメントの検索と確認]

公式ドキュメントを確認した結果、AWS Organizations環境でIAM Identity Centerを使用し、アカウントAからアカウントBのS3バケットにオブジェクトをPUTする場合の正確な設定は以下の通りです：

## 修正版：クロスアカウントS3アクセス設定

### 1. アカウントB側（S3バケット所有者）の設定

#### S3バケットポリシー
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCrossAccountPutObject",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::アカウントAのID:root"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::バケット名/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
```

### 2. アカウントA側（アクセス元）の設定

#### IAM Identity CenterのPermission Set
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::アカウントBのバケット名/*"
    }
  ]
}
```

### 3. 重要な考慮事項

#### オブジェクト所有権
- **推奨設定**: アカウントBのS3バケットで「バケット所有者強制」を有効化
- これにより、アカウントAがアップロードしたオブジェクトの所有権が自動的にアカウントBに移転

#### S3 Access Grantsの活用（オプション）
より細かいアクセス制御が必要な場合は、S3 Access Grantsの使用を検討：
1. アカウントBでS3 Access Grantsインスタンスを作成
2. リソースポリシーでアカウントAへのアクセスを許可
3. 特定のIAMプリンシパルに対してグラントを作成

### 4. 実装時の注意点

1. **Principal指定**: `"AWS": "arn:aws:iam::アカウントAのID:root"`はアカウント全体への権限付与を意味する
2. **ACL設定**: `bucket-owner-full-control`の指定により、アップロードされたオブジェクトの制御権をバケット所有者が保持
3. **セキュリティ**: 必要最小限の権限のみを付与し、定期的にアクセス監査を実施

**User**:
Okay. Terraformを使い、account_A.tf, account_B.tf の実装例を作れ。ただし、リソースだけで良い。モジュールなどは他にある。

**Claude**:
Terraformを使用したクロスアカウントS3アクセスの実装例を作成します。

## account_B.tf (S3バケット所有者側)

```hcl
# S3バケット
resource "aws_s3_bucket" "cross_account_bucket" {
  bucket = "cross-account-bucket-${data.aws_caller_identity.current.account_id}"
}

# バケット所有者強制設定
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.cross_account_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# パブリックアクセスブロック
resource "aws_s3_bucket_public_access_block" "bucket_pab" {
  bucket = aws_s3_bucket.cross_account_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# バケットポリシー
resource "aws_s3_bucket_policy" "cross_account_policy" {
  bucket = aws_s3_bucket.cross_account_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPutObject"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_a_id}:root"
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.cross_account_bucket.arn}/*"
      }
    ]
  })
}

# 現在のアカウントID取得用
data "aws_caller_identity" "current" {}
```

## account_A.tf (アクセス元側)

```hcl
# IAM Identity Center Permission Set
resource "aws_ssoadmin_permission_set" "s3_cross_account_access" {
  name             = "S3CrossAccountAccess"
  description      = "Permission to put objects to Account B S3 bucket"
  instance_arn     = var.sso_instance_arn
  session_duration = "PT2H"
}

# インラインポリシー
resource "aws_ssoadmin_permission_set_inline_policy" "s3_policy" {
  inline_policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::cross-account-bucket-${var.account_b_id}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::cross-account-bucket-${var.account_b_id}"
      }
    ]
  })
  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.s3_cross_account_access.arn
}

# Permission Setの割り当て
resource "aws_ssoadmin_account_assignment" "s3_assignment" {
  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.s3_cross_account_access.arn

  principal_id   = var.principal_id
  principal_type = var.principal_type  # "USER" or "GROUP"

  target_id   = data.aws_caller_identity.current.account_id
  target_type = "AWS_ACCOUNT"
}

# 現在のアカウントID取得用
data "aws_caller_identity" "current" {}
```

## 必要な変数（両ファイル共通）

```hcl
# account_B.tf用の変数
variable "account_a_id" {
  description = "Account A ID for cross-account access"
  type        = string
}

# account_A.tf用の変数
variable "account_b_id" {
  description = "Account B ID where S3 bucket exists"
  type        = string
}

variable "sso_instance_arn" {
  description = "SSO instance ARN"
  type        = string
}

variable "principal_id" {
  description = "Principal ID (user or group) to assign permission"
  type        = string
}

variable "principal_type" {
  description = "Principal type (USER or GROUP)"
  type        = string
  default     = "USER"
}
```

## 使用上の注意

1. **実行順序**: account_B.tfを先に適用してS3バケットを作成
2. **バケット名**: 実際の環境では一意のバケット名を使用
3. **権限の最小化**: 必要に応じてResource部分をより具体的に制限
4. **監査**: CloudTrailでクロスアカウントアクセスを監視

**User**:
account_AではIICのユーザー（Human）がS3 Putを利用する前提に見える。しかし、S3 Putは人ではなくマネージドサービスだけが行う

**Claude**:
なるほど、マネージドサービスがS3 PUTを実行する場合の設定に修正します。

## account_A.tf (マネージドサービス用に修正)

```hcl
# Lambda関数用のIAMロール
resource "aws_iam_role" "s3_cross_account_role" {
  name = "s3-cross-account-put-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "glue.amazonaws.com",
            "states.amazonaws.com"  # Step Functions
          ]
        }
      }
    ]
  })
}

# クロスアカウントS3アクセスポリシー
resource "aws_iam_role_policy" "s3_cross_account_policy" {
  name = "s3-cross-account-put-policy"
  role = aws_iam_role.s3_cross_account_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::cross-account-bucket-${var.account_b_id}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::cross-account-bucket-${var.account_b_id}"
      }
    ]
  })
}

# 基本的なLambda実行ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.s3_cross_account_role.name
}

# EventBridge用のIAMロール（Lambda起動用）
resource "aws_iam_role" "eventbridge_role" {
  name = "eventbridge-lambda-invoke-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

# EventBridgeからLambda起動ポリシー
resource "aws_iam_role_policy" "eventbridge_lambda_policy" {
  name = "eventbridge-lambda-invoke-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
      }
    ]
  })
}

# ECS Task用のIAMロール（必要な場合）
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-s3-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ECS Taskロールにも同じS3ポリシーをアタッチ
resource "aws_iam_role_policy" "ecs_s3_policy" {
  name = "ecs-s3-cross-account-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::cross-account-bucket-${var.account_b_id}/*"
      }
    ]
  })
}

# データソース
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```

## account_B.tf (変更なし、ただしPrincipal部分を明確化)

```hcl
# S3バケット
resource "aws_s3_bucket" "cross_account_bucket" {
  bucket = "cross-account-bucket-${data.aws_caller_identity.current.account_id}"
}

# バケット所有者強制設定
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.cross_account_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# パブリックアクセスブロック
resource "aws_s3_bucket_public_access_block" "bucket_pab" {
  bucket = aws_s3_bucket.cross_account_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# バケットポリシー（サービスロールを明示的に許可）
resource "aws_s3_bucket_policy" "cross_account_policy" {
  bucket = aws_s3_bucket.cross_account_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountServicePutObject"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.account_a_id}:role/s3-cross-account-put-role",
            "arn:aws:iam::${var.account_a_id}:role/ecs-s3-cross-account-role"
          ]
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.cross_account_bucket.arn}/*"
      }
    ]
  })
}

# 現在のアカウントID取得用
data "aws_caller_identity" "current" {}
```

## 主な変更点

1. **IAM Identity Center削除**: 人間のユーザーではなくサービスがアクセスするため
2. **サービスロール追加**: Lambda、Glue、ECS等のマネージドサービス用ロール
3. **Principalの具体化**: account_B側で特定のロールのみを許可
4. **最小権限の原則**: 必要なサービスのみがAssumeRole可能

**User**:
書き方がわかりづらいです。ECSだけにしてください書き方がわかりづらいです。全てのサービスに使える汎用的なものは無理？aws mcpを利用して

**Claude**:
AWS MCPで確認して、ECSに特化したシンプルな実装と、汎用的なサービスロールについて調査します。

[AWS MCP検索実行]

シンプルにECSのみに特化した実装と、汎用的なサービスロールの実装例を示します。

## ECSのみに特化したシンプルな実装

### account_A.tf (ECS専用)
```hcl
# ECSタスク用のIAMロール
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-cross-account-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# S3クロスアカウントアクセスポリシー
resource "aws_iam_role_policy" "ecs_s3_policy" {
  name = "ecs-s3-cross-account-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      Resource = "arn:aws:s3:::${var.bucket_name}/*"
    }]
  })
}
```

### account_B.tf (ECS専用)
```hcl
# S3バケット
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
}

# バケット所有者強制
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# バケットポリシー
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.account_a_id}:role/ecs-cross-account-s3-role"
      }
      Action = [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      Resource = "${aws_s3_bucket.main.arn}/*"
    }]
  })
}
```

## 汎用的なサービスロール実装

### account_A.tf (汎用版)
```hcl
# 汎用的なサービスロール
resource "aws_iam_role" "service_s3_role" {
  name = "cross-account-s3-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = var.aws_services
      }
    }]
  })
}

# S3アクセスポリシー
resource "aws_iam_role_policy" "service_s3_policy" {
  name = "cross-account-s3-policy"
  role = aws_iam_role.service_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      Resource = "arn:aws:s3:::${var.bucket_name}/*"
    }]
  })
}

# 変数定義
variable "aws_services" {
  description = "AWS services that can assume this role"
  type        = list(string)
  default = [
    "ecs-tasks.amazonaws.com",
    "lambda.amazonaws.com",
    "glue.amazonaws.com",
    "states.amazonaws.com",
    "batch.amazonaws.com"
  ]
}
```

### account_B.tf (汎用版)
```hcl
# S3バケット
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
}

# バケット所有者強制
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# バケットポリシー（ロールベース）
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.account_a_id}:role/cross-account-s3-service-role"
      }
      Action = [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      Resource = "${aws_s3_bucket.main.arn}/*"
    }]
  })
}
```

## 共通変数
```hcl
variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "account_a_id" {
  description = "Account A ID"
  type        = string
}
```

## ポイント

1. **ECS専用版**: 最もシンプルで理解しやすい
2. **汎用版**: 複数のAWSサービスで同じロールを使い回せる
3. **セキュリティ**: 必要なサービスのみを`aws_services`変数で指定
4. **管理の簡素化**: 1つのロールで複数サービスに対応

