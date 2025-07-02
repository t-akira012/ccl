```
  resource "aws_glue_catalog_table" "s3_access_logs" {
    # Athenaでクエリ時に使用するテーブル名
    name          = "s3_access_logs"
    # 所属するGlueデータベース（別リソースで定義）
    database_name = aws_glue_catalog_database.s3_access_logs_db.name
    # 外部テーブル - S3上のデータを直接参照（データコピー不要）
    table_type    = "EXTERNAL_TABLE"

    # Partition Projection設定 - 大量の日次パーティションを自動認識
    # AWS Documentation: https://docs.aws.amazon.com/athena/latest/ug/partition-projection.html
    parameters = {
      # 外部データソースであることを明示（Glueクローラー等で必要）
      EXTERNAL                = "TRUE"
      # Partition Projectionを有効化（手動パーティション追加が不要になる）
      "projection.enabled"    = "true"
      # パーティションの型を日付型として定義
      "projection.timestamp.type" = "date"
      # 2020年1月1日から現在まで（過去ログ分析とリアルタイム分析の両立）
      "projection.timestamp.range" = "2020/01/01,NOW"
      # S3のフォルダ構造に合わせた日付形式
      "projection.timestamp.format" = "yyyy/MM/dd"
      # 1日単位でパーティション分割
      "projection.timestamp.interval" = "1"
      "projection.timestamp.interval.unit" = "DAYS"
      # 動的にS3パスを生成（${timestamp}は実行時に日付に置換）
      "storage.location.template" = "s3://${var.access_logs_bucket}/access-logs/${timestamp}/"
    }

    # ストレージ記述子 - データの物理的な格納形式を定義
    storage_descriptor {
      # S3上のログファイル格納場所
      location      = "s3://${var.access_logs_bucket}/access-logs/"
      # S3アクセスログはプレーンテキスト形式
      input_format  = "org.apache.hadoop.mapred.TextInputFormat"
      # Athenaでの出力形式（通常使用しないが定義必須）
      output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

      # SerDe（Serializer/Deserializer）設定 - S3アクセスログ形式の解析定義
      # AWS Documentation: https://docs.aws.amazon.com/athena/latest/ug/serde-about.html
      ser_de_info {
        # SerDe識別名（任意だが分かりやすい名前を設定）
        name                  = "s3-access-logs-regex"
        # 正規表現ベースのSerDe（S3ログ形式は固定フォーマット）
        serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"

        parameters = {
          # S3アクセスログの標準形式を解析する正規表現
          # AWS S3 Access Log Format: https://docs.aws.amazon.com/AmazonS3/latest/userguide/LogFormat.html
          # 各キャプチャグループが後述のカラムに対応
          "input.regex" = "([^ ]*) ([^ ]*) \\[(.*?)\\] ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) (\"[^\"]*\" < /dev/null | \\-) (\\-|[0-9]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^
  ]*) (\"[^\"]*\"|\\-) ([^ ]*)(?: ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*))?.*$"
        }
      }

      # カラム定義 - 正規表現の各キャプチャグループと対応
      # セキュリティ監査とパフォーマンス分析に必要な主要フィールドのみ定義

      # バケット所有者のCanonical User ID（権限分析用）
      columns {
        name = "bucketowner"
        type = "string"
      }

      # アクセスされたS3バケット名（対象バケット特定用）
      columns {
        name = "bucket_name"
        type = "string"
      }

      # リクエスト発生時刻 [DD/MMM/YYYY:HH:MM:SS +TTTT]形式（時系列分析用）
      columns {
        name = "requestdatetime"
        type = "string"
      }

      # リクエスト元IPアドレス（不正アクセス検知の最重要項目）
      columns {
        name = "remoteip"
        type = "string"
      }

      # リクエスト実行者のCanonical User ID（誰がアクセスしたか）
      columns {
        name = "requester"
        type = "string"
      }

      # 一意のリクエスト識別子（問題調査時のトレース用）
      columns {
        name = "requestid"
        type = "string"
      }

      # S3操作タイプ REST.GET.OBJECT, REST.PUT.OBJECT等（操作監査用）
      columns {
        name = "operation"
        type = "string"
      }

      # アクセスされたオブジェクトキー（何にアクセスしたか）
      columns {
        name = "key"
        type = "string"
      }

      # HTTPリクエストURI（詳細なリクエスト内容）
      columns {
        name = "request_uri"
        type = "string"
      }

      # HTTPステータスコード 200=成功, 403=権限エラー等（エラー監視用）
      columns {
        name = "httpstatus"
        type = "string"
      }

      # S3エラーコード NoSuchKey, AccessDenied等（詳細エラー分析用）
      columns {
        name = "errorcode"
        type = "string"
      }

      # 送信バイト数（データ転送コスト計算用） - bigint型で数値計算可能
      columns {
        name = "bytessent"
        type = "bigint"
      }

      # オブジェクトサイズ（ストレージ使用量分析用） - bigint型で集計可能
      columns {
        name = "objectsize"
        type = "bigint"
      }

      # 総処理時間ミリ秒（パフォーマンス監視用）
      columns {
        name = "totaltime"
        type = "string"
      }

      # ターンアラウンド時間（S3処理性能分析用）
      columns {
        name = "turnaroundtime"
        type = "string"
      }

      # HTTPリファラー（アクセス経路・連携システム分析用）
      columns {
        name = "referrer"
        type = "string"
      }

      # ユーザーエージェント（クライアントアプリケーション識別用）
      columns {
        name = "useragent"
        type = "string"
      }

      # オブジェクトバージョンID（バージョニング有効時の版管理）
      columns {
        name = "versionid"
        type = "string"
      }

      # ホストID（S3内部識別子、AWS問い合わせ時に使用）
      columns {
        name = "hostid"
        type = "string"
      }

      # 署名バージョン SigV2/SigV4（認証方式の監査用）
      columns {
        name = "sigv"
        type = "string"
      }

      # TLS暗号化スイート（セキュリティ監査・脆弱性検査用）
      columns {
        name = "ciphersuite"
        type = "string"
      }

      # 認証タイプ AuthHeader等（認証方式の詳細）
      columns {
        name = "authtype"
        type = "string"
      }

      # S3エンドポイント s3.amazonaws.com等（リージョン特定用）
      columns {
        name = "endpoint"
        type = "string"
      }

      # TLSバージョン TLSv1.2等（セキュリティ監査用）
      columns {
        name = "tlsversion"
        type = "string"
      }

      # Access Point ARN（S3 Access Point経由のアクセス識別用）
      columns {
        name = "accesspointarn"
        type = "string"
      }

      # ACL要求フラグ（アクセス制御リスト使用の有無）
      columns {
        name = "aclrequired"
        type = "string"
      }
    }

    # パーティション設定 - 日付ベースでデータを分割
    # 大量ログの効率的クエリのため日付でパーティション分割
    # Partition Projectionと連携して自動的にパーティション認識
    partition_keys {
      name = "timestamp"    # yyyy/MM/dd形式の日付文字列
      type = "string"       # 文字列型として定義
    }
  }
```
