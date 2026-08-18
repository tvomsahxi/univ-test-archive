import 'storage_base.dart';
import 'storage_stub.dart'
    if (dart.library.io) 'storage_io.dart'
    if (dart.library.js_interop) 'storage_web.dart' as impl;

export 'storage_base.dart';

/// 実行中のプラットフォームに合わせた保存先を返す。
QuizStorage createStorage() => impl.createStorage();
