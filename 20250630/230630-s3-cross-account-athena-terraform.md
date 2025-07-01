# s3-cross-account-athena-terraform

**User**:
承知しました。AthenaをアカウントBに構築し、アカウントAのS3に保存されたS3アクセスログを、クロスアカウントで直接クエリ可能かどうかをAWSドキュメントに厳密に基づいて調査いたします。

調査完了後、実現可否と必要最小限の構成（ポリシーや設定）についてご報告いたします。

# Athenaによる別アカウントS3アクセスログの直接クエリは可能か

**結論:** Amazon Athenaから別AWSアカウントにあるAmazon S3のアクセスログ（オブジェクト）を直接クエリすることは **AWS公式にサポートされています**。実現するには、**アクセス元アカウントBとデータ保有アカウントAの双方で適切な権限設定**を行う必要があります。以下にAWS公式ドキュメントに基づき、必要な設定と留意点を解説します。

## クロスアカウントクエリを実現するための必要な設定

Athenaから別アカウントのS3データへ直接クエリするには、**リソース側（アカウントAのS3バケット）**と**アクセス元側（アカウントBのIAM/Athena）**の両方で権限を付与する必要があります。

* **アカウントA側（S3バケットの設定）:**
  S3バケットに**リソースベースのバケットポリシー**を設定し、アカウントBからの読み取りアクセスを許可します。AWS公式も「異なるアカウントのユーザーにバケットへのアクセス権を付与する場合、バケットポリシーで許可を与える」ことを推奨しています。
  具体的には、バケットポリシーの`Principal`にアカウントBを指定し（例: `"AWS": "arn:aws:iam::<アカウントB ID>:root"`でアカウントB内の全ユーザーやロールを対象にできます）、**許可するアクション**として少なくとも以下を含めます:

  * `s3:GetObject`（オブジェクトの取得）
  * `s3:ListBucket`（バケット内オブジェクトの一覧取得）
  * `s3:GetBucketLocation`（バケットのリージョン情報取得）
    ※上記はAthenaがクエリ実行時に必要とする主な操作です。必要に応じてマルチパート処理関連のアクション（例: ListMultipartUploadParts, AbortMultipartUpload）も含めるのが望ましいです。AWS公式ドキュメントには、クロスアカウントアクセス許可を付与するバケットポリシーの具体例が掲載されています。

* **アカウントB側（IAMポリシーとGlue/Athena設定）:**
  アカウントBでAthenaを実行するユーザーやロールにも、**対象S3バケットへの読み取り権限**を付与する必要があります。Athenaではクエリ実行者の権限がそのままS3アクセスに適用されるため、IAMユーザ/ロールのポリシーで上記と同様に`s3:GetObject`や`s3:ListBucket`等を許可してください。公式ドキュメントでも「Athenaで他アカウントのS3を操作する場合、リソース側ポリシーだけでなく**接続元IAMエンティティにも許可が必要**」と明記されています。

  また、データカタログについては、今回はGlueデータカタログがアカウントBにある前提のため特別な設定は不要です。**アカウントBのGlueデータカタログに、アカウントAのS3ログデータに対応するデータベース・テーブルスキーマを作成**すれば問題ありません（ロケーションにアカウントAのバケットパスを指定）。スキーマは手動で定義するか、必要に応じて**クロスアカウント対応のGlueクローラー**で自動取得することも可能です（クロスアカウントクローリングには追加の設定が必要ですが、単純なログ形式であれば手動登録で十分でしょう）。
  *※参考:* Glueデータカタログ自体をデータ所有側のアカウントAから共有する方法もAWS公式に記載がありますが、その場合はGlue側でのリソースポリシー設定やAthenaのデータソース登録が必要になります。今回は**GlueもAthenaもアカウントB**にあるため、そうした手順を踏まずに**アカウントB上でテーブル定義**を行う方が簡便です。

* **Athenaのクエリ結果出力先:**
  Athenaクエリの結果出力用バケット（`Query result location`）も事前に確認してください。通常はアカウントB内のS3バケットを指定しますが、万一アカウントA側に出力する場合は、同様にそのバケットへの書き込み権限をクロスアカウントで構成する必要があります。

## KMS暗号化やその他の制約への対処

