import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'storage_base.dart';

QuizStorage createStorage() => FileQuizStorage();

/// iOS / Android / デスクトップ向け。JSON ファイルとして実ファイルに保存する。
class FileQuizStorage implements QuizStorage {
  static const String fileName = 'questions.json';
  static const String dirName = 'univ_test_archive';

  File? _cachedFile;

  Future<File> _file() async {
    final cached = _cachedFile;
    if (cached != null) return cached;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _cachedFile = File('${dir.path}/$fileName');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final contents = await file.readAsString();
    return contents.trim().isEmpty ? null : contents;
  }

  @override
  Future<void> write(String json) async {
    final file = await _file();
    // 書き込み途中でアプリが落ちてもファイルが壊れないよう、一時ファイル経由で置き換える。
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(file.path);
  }

  @override
  Future<String> describeLocation() async => (await _file()).path;
}
