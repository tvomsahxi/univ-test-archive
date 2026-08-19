import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// iOS / Android / デスクトップ向け。ドキュメントディレクトリ配下の
/// exports フォルダへ書き出し、保存先パスを返す。
Future<String> saveJsonFile(String json, String fileName) async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/univ_test_archive/exports');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(json, flush: true);
  return '保存しました: ${file.path}';
}
