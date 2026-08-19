import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web 向け。JSON をブラウザのダウンロードとして保存させる。
Future<String> saveJsonFile(String json, String fileName) async {
  final blob = web.Blob(
    [json.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return '$fileName をダウンロードしました';
}
