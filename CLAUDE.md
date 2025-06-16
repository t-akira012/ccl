# Claude Code Log Management

## 会話ログ管理システム

### 基本動作
- 全ての会話を日本語で行う
- 全ての回答をArtifacts形式で構造化して出力
- 各レスポンスで会話ログファイルを自動更新
- ユーザーが「保存して」と言わなくても自動でログ保存を実行
- ログは日付ベースのディレクトリに整理する

### 出力形式
- 常にMarkdown形式でファイルに出力
- 質問と回答を構造化して記録
- タイムスタンプ付きで逐次更新
- 会話内容から自動的にタイトルを生成
- 主要トピックを分析してファイル名を決定

### ディレクトリ構造
```
claude-code-log/
├── yyyymmdd/
│   ├── chat-title-1.md
│   ├── chat-title-2.md
│   └── ...
└── CLAUDE.md
```

### ログ保存ルール
1. 会話タイトルはユーザーが指定、未指定の場合は会話内容から自動生成
2. ファイル名は安全な文字列に変換（日本語OK、スペースはハイフンに）
3. 各ログにはタイムスタンプとメタデータを含める

### カスタムコマンド
- `save-chat [title]`: 現在の会話をログに保存
- `list-chats [date]`: 指定日（または今日）の会話一覧を表示
- `search-chats [keyword]`: 会話ログから検索

### ログフォーマット
```markdown
# [Chat Title]

**Date**: YYYY-MM-DD HH:MM:SS
**Duration**: [conversation length]
**Topics**: [auto-extracted topics]

---

## Conversation

[conversation content]
```

### 実装方針
- CLAUDE.mdベースでClaude Codeに機能を統合
- bashコマンドとMarkdown形式でシンプルに実装
- 検索性を重視したメタデータ付与

