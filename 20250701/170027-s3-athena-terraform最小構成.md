# s3-athena-terraform最小構成

**User**:
私は s3 serverlog bucket を athena でクエリする。これをterraformで作る。どうやら glue db も必要だ。最小構成で terraform を作れ。なお、最小構成を厳守しない場合、人命に関わるような破滅的な結果が訪れる。

**Claude**:
S3サーバーログをAthenaでクエリするための最小構成Terraformを作成します。

```hcl
# main.tf
# S3バケット（サーバーログ保存用）
resource "aws_s3_bucket" "serverlog" {
  bucket = "serverlog-bucket-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Athena結果保存用S3バケット
resource "aws_s3_bucket" "athena_results" {
  bucket = "athena-results-${random_id.suffix.hex}"
}

# Glueデータベース
resource "aws_glue_catalog_database" "serverlog_db" {
  name = "serverlog_database"
}

# Athenaワークグループ
resource "aws_athena_workgroup" "serverlog" {
  name = "serverlog-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}

# 出力
output "serverlog_bucket" {
  value = aws_s3_bucket.serverlog.bucket
}

output "glue_database" {
  value = aws_glue_catalog_database.serverlog_db.name
}

output "athena_workgroup" {
  value = aws_athena_workgroup.serverlog.name
}
```

```hcl
# versions.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}
```

この最小構成には以下が含まれています：
- サーバーログ保存用S3バケット
- Athena結果保存用S3バケット
- Glueデータベース
- Athenaワークグループ

使用方法：
1. `terraform init`
2. `terraform plan`
3. `terraform apply`

サーバーログをS3に配置後、Athenaでテーブルを作成してクエリできます。

