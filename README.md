# 問題集アーカイブ（univ_test_archive)

大学のオンライン授業などで出された問題を、教科（題材）× 授業回（サブ題材）で整理して保存し、いつでも復習できる 4択問題集アプリです。Flutter 製で iOS / Android / Web で動作します。

## 機能

- **問題の新規作成**: 問題文（テキスト＋任意で画像）、4つの選択肢、正解の丸付け、解説を登録
  - 解答形式は「1つ選択」と「複数選択」に対応
- **題材によるカテゴライズ**: 題材（例: 教科）→ サブ題材(例: 第1回〜) の2階層
  - 問題作成時に「既存の題材から選ぶ（モーダル）」か「新しい題材を作る」かを選択可能
- **出題**:
  - 題材を選んで開始 → 題材内の全問題からランダム出題（開始時に出題数の上限を指定可能）
  - サブ題材を選んで開始 → そのサブ題材の問題のみランダム出題
  - 回答すると正解 / 不正解と解説を表示、最後に正解数と正答率を表示
  - 複数選択問題は「過不足なくすべて選んだときだけ正解」（部分点なし）
- **問題一覧**: 題材 / サブ題材ごとに問題を確認し、タップで編集、ゴミ箱アイコンで削除
- **保存**: すべての変更は即座に JSON として保存され、次回起動時に読み込まれます

## データの保存先

| プラットフォーム | 保存先 |
|---|---|
| iOS / Android / デスクトップ | アプリのドキュメントディレクトリ内 `univ_test_archive/questions.json` |
| Web | ブラウザの `localStorage`（ファイルシステムが無いため） |

どちらも同じ JSON 形式なので、「データ管理」画面（ホーム右上のアイコン）から JSON を書き出し / 読み込みして、端末間でデータを移行できます。書き出しは2通りあります:

- **ファイルとして保存**: Web ではブラウザのダウンロードとして `questions.json` が保存され、モバイルでは `exports/questions.json` に書き出されます
- **クリップボードへコピー**: JSON テキストをそのまま貼り付けて移行したいとき用

画像は Base64 として JSON に埋め込まれます（画像の利用が少ない前提の設計です）。

## 開発

```bash
flutter pub get
flutter test          # ユニット / ウィジェットテスト
flutter analyze
flutter run -d chrome # Web で起動
flutter run           # 接続中の iOS / Android 端末で起動
flutter build web     # Web 用ビルド（build/web に出力）
```

## JSON スキーマ（version 1）

```json
{
  "version": 1,
  "topics": [
    {
      "id": "t-...",
      "name": "情報科学概論",
      "subTopics": [{ "id": "s-...", "name": "第1回" }]
    }
  ],
  "questions": [
    {
      "id": "q-...",
      "topicId": "t-...",
      "subTopicId": "s-...",
      "text": "問題文",
      "imageBase64": null,
      "choices": [
        { "text": "選択肢1", "isCorrect": true },
        { "text": "選択肢2", "isCorrect": false },
        { "text": "選択肢3", "isCorrect": false },
        { "text": "選択肢4", "isCorrect": false }
      ],
      "answerType": "single",
      "explanation": "解説",
      "createdAt": "...",
      "updatedAt": "..."
    }
  ]
}
```
