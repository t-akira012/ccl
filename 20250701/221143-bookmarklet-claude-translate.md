# bookmarklet-claude-translate

**User**:
firefoxのbookmarkletで、開いているページをClaude Webに飛ばして、翻訳させるのを作って

**Claude**:
Firefoxのブックマークレットを作成します。現在のページをClaude Webに送って翻訳依頼するコードです。

```javascript
javascript:(function(){
  const url = encodeURIComponent(window.location.href);
  const title = encodeURIComponent(document.title);
  const selectedText = window.getSelection().toString();
  
  let prompt = `以下のWebページを日本語に翻訳してください：\n\nURL: ${decodeURIComponent(url)}\nタイトル: ${decodeURIComponent(title)}`;
  
  if (selectedText) {
    prompt += `\n\n選択されたテキスト:\n${selectedText}`;
  } else {
    // ページの主要なテキストコンテンツを取得
    const content = document.body.innerText.substring(0, 3000) + (document.body.innerText.length > 3000 ? '...' : '');
    prompt += `\n\nページ内容:\n${content}`;
  }
  
  const claudeUrl = 'https://claude.ai/chat?' + new URLSearchParams({
    q: prompt
  }).toString();
  
  window.open(claudeUrl, '_blank');
})();
```

## 使用方法

1. Firefoxのブックマークツールバーを右クリック
2. 「新しいブックマーク」を選択
3. 名前: `Claude翻訳`
4. URL: 上記のJavaScriptコード全体をコピー&ペースト
5. 保存

## 機能

- 現在のページURLとタイトルを取得
- テキストが選択されている場合は選択部分のみ
- 選択がない場合はページ全体の内容（最初の3000文字）
- Claude Webの新しいタブで翻訳プロンプト付きで開く

ブックマークレットをクリックすると、現在のページ情報と共にClaude Webが開き、翻訳を依頼できます。

**User**:
動かないな

**Claude**:
申し訳ありません。Claude.aiへの直接的なプロンプト送信は現在サポートされていないようです。代わりに、以下の方法を提案します：

## 方法1: ページ内容をクリップボードにコピー

```javascript
javascript:(function(){
  const url = window.location.href;
  const title = document.title;
  const selectedText = window.getSelection().toString();
  
  let content = `以下のWebページを日本語に翻訳してください：\n\nURL: ${url}\nタイトル: ${title}\n\n`;
  
  if (selectedText) {
    content += `選択されたテキスト:\n${selectedText}`;
  } else {
    const bodyText = document.body.innerText.substring(0, 3000);
    content += `ページ内容:\n${bodyText}${bodyText.length >= 3000 ? '...' : ''}`;
  }
  
  navigator.clipboard.writeText(content).then(() => {
    alert('翻訳依頼文をコピーしました。Claude.aiに貼り付けてください。');
    window.open('https://claude.ai/new', '_blank');
  }).catch(err => {
    alert('コピーに失敗しました: ' + err);
  });
})();
```

## 方法2: シンプルなURL共有

```javascript
javascript:(function(){
  const url = encodeURIComponent(window.location.href);
  const prompt = encodeURIComponent(`このページを日本語に翻訳してください: ${decodeURIComponent(url)}`);
  navigator.clipboard.writeText(decodeURIComponent(prompt)).then(() => {
    window.open('https://claude.ai/new', '_blank');
  });
})();
```

どちらも、内容をクリップボードにコピーしてからClaude.aiを開くので、手動で貼り付ける必要があります。

javascript:(function(){const e=document.createElement('textarea');e.value=document.title+"\n"+location.href;document.querySelector('body').append(e);e.select();document.execCommand('copy');e.remove();})();


javascript:(function(){ const url = encodeURIComponent(window.location.href); const prompt = encodeURIComponent(`このページを日本語に翻訳してください: ${decodeURIComponent(url)}`); navigator.clipboard.writeText(decodeURIComponent(prompt)).then(() => { window.open('https://claude.ai/new', ); }); })();
**User**:
デバッグしようか。単にgoogleに移動するbookmarkletにして

**Claude**:
シンプルにGoogleに移動するだけのブックマークレットを作ります。

```javascript
javascript:(function(){window.open('https://www.google.com','_blank');})();
```

または、現在のタブで移動する場合：

```javascript
javascript:(function(){window.location.href='https://www.google.com';})();
```

さらにシンプルに：

```javascript
javascript:window.open('https://www.google.com');
```

これらのどれかをブックマークのURL欄に入れてください。動作確認後、Claude.ai向けの機能を追加していきましょう。

**User**:
javascript:(function(){window.location.href='https://www.google.com';})();

これはOKだね。じゃあ、Claudeに飛ばそう

**Claude**:
では、Claude.aiに飛ばすように変更します。

```javascript
javascript:(function(){window.location.href='https://claude.ai/new';})();
```

これでClaude.aiの新規チャット画面に移動します。次は、ページ情報をクリップボードにコピーしてから移動する機能を追加してみましょうか？

**User**:
OK.じゃあ、クリップボードにコピーして貼り付けようか

**Claude**:
クリップボードにページ情報をコピーしてからClaude.aiに移動するブックマークレットです。

```javascript
javascript:(function(){
  const url = window.location.href;
  const title = document.title;
  const text = `このページを日本語に翻訳してください:\n\nURL: ${url}\nタイトル: ${title}`;
  
  navigator.clipboard.writeText(text).then(() => {
    alert('翻訳依頼をコピーしました。Claudeに貼り付けてください。');
    window.location.href = 'https://claude.ai/new';
  }).catch(() => {
    // 古いブラウザ用のフォールバック
    const textarea = document.createElement('textarea');
    textarea.value = text;
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
    alert('翻訳依頼をコピーしました。Claudeに貼り付けてください。');
    window.location.href = 'https://claude.ai/new';
  });
})();
```

これで：
1. 現在のページのURLとタイトルを含む翻訳依頼文をクリップボードにコピー
2. アラートで確認
3. Claude.aiの新規チャット画面に移動

Claude.aiで貼り付け（Ctrl+V）するだけで翻訳依頼ができます。

**User**:
ここで壊れたね。君は余計なコード、フォールバックとかYAGNIを破ったね。

**Claude**:
その通りです。シンプルに戻しましょう。

```javascript
javascript:(function(){
  const text = `このページを日本語に翻訳してください:\n\nURL: ${window.location.href}\nタイトル: ${document.title}`;
  navigator.clipboard.writeText(text).then(() => {
    window.location.href = 'https://claude.ai/new';
  });
})();
```

余計なものを削除：
- alert不要
- フォールバック不要
- 変数も最小限に

これで動作するはずです。

**User**:
Yagniを破ることは許さないよ。

**Claude**:
はい、理解しました。YAGNIの原則を守ります。

必要最小限のコードのみ。要求されていない機能は一切追加しません。

**User**:
クリップボードに追加するときに、選択した文字列も含めなさい

**Claude**:
```javascript
javascript:(function(){
  const s = window.getSelection().toString();
  const text = `このページを日本語に翻訳してください:\n\nURL: ${window.location.href}\nタイトル: ${document.title}${s ? '\n\n選択テキスト:\n' + s : ''}`;
  navigator.clipboard.writeText(text).then(() => {
    window.location.href = 'https://claude.ai/new';
  });
})();
```

