# 20250101-aws-s3-access-logs-athena-glue-catalog-table-structure

**User**:
AWS S3アクセスログをAthenaでクエリするためのGlue Catalog Tableの構造を調査してください。以下の情報を調べて回答してください：

1. S3アクセスログの標準的なフォーマット（カラム構造）
2. TerraformのGlue Catalog Tableリソースでの定義方法
3. S3アクセスログに対応するパーティション設定
4. 最小構成でのGlue Catalog Table定義

AWS公式ドキュメントやTerraform providerドキュメントを参照して、実際にS3アクセスログをクエリできる最小構成のテーブル定義を提供してください。

**Claude**:
AWS S3アクセスログをAthenaでクエリするためのGlue Catalog Tableの構造について詳細に調査しました。以下に調査結果をまとめます。

## 1. S3アクセスログの標準的なフォーマット（カラム構造）

AWS S3サーバーアクセスログは、スペース区切りのフィールドで構成されるテキストファイルです。以下が完全なカラム構造です：

### 基本フィールド（25個）
1. **Bucket Owner** - バケット所有者のCanonical User ID
2. **Bucket** - リクエスト対象のバケット名
3. **Time** - リクエスト受信時刻（UTC、[%d/%b/%Y:%H:%M:%S %z]形式）
4. **Remote IP** - リクエスト元のIPアドレス
5. **Requester** - リクエスト者のCanonical User IDまたはIAMユーザー情報
6. **Request ID** - S3が生成する一意のリクエストID
7. **Operation** - 実行された操作（例：REST.GET.OBJECT、REST.PUT.OBJECT）
8. **Key** - オブジェクトキー（オブジェクト名）
9. **Request-URI** - HTTPリクエストのRequest-URI部分
10. **HTTP Status** - HTTPステータスコード
11. **Error Code** - S3エラーコード（エラーがない場合は「-」）
12. **Bytes Sent** - 送信されたレスポンスバイト数
13. **Object Size** - オブジェクトの総サイズ
14. **Total Time** - リクエストの総処理時間（ミリ秒）
15. **Turn-Around Time** - S3内部でのリクエスト処理時間（ミリ秒）
16. **Referer** - HTTP Refererヘッダーの値
17. **User-Agent** - HTTP User-Agentヘッダーの値
18. **Version Id** - リクエストのバージョンID
19. **Host Id** - x-amz-id-2またはS3拡張リクエストID
20. **Signature Version** - 署名バージョン（SigV2またはSigV4）
21. **Cipher Suite** - TLS暗号スイート
22. **Authentication Type** - 認証タイプ（AuthHeader、QueryString等）
23. **Host Header** - S3エンドポイント
24. **TLS Version** - TLSバージョン
25. **Access Point ARN** - アクセスポイントのARN（使用時）
26. **ACL Required** - ACLが必要かどうか（「Yes」または「-」）

### ログエントリの例
```
79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be amzn-s3-demo-bucket1 [06/Feb/2019:00:00:38 +0000] 192.0.2.3 79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be 3E57427F3EXAMPLE REST.GET.VERSIONING - "GET /amzn-s3-demo-bucket1?versioning HTTP/1.1" 200 - 113 - 7 - "-" "S3Console/0.4" - s9lzHYrFp76ZVxRcpX9+5cjAnEH2ROuNkd2BHfIa6UkFVdtjf5mKR3/eTPFvsiP/XV/VLi31234= SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader amzn-s3-demo-bucket1.s3.us-west-1.amazonaws.com TLSV1.2 arn:aws:s3:us-west-1:123456789012:accesspoint/example-AP Yes
```

## 2. TerraformのGlue Catalog Tableリソースでの定義方法

TerraformでS3アクセスログ用のGlue Catalog Tableを定義する場合、以下の要素が必要です：

### 必要なリソース
- `aws_glue_catalog_database` - テーブルを格納するデータベース
- `aws_glue_catalog_table` - S3アクセスログ用のテーブル定義

