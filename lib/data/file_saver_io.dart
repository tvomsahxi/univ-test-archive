import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// iOS / Android / デスクトップ向け。
///
/// アプリ内部のフォルダに置くだけではユーザーから見えないため、
/// 一時ファイルに書き出したうえで OS の共有シートを開く。
/// 共有シートからは「ファイルに保存」で本体へ、
/// 「Google ドライブ」でクラウドへ、といった保存先を選べる。
Future<String> saveJsonFile(String json, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(json, flush: true);

  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      fileNameOverrides: [fileName],
      subject: '問題集アーカイブ $fileName',
    ),
  );

  return switch (result.status) {
    ShareResultStatus.success => '$fileName を保存しました',
    ShareResultStatus.dismissed => '保存をキャンセルしました',
    ShareResultStatus.unavailable => '保存先を開けませんでした',
  };
}
