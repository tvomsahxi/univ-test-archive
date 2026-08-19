import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:univ_test_archive/data/quiz_repository.dart';
import 'package:univ_test_archive/main.dart';

import 'quiz_repository_test.dart' show MemoryStorage;

void main() {
  testWidgets('「題材を追加」で入力した題材が一覧に反映される', (tester) async {
    final repo = QuizRepository(MemoryStorage());
    await repo.load();

    await tester.pumpWidget(QuizApp(repository: repo));
    await tester.pumpAndSettle();

    // FAB をタップしてダイアログを開く
    await tester.tap(find.text('題材を追加'));
    await tester.pumpAndSettle();

    // 名前を入力して OK
    await tester.enterText(find.byType(TextField), '情報科学概論');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // リポジトリに入っているか
    expect(repo.topics.map((t) => t.name), ['情報科学概論']);
    // 画面に出ているか
    expect(find.text('情報科学概論'), findsOneWidget);
  });
}