### 重要なパラメータ
- **SerDe**: RegexSerDeを使用してログの解析を行う
- **Input Format**: TextInputFormat
- **Storage Location**: S3アクセスログが格納されているパス
- **Regex Pattern**: ログエントリを正しく解析するための正規表現

## 3. S3アクセスログに対応するパーティション設定

S3アクセスログのパーティション設定には2つの主要な方式があります：

### Date-based Partitioning（推奨）
AWS S3は現在、以下の形式での日付ベースパーティション設定をサポートしています：
```
[DestinationPrefix][SourceAccountId]/[SourceRegion]/[SourceBucket]/[YYYY]/[MM]/[DD]/[YYYY]-[MM]-[DD]-[hh]-[mm]-[ss]-[UniqueString]
```

### パーティション利点
- クエリパフォーマンスの大幅改善
- スキャン対象データの削減によるコスト削減
- 時間範囲を指定したクエリの高速化

## 4. 最小構成でのGlue Catalog Table定義

以下が実際にS3アクセスログをクエリできる最小構成のTerraform定義です：

### データベース定義
```hcl
resource "aws_glue_catalog_database" "s3_access_logs_db" {
  name        = "s3_access_logs_db"
  description = "Database for S3 access logs analysis"
}
```

### 最小構成テーブル定義
```hcl
resource "aws_glue_catalog_table" "s3_access_logs" {
  name          = "s3_access_logs"
  database_name = aws_glue_catalog_database.s3_access_logs_db.name
  table_type    = "EXTERNAL_TABLE"
  
  parameters = {
    EXTERNAL                = "TRUE"
    "projection.enabled"    = "true"
    "projection.timestamp.type" = "date"
    "projection.timestamp.range" = "2020/01/01,NOW"
    "projection.timestamp.format" = "yyyy/MM/dd"
    "projection.timestamp.interval" = "1"
    "projection.timestamp.interval.unit" = "DAYS"
    "storage.location.template" = "s3://${var.access_logs_bucket}/access-logs/${timestamp}/"
  }
  
  storage_descriptor {
    location      = "s3://${var.access_logs_bucket}/access-logs/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    
    ser_de_info {
      name                  = "s3-access-logs-regex"
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
      
      parameters = {
        "input.regex" = "([^ ]*) ([^ ]*) \\[(.*?)\\] ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) (\"[^\"]*\" < /dev/null | \\-) (\\-|[0-9]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) (\"[^\"]*\"|\\-) ([^ ]*)(?: ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*))?.*$"
      }
    }
    
    # 主要カラムのみ（分析に必要な最小限）
    columns {
      name = "bucketowner"
      type = "string"
    }
    
    columns {
      name = "bucket_name"
      type = "string"
    }
    
    columns {
      name = "requestdatetime"
      type = "string"
    }
    
    columns {
      name = "remoteip"
      type = "string"
    }
    
    columns {
      name = "requester"
      type = "string"
    }
    
    columns {
      name = "requestid"
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
      name = "httpstatus"
      type = "string"
    }
    
    columns {
      name = "errorcode"
      type = "string"
    }
    
    columns {
      name = "bytessent"
      type = "bigint"
    }
    
    columns {
      name = "objectsize"
      type = "bigint"
    }
    
    columns {
      name = "totaltime"
      type = "string"
    }
    
    columns {
      name = "turnaroundtime"
      type = "string"
    }
    
    columns {
      name = "referrer"
      type = "string"
    }
    
    columns {
      name = "useragent"
      type = "string"
    }
    
    columns {
      name = "versionid"
      type = "string"
    }
    
    columns {
      name = "hostid"
      type = "string"
    }
    
    columns {
      name = "sigv"
      type = "string"
    }
    
    columns {
      name = "ciphersuite"
      type = "string"
    }
    
    columns {
      name = "authtype"
      type = "string"
    }
    
    columns {
      name = "endpoint"
      type = "string"
    }
    
    columns {
      name = "tlsversion"
      type = "string"
    }
    
    columns {
      name = "accesspointarn"
      type = "string"
    }
    
    columns {
      name = "aclrequired"
      type = "string"
    }
  }
  
  # パーティション設定（Partition Projectionを使用）
  partition_keys {
    name = "timestamp"
    type = "string"
  }
}
```

