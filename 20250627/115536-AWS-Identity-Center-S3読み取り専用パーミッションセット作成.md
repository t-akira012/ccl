# AWS-Identity-Center-S3読み取り専用パーミッションセット作成

**User**:
aws mcpを使い、terraformで、AWS IICからログインしたユーザーが、特定のS3バケット（var.vdi_log_bucket_name）に限り操作可能とする最小権限のパーミッションセット作れ。操作権限はバケット内の全てのファイル表示、全てのファイルダウンロードに限る。

**Claude**:
AWS Identity Center（旧AWS SSO）のパーミッションセットをTerraformで作成しました。以下のファイルを作成しました：

## 1. aws_identity_center_s3_permission_set.tf
特定のS3バケットに対する読み取り専用アクセスを提供するパーミッションセットを定義。以下の最小権限を付与：

- **バケットレベル**: ListBucket, GetBucketLocation, GetBucketVersioning, ListBucketVersions
- **オブジェクトレベル**: GetObject, GetObjectVersion, GetObjectMetadata等（ダウンロードに必要な権限）
- **ナビゲーション用**: ListAllMyBuckets（AWSコンソールでバケット一覧を表示するため）

## 2. aws_identity_center_assignment.tf
パーミッションセットをIdentity Centerのグループに割り当てる設定。

## 3. terraform.tfvars.example
必要な変数の例：
- `vdi_log_bucket_name`: 対象のS3バケット名
- `target_account_id`: 割り当て先のAWSアカウントID
- `identity_center_group_name`: Identity Centerのグループ名

## 4. aws_identity_center_s3_readme.md
使用方法、付与される権限の詳細、セキュリティ考慮事項を記載したドキュメント。

この設定により、AWS Identity Centerからログインしたユーザーは、指定されたS3バケット内のファイルの表示とダウンロードのみが可能となり、書き込みや削除などの権限は一切付与されません。

