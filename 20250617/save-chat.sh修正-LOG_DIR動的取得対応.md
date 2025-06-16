# save-chat.sh修正-LOG_DIR動的取得対応

**User**:
LOG_DIRがハードコーディングされている。修正せよ

**Claude**:
save-chat.shのLOG_DIRをハードコーディングから動的に取得する方式に修正しました。

変更内容：
- LOG_DIR=\/Users/t-akira012/tmp/claude-code-log\ 
- ↓
- LOG_DIR=\\\

これにより、スクリプトが配置されているディレクトリを自動的に取得し、どのユーザー環境でも動作するようになります。
