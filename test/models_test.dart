import 'package:flutter_test/flutter_test.dart';
import 'package:univ_test_archive/models/quiz_models.dart';

void main() {
  group('generateId', () {
    // Web(dart2js)では `1 << 32` が 0 になり nextInt が RangeError を投げるため、
    // この検証は `flutter test --platform chrome` でこそ意味がある。
    test('例外を投げず、prefix 付きの ID を返す', () {
      final id = generateId('t');
      expect(id, startsWith('t-'));
      expect(id.length, greaterThan(5));
    });

    test('連続生成しても重複しない', () {
      final ids = {for (var i = 0; i < 500; i++) generateId('q')};
      expect(ids, hasLength(500));
    });
  });

  group('Question の JSON 往復', () {
    test('保存して読み直しても内容が保たれる', () {
      final q = Question(
        id: 'q-1',
        topicId: 't-1',
        subTopicId: 's-1',
        text: '問題文',
        choices: const [
          Choice(text: 'A', isCorrect: true),
          Choice(text: 'B', isCorrect: false),
          Choice(text: 'C', isCorrect: true),
          Choice(text: 'D', isCorrect: false),
        ],
        explanation: '解説',
      );
      final restored = Question.fromJson(q.toJson());
      expect(restored.text, '問題文');
      expect(restored.correctIndexes, {0, 2});
      expect(restored.explanation, '解説');
      expect(restored.subTopicId, 's-1');
    });

    test('旧形式の answerType が入っていても読み込める', () {
      final json = {
        'id': 'q-1',
        'topicId': 't-1',
        'subTopicId': null,
        'text': '旧形式の問題',
        'choices': [
          {'text': 'A', 'isCorrect': true},
          {'text': 'B', 'isCorrect': false},
          {'text': 'C', 'isCorrect': false},
          {'text': 'D', 'isCorrect': false},
        ],
        'answerType': 'single',
        'explanation': '解説',
      };
      final q = Question.fromJson(json);
      expect(q.text, '旧形式の問題');
      expect(q.correctIndexes, {0});
    });
  });
}
