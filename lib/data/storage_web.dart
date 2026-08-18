import 'package:web/web.dart' as web;

import 'storage_base.dart';

QuizStorage createStorage() => WebQuizStorage();

/// Web 向け。ブラウザにファイルシステムが無いため localStorage に JSON を保存する。
/// 保存されるのはファイルと同じ形式の JSON なので、「データ管理」画面から
/// 書き出して questions.json として保存・共有できる。
class WebQuizStorage implements QuizStorage {
  static const String storageKey = 'univ_test_archive.questions.v1';

  @override
  Future<String?> read() async {
    final value = web.window.localStorage.getItem(storageKey);
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  @override
  Future<void> write(String json) async {
    web.window.localStorage.setItem(storageKey, json);
  }

  @override
  Future<String> describeLocation() async =>
      'ブラウザの localStorage（キー: $storageKey）';
}
