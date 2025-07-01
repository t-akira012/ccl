# AWS-CloudTrail-ログ取得方法

**User**:
AWS cloudtrailで、アカウント111111111の全てのユーザーログイン記録と、S3バケット `hoge_bucket` を閲覧した記録を全て取り出す方法を教えなさい. aws mcpを使え。

**Claude**:
AWS CloudTrailで指定された情報を取得するには、以下の方法を使用します：

## 1. ユーザーログイン記録の取得

アカウント111111111の全てのユーザーログイン記録を取得するには：

```bash
# ConsoleLoginイベントを検索（過去90日間）
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin \
    --region us-east-1 \
    --output json
```

## 2. S3バケット `hoge_bucket` へのアクセス記録の取得

### 前提条件：データイベントのロギング設定

S3オブジェクトレベルのアクセスログを取得するには、事前にCloudTrailでデータイベントのロギングを有効にしている必要があります。

### データイベント有効化の確認・設定

```bash
# 既存のトレイルでデータイベントを有効化
aws cloudtrail put-event-selectors \
    --trail-name your-trail-name \
    --advanced-event-selectors '[
        {
            "Name": "Log S3 data events for hoge_bucket",
            "FieldSelectors": [
                {
                    "Field": "resources.type",
                    "Equals": ["AWS::S3::Object"]
                },
                {
                    "Field": "resources.ARN",
                    "StartsWith": ["arn:aws:s3:::hoge_bucket/"]
                }
            ]
        }
    ]'
```

### S3アクセスログの検索

```bash
# S3バケットへのアクセスイベントを検索
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=ResourceName,AttributeValue=arn:aws:s3:::hoge_bucket \
    --region your-region \
    --output json
```

## 3. 特定アカウントでのフィルタリング

アカウント111111111に限定してイベントを取得する場合、結果をjqでフィルタリング：

```bash
# ログインイベント（アカウント111111111のみ）
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin \
    --region us-east-1 \
    --output json  < /dev/null |  jq '.Events[] | select(.userIdentity.accountId=="111111111")'

# S3アクセスイベント（アカウント111111111のみ）
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=ResourceName,AttributeValue=arn:aws:s3:::hoge_bucket \
    --region your-region \
    --output json | jq '.Events[] | select(.recipientAccountId=="111111111")'
```

## 4. CloudTrail Lake（長期保存・高度な検索）

90日以上前のデータや、より高度な検索が必要な場合は、CloudTrail Lakeを使用：

```sql
-- CloudTrail Lakeでのクエリ例
-- ログインイベント
SELECT eventTime, userIdentity.userName, sourceIPAddress, responseElements
FROM event_data_store_id
WHERE eventName = 'ConsoleLogin'
  AND recipientAccountId = '111111111'
  AND eventTime > '2024-01-01'

-- S3アクセスイベント
SELECT eventTime, userIdentity.userName, eventName, requestParameters
FROM event_data_store_id
WHERE resources.ARN LIKE 'arn:aws:s3:::hoge_bucket%'
  AND recipientAccountId = '111111111'
  AND eventTime > '2024-01-01'
```

## 注意事項

1. **データイベントの有効化**: S3オブジェクトレベルのアクセスログは、事前にデータイベントのロギングを有効にしていないと記録されません
2. **コスト**: データイベントのロギングには追加料金が発生します
3. **リージョン**: ConsoleLoginイベントは通常us-east-1に記録されます
4. **保存期間**: lookup-eventsは過去90日間のイベントのみ検索可能です

**User**:
OK. まずはテストしたいので、マネジメントコンソール上での操作を教えなさい

**Claude**:
AWS Management ConsoleでCloudTrailを使用してログを確認する手順を説明します：

## 1. ユーザーログイン記録の確認

### ステップ1: CloudTrailコンソールへアクセス
1. AWS Management Consoleにログイン
2. サービス検索で「CloudTrail」を検索し、選択

### ステップ2: イベント履歴の確認
1. 左側メニューから「**イベント履歴**」をクリック
2. フィルター設定：
   - 「**イベント名**」を選択
   - 値に「**ConsoleLogin**」を入力
   - 期間を選択（最大90日前まで）

### ステップ3: 結果の確認
- ログインイベントの一覧が表示されます
- 各イベントをクリックすると詳細情報（ユーザー名、IPアドレス、MFA使用有無など）が確認できます

## 2. S3バケット「hoge_bucket」へのアクセス記録の確認

### 前提: データイベントの有効化

#### ステップ1: トレイルの作成または編集
1. CloudTrailコンソールで「**トレイル**」を選択
2. 既存のトレイルを選択して「**編集**」、または「**トレイルの作成**」

#### ステップ2: データイベントの設定
1. 「**データイベント**」セクションまでスクロール
2. 「**S3**」を選択
3. 「**個別のバケットまたはオブジェクトを選択**」を選択
4. 「**バケットを参照**」をクリック
5. 「**hoge_bucket**」を選択
6. イベントタイプ：
   - 「**読み取り**」にチェック（GetObject等）
   - 「**書き込み**」にチェック（PutObject等）
7. 「**変更を保存**」

### データイベントの確認

#### ステップ1: イベント履歴でフィルター
1. 「**イベント履歴**」に戻る
2. フィルター設定：
   - 「**リソース名**」を選択
   - 値に「**hoge_bucket**」を入力
   - または完全なARN：「**arn:aws:s3:::hoge_bucket**」

#### ステップ2: 詳細フィルター（オプション）
- 「**読み取り専用**」でイベントタイプを絞り込み：
  - 「**true**」: 読み取り操作（GetObject等）
  - 「**false**」: 書き込み操作（PutObject等）

## 3. アカウント111111111に限定した検索

### フィルターの組み合わせ
1. イベント履歴で複数のフィルターを設定：
   - **イベント名**: ConsoleLogin（ログイン用）
   - **ユーザー名**: 特定のユーザー名
   - **期間**: カスタム期間を設定

### 結果のダウンロード
1. フィルター結果の右上にある「**イベントをダウンロード**」
2. CSV形式でダウンロード可能
3. ExcelやGoogle SheetsでアカウントIDでフィルタリング

## 4. CloudTrail Insights（高度な分析）

### Insightsの有効化
1. トレイルの編集画面で「**CloudTrail Insights**」を有効化
2. 異常なAPIコール量やエラー率を自動検出

## 注意事項

- **データイベントの課金**: S3データイベントのロギングは追加料金が発生
- **遅延**: イベントが表示されるまで5-15分程度かかる場合があります
- **90日制限**: イベント履歴は過去90日間のみ。それ以前のデータはS3に保存されたログファイルを確認

## テスト推奨手順

1. まず小規模なテスト用S3バケットでデータイベントを有効化
2. テストファイルをアップロード/ダウンロード
3. 15分後にイベント履歴で確認
4. 正常に記録されることを確認後、本番環境に適用

