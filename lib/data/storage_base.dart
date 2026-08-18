/// プラットフォームごとの保存先を抽象化する。
///
/// - モバイル / デスクトップ: アプリのドキュメントディレクトリ内の JSON ファイル
/// - Web: ブラウザの localStorage（ファイルシステムが無いため）
abstract class QuizStorage {
  /// 保存済みの JSON 文字列。未保存なら null。
  Future<String?> read();

  /// JSON 文字列を保存する。
  Future<void> write(String json);

  /// 画面に表示する保存先の説明（例: ファイルパス）。
  Future<String> describeLocation();
}