* **オブジェクトがKMS暗号化されている場合:**
  S3アクセスログの対象バケットで**カスタムのAWS KMSキーによる暗号化**が有効な場合、追加のクロスアカウント許可が必要です。具体的には、**KMSキーのキーポリシー**にアカウントBのIAMロール/ユーザーをプリンシパルとして追加し、`kms:Decrypt`や`kms:GenerateDataKey`などのキー使用権限を付与します。同時に、アカウントB側IAMロールのポリシーにも当該KMSキーの利用権限（`kms:Decrypt`等）を含めてください。これにより、Athenaクエリ実行時に暗号化オブジェクトを復号できるようになります。
  *参考:* AWS公式の手順では「**アカウントAのバケットポリシー**でアカウントBロールにアクセス許可を与える」「**アカウントAのKMSキーのポリシー**でアカウントBロールにキー使用許可を与える」「**アカウントB側のIAMロール**にアカウントAのバケットおよびキーへのアクセス許可を与える」の3点が必要と説明されています。

* **リージョンに関する注意:**
  基本的にAthenaは**同一リージョン内のデータ**に対してクエリを実行します。アカウントAのS3バケットがAthenaとは異なるリージョンにある場合、直接クエリすることは非推奨です（ネットワーク遅延やコストの面で不利になります）。ただし、Glueデータカタログをクエリ実行側に置く今回の方法では**リージョンが異なるS3バケットでもクエリ可能**であり、AWS公式回答でもクロスリージョン・クロスアカウント構成はこのパターンでサポートされると言及されています。実運用ではデータとAthenaは同リージョンに揃えるのが望ましいですが、異なる場合でも権限さえ適切に設定すれば機能上はクエリ可能です。

## **まとめ: 構成の可否**

以上を踏まえ、本構成（**アカウントBのAthena/Glue**から**アカウントAのS3アクセスログ**を直接SQLクエリ）は**AWS公式にサポートされた一般的なパターン**です。実現には**アカウントAのS3バケットポリシー**でアクセス許可を与え、**アカウントBのIAM**（および必要ならGlueクローラー用ロール等）でS3アクセス権を付与することが必要不可欠です。公式ドキュメントに沿って正しくポリシーを設定すれば、アカウントBからアカウントA内のS3オブジェクトをAthenaで問題なくクエリできます。

**参考資料:**

* AWS公式: Athenaで別アカウントのS3バケットにアクセスする設定方法
* AWS公式: クロスアカウントのS3アクセス許可に関する解説
* AWS公式: カスタムKMSキー付きバケットへのクロスアカウントアクセス手順
* AWS公式（Knowledge Center相当）: 別アカウントS3データをAthenaでクエリする際のポイント

あなたは添付の資料に基づいて、以下の構成のterraform codeを作りなさい。

- AWSアカウントAでサーバーアクセスログをONにした監査対象バケットを作る
- 監査対象バケットのサーバーアクセスログバケットを作る
- AWSアカウントBで、クロスアカウントアクセスを利用してサーバーアクセスログバケットに対してAthenaクエリをできる環境を作る

**Claude**:
クロスアカウントS3アクセスログのAthenaクエリ環境を構築するTerraformコードを作成いたします。

## アカウントA用Terraformコード（audit-logs-account-a.tf）

