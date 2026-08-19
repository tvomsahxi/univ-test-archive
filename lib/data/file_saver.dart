import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.js_interop) 'file_saver_web.dart' as impl;

/// JSON をファイルとして保存する。
/// Web ではブラウザのダウンロード、それ以外では exports フォルダへの書き出しになる。
/// 戻り値は結果を伝えるメッセージ。
Future<String> saveJsonFile(String json, String fileName) =>
    impl.saveJsonFile(json, fileName);
