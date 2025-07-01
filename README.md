# Claude Code Log Management System

Claude Codeセッションで一元化された会話ログ管理システムです。

## ディレクトリ構造

```
claude-code-log/
├── CLAUDE.md           # プロジェクト設定
├── README.md           # このファイル
├── save-chat.sh        # 会話保存スクリプト
├── list-chats.sh       # 会話一覧表示
├── search-chats.sh     # 会話検索
├── 20241216/           # 日付ベースディレクトリ
│   ├── chat-title-1.md
│   ├── chat-title-2.md
│   └── ...
└── ...
```

## 基本的な使い方

### 1. 会話の保存
```bash
./save-chat.sh "新しいプロジェクトの相談"
```

### 2. 会話ログの一覧表示
```bash
# 今日の会話一覧
./list-chats.sh

# 特定日の会話一覧
./list-chats.sh 20241215
```

### 3. 会話ログの検索
```bash
./search-chats.sh "Python"
```

## 特徴

- **日本語対応**: ファイル名に日本語を使用可能
- **日付ベース整理**: YYYYMMDD形式でディレクトリ自動作成
- **検索機能**: キーワードでの横断検索
- **Claude Code統合**: CLAUDE.mdベースでClaude Codeと連携

## Claude Code統合

このシステムはClaude CodeのCLAUDE.md機能と連携しています：

1. プロジェクトディレクトリに移動
2. Claude Codeを起動
3. 会話終了時に `./save-chat.sh` でログ保存

## ログフォーマット

各会話ログは以下の形式で保存されます：

```markdown
# [Chat Title]

**Date**: YYYY-MM-DD HH:MM:SS
**Duration**: [conversation length]
**Topics**: [auto-extracted topics]

---

## Conversation

[conversation content]
```

## 今後の拡張予定

- [ ] 会話内容の自動取得
- [ ] トピック自動抽出
- [ ] 会話時間の自動計算
- [ ] Webインターフェース
- [ ] 検索結果のハイライト表示


claude mcp add awslabs.aws-documentation-mcp-server -s user uvx awslabs.aws-documentation-mcp-server@latest