```hcl
# Variables
variable "account_b_id" {
  description = "Account B ID for cross-account access"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# Random suffix for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Audit target bucket
resource "aws_s3_bucket" "audit_target" {
  bucket = "audit-target-${var.environment}-${random_id.bucket_suffix.hex}"
}

# Server access logs bucket
resource "aws_s3_bucket" "server_access_logs" {
  bucket = "server-access-logs-${var.environment}-${random_id.bucket_suffix.hex}"
}

# Enable versioning for audit target bucket
resource "aws_s3_bucket_versioning" "audit_target_versioning" {
  bucket = aws_s3_bucket.audit_target.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server access logging configuration
resource "aws_s3_bucket_logging" "audit_target_logging" {
  bucket = aws_s3_bucket.audit_target.id

  target_bucket = aws_s3_bucket.server_access_logs.id
  target_prefix = "access-logs/"
}

# Block public access for audit target bucket
resource "aws_s3_bucket_public_access_block" "audit_target_pab" {
  bucket = aws_s3_bucket.audit_target.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Block public access for server access logs bucket
resource "aws_s3_bucket_public_access_block" "server_access_logs_pab" {
  bucket = aws_s3_bucket.server_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cross-account bucket policy for server access logs
resource "aws_s3_bucket_policy" "server_access_logs_policy" {
  bucket = aws_s3_bucket.server_access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountAthenaAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_b_id}:root"
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketVersions",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          aws_s3_bucket.server_access_logs.arn,
          "${aws_s3_bucket.server_access_logs.arn}/*"
        ]
      }
    ]
  })
}

# Server-side encryption for audit target bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "audit_target_encryption" {
  bucket = aws_s3_bucket.audit_target.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Server-side encryption for server access logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "server_access_logs_encryption" {
  bucket = aws_s3_bucket.server_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle configuration for server access logs
resource "aws_s3_bucket_lifecycle_configuration" "server_access_logs_lifecycle" {
  bucket = aws_s3_bucket.server_access_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Outputs
output "audit_target_bucket_name" {
  description = "Name of the audit target bucket"
  value       = aws_s3_bucket.audit_target.id
}

output "server_access_logs_bucket_name" {
  description = "Name of the server access logs bucket"
  value       = aws_s3_bucket.server_access_logs.id
}

output "server_access_logs_bucket_arn" {
  description = "ARN of the server access logs bucket"
  value       = aws_s3_bucket.server_access_logs.arn
}
```

## アカウントB用Terraformコード（athena-account-b.tf）