### 変数定義
```hcl
variable "access_logs_bucket" {
  description = "S3 bucket name where access logs are stored"
  type        = string
}
```

## 更にシンプルな構成（基本クエリ用）

基本的な分析のみを行う場合の最小限の構成：

```hcl
resource "aws_glue_catalog_table" "s3_access_logs_simple" {
  name          = "s3_access_logs_simple"
  database_name = aws_glue_catalog_database.s3_access_logs_db.name
  table_type    = "EXTERNAL_TABLE"
  
  parameters = {
    EXTERNAL = "TRUE"
  }
  
  storage_descriptor {
    location      = "s3://${var.access_logs_bucket}/access-logs/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
      
      parameters = {
        "input.regex" = "([^ ]*) ([^ ]*) \\[(.*?)\\] ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) (\"[^\"]*\"|\\-) (\\-|[0-9]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) (\"[^\"]*\"|\\-) ([^ ]*).*$"
      }
    }
    
    # 基本的な分析に必要な主要カラムのみ
    columns {
      name = "bucketowner"
      type = "string"
    }
    
    columns {
      name = "bucket_name"
      type = "string"
    }
    
    columns {
      name = "requestdatetime"
      type = "string"
    }
    
    columns {
      name = "remoteip"
      type = "string"
    }
    
    columns {
      name = "requester"
      type = "string"
    }
    
    columns {
      name = "requestid"
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
      name = "httpstatus"
      type = "string"
    }
    
    columns {
      name = "errorcode"
      type = "string"
    }
    
    columns {
      name = "bytessent"
      type = "bigint"
    }
    
    columns {
      name = "objectsize"
      type = "bigint"
    }
    
    columns {
      name = "totaltime"
      type = "string"
    }
    
    columns {
      name = "turnaroundtime"
      type = "string"
    }
    
    columns {
      name = "referrer"
      type = "string"
    }
    
    columns {
      name = "useragent"
      type = "string"
    }
  }
}
```

## 使用例のサンプルクエリ

テーブル作成後、以下のようなクエリが実行可能になります：

```sql
-- 特定ユーザーの操作履歴を確認
SELECT requestdatetime, operation, key, httpstatus 
FROM s3_access_logs_db.s3_access_logs 
WHERE requester = 'arn:aws:iam::123456789012:user/username'
ORDER BY requestdatetime DESC
LIMIT 100;

-- エラーが発生したリクエストを確認
SELECT requestdatetime, remoteip, operation, key, httpstatus, errorcode
FROM s3_access_logs_db.s3_access_logs 
WHERE httpstatus \!= '200' AND errorcode \!= '-'
ORDER BY requestdatetime DESC;

-- 最もアクセスされているオブジェクトのトップ10
SELECT key, COUNT(*) as access_count, SUM(bytessent) as total_bytes
FROM s3_access_logs_db.s3_access_logs 
WHERE operation = 'REST.GET.OBJECT'
GROUP BY key
ORDER BY access_count DESC
LIMIT 10;
```

## 重要な注意点

1. **RegEx SerDe**: S3アクセスログの解析には正規表現SerDe（RegexSerDe）が必須です
2. **Partition Projection**: 大量のログを効率的にクエリするためにはPartition Projectionの使用を推奨します
3. **ログ形式の変更**: S3アクセスログ形式は時々更新されるため、新しいフィールドが追加される可能性があります
4. **パフォーマンス**: パーティション設定により、クエリのパフォーマンスとコストを大幅に改善できます

この構成により、S3アクセスログをAthenaで効率的にクエリできるようになります。

