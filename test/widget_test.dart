import 'package:flutter_test/flutter_test.dart';
import 'package:univ_test_archive/data/quiz_repository.dart';
import 'package:univ_test_archive/main.dart';

import 'quiz_repository_test.dart' show MemoryStorage;

void main() {
  testWidgets('ホーム画面が表示され、題材が一覧に出る', (tester) async {
    final repo = QuizRepository(MemoryStorage());
    await repo.load();
    await repo.addTopic('情報科学概論');

    await tester.pumpWidget(QuizApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('問題集アーカイブ'), findsOneWidget);
    expect(find.text('情報科学概論'), findsOneWidget);
    expect(find.text('問題を作成'), findsOneWidget);
    expect(find.text('題材を追加'), findsOneWidget);
  });
}