```hcl
# Variables
variable "account_a_logs_bucket_name" {
  description = "Server access logs bucket name from Account A"
  type        = string
}

variable "account_a_logs_bucket_arn" {
  description = "Server access logs bucket ARN from Account A"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# Random suffix for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Athena query results bucket
resource "aws_s3_bucket" "athena_results" {
  bucket = "athena-results-${var.environment}-${random_id.bucket_suffix.hex}"
}

# Block public access for Athena results bucket
resource "aws_s3_bucket_public_access_block" "athena_results_pab" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption for Athena results bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results_encryption" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle configuration for Athena results
resource "aws_s3_bucket_lifecycle_configuration" "athena_results_lifecycle" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "delete_old_results"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# IAM role for Athena execution
resource "aws_iam_role" "athena_execution_role" {
  name = "athena-s3-access-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

# IAM policy for cross-account S3 access and Athena operations
resource "aws_iam_policy" "athena_cross_account_policy" {
  name        = "athena-cross-account-s3-policy"
  description = "Policy for Athena to access cross-account S3 logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CrossAccountS3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketVersions",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          var.account_a_logs_bucket_arn,
          "${var.account_a_logs_bucket_arn}/*"
        ]
      },
      {
        Sid    = "AthenaResultsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.athena_results.arn,
          "${aws_s3_bucket.athena_results.arn}/*"
        ]
      },
      {
        Sid    = "GlueDataCatalogAccess"
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchCreatePartition",
          "glue:BatchDeletePartition",
          "glue:BatchUpdatePartition"
        ]
        Resource = "*"
      },
      {
        Sid    = "AthenaAccess"
        Effect = "Allow"
        Action = [
          "athena:BatchGetQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "athena:ListQueryExecutions",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "athena_execution_role_policy" {
  role       = aws_iam_role.athena_execution_role.name
  policy_arn = aws_iam_policy.athena_cross_account_policy.arn
}

# Glue database for S3 access logs
resource "aws_glue_catalog_database" "s3_access_logs_db" {
  name        = "s3_access_logs_db"
  description = "Database for S3 server access logs analysis"
}

# Glue table for S3 access logs
resource "aws_glue_catalog_table" "s3_access_logs_table" {
  name          = "s3_access_logs"
  database_name = aws_glue_catalog_database.s3_access_logs_db.name
  description   = "Table for S3 server access logs"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"                   = "s3-access-logs"
    "compressionType"                 = "none"
    "typeOfData"                      = "file"
    "skip.header.line.count"          = "0"
    "serialization.format"            = "1"
    "field.delim"                     = " "
    "EXTERNAL"                        = "TRUE"
    "projection.enabled"              = "true"
    "projection.year.type"            = "integer"
    "projection.year.range"           = "2020,2030"
    "projection.month.type"           = "integer"
    "projection.month.range"          = "1,12"
    "projection.day.type"             = "integer"
    "projection.day.range"            = "1,31"
    "storage.location.template"       = "s3://${var.account_a_logs_bucket_name}/access-logs/$${year}/$${month}/$${day}/"
  }

  storage_descriptor {
    location      = "s3://${var.account_a_logs_bucket_name}/access-logs/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "s3-access-logs-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
      parameters = {
        "serialization.format" = "1"
        "input.regex"          = "([^ ]*) ([^ ]*) \\[(.*?)\\] ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) \"([^ ]*) ([^ ]*) ([^ ]*)\" ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*)"
      }
    }

    columns {
      name = "bucket_owner"
      type = "string"
    }
    columns {
      name = "bucket_name"
      type = "string"
    }
    columns {
      name = "request_datetime"
      type = "string"
    }
    columns {
      name = "remote_ip"
      type = "string"
    }
    columns {
      name = "requester"
      type = "string"
    }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "operation"
      type = "string"
    }
    columns {
      name = "key"
      type = "string"
    }
    columns {
      name = "request_uri"
      type = "string"
    }
    columns {
      name = "http_status"
      type = "string"
    }
    columns {
      name = "error_code"
      type = "string"
    }
    columns {
      name = "bytes_sent"
      type = "bigint"
    }
    columns {
      name = "object_size"
      type = "bigint"
    }
    columns {
      name = "total_time"
      type = "string"
    }
    columns {
      name = "turn_around_time"
      type = "string"
    }
    columns {
      name = "referrer"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "version_id"
      type = "string"
    }
    columns {
      name = "host_id"
      type = "string"
    }
    columns {
      name = "signature_version"
      type = "string"
    }
    columns {
      name = "cipher_suite"
      type = "string"
    }
    columns {
      name = "authentication_type"
      type = "string"
    }
    columns {
      name = "host_header"
      type = "string"
    }
    columns {
      name = "tls_version"
      type = "string"
    }
    columns {
      name = "access_point_arn"
      type = "string"
    }
    columns {
      name = "acl_required"
      type = "string"
    }
  }
}

# Athena workgroup
resource "aws_athena_workgroup" "s3_access_logs_workgroup" {
  name        = "s3-access-logs-workgroup"
  description = "Workgroup for S3 access logs analysis"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

# Get current account ID
data "aws_caller_identity" "current" {}

# Outputs
output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.s3_access_logs_workgroup.name
}

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.s3_access_logs_db.name
}

output "glue_table_name" {
  description = "Name of the Glue table"
  value       = aws_glue_catalog_table.s3_access_logs_table.name
}

output "athena_execution_role_arn" {
  description = "ARN of the Athena execution role"
  value       = aws_iam_role.athena_execution_role.arn
}

output "athena_results_bucket_name" {
  description = "Name of the Athena results bucket"
  value       = aws_s3_bucket.athena_results.id
}
```

## 使用方法とクエリ例

### terraform.tfvars例（アカウントA）
```hcl
account_b_id = "123456789012"
environment  = "prod"
```

### terraform.tfvars例（アカウントB）
```hcl
account_a_logs_bucket_name = "server-access-logs-prod-abcd1234"
account_a_logs_bucket_arn  = "arn:aws:s3:::server-access-logs-prod-abcd1234"
environment                = "prod"
```

### Athenaクエリ例
```sql
-- 基本的なアクセスログ分析
SELECT 
    bucket_name,
    operation,
    remote_ip,
    http_status,
    COUNT(*) as request_count
FROM s3_access_logs_db.s3_access_logs 
WHERE request_datetime >= '2024-01-01'
GROUP BY bucket_name, operation, remote_ip, http_status
ORDER BY request_count DESC
LIMIT 100;

-- エラーログの分析
SELECT 
    remote_ip,
    operation,
    key,
    http_status,
    error_code,
    request_datetime
FROM s3_access_logs_db.s3_access_logs 
WHERE http_status NOT IN ('200', '204', '206', '304')
AND request_datetime >= '2024-01-01'
ORDER BY request_datetime DESC;
```

この構成により、アカウントBからアカウントAのS3アクセスログを安全にクエリできる環境が構築されます。

