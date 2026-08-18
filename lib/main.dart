import 'package:flutter/material.dart';

import 'data/quiz_repository.dart';
import 'data/storage.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = QuizRepository(createStorage());
  repository.load();
  runApp(QuizApp(repository: repository));
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key, required this.repository});

  final QuizRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      repository: repository,
      child: MaterialApp(
        title: '問題集アーカイブ',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

/// 画面ツリーのどこからでもリポジトリへアクセスするための InheritedNotifier。
/// リポジトリが notifyListeners すると依存ウィジェットが再構築される。
class RepositoryScope extends InheritedNotifier<QuizRepository> {
  const RepositoryScope({
    super.key,
    required QuizRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static QuizRepository of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'RepositoryScope が見つかりません');
    return scope!.notifier!;
  }
}
