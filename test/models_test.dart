import 'package:flutter_test/flutter_test.dart';
import 'package:univ_test_archive/models/quiz_models.dart';
import 'package:univ_test_archive/screens/data_screen.dart';

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

  group('書き出しファイル名', () {
    test('日付が 0 埋めされた questions-YYYYMMDD.json になる', () {
      expect(
        DataScreen.fileNameFor(DateTime(2026, 9, 5)),
        'questions-20260905.json',
      );
      expect(
        DataScreen.fileNameFor(DateTime(2026, 12, 31)),
        'questions-20261231.json',
      );
    });
  });

  group('解答履歴', () {
    Question q() => Question(
      id: 'q-1',
      topicId: 't-1',
      subTopicId: null,
      text: '問題',
      choices: const [
        Choice(text: 'A', isCorrect: true),
        Choice(text: 'B', isCorrect: false),
        Choice(text: 'C', isCorrect: false),
        Choice(text: 'D', isCorrect: false),
      ],
    );

    test('履歴が無いときは直近の解答も正答率も null', () {
      final question = q();
      expect(question.lastAnswer, isNull);
      expect(question.lastAnsweredAt, isNull);
      expect(question.lastIsCorrect, isNull);
      expect(question.answeredCount, 0);
      expect(question.accuracy, isNull);
    });

    test('withAnswer は解答日と正誤を積み、集計に反映される', () {
      final t1 = DateTime(2026, 9, 20, 10);
      final t2 = DateTime(2026, 9, 21, 11);
      final question = q()
          .withAnswer(AnswerRecord(answeredAt: t1, isCorrect: false))
          .withAnswer(AnswerRecord(answeredAt: t2, isCorrect: true));

      expect(question.answeredCount, 2);
      expect(question.correctAnswerCount, 1);
      expect(question.accuracy, 0.5);
      expect(question.lastAnsweredAt, t2);
      expect(question.lastIsCorrect, isTrue);
    });

    test('withAnswer は問題の更新日時を変えない', () {
      final question = q();
      final before = question.updatedAt;
      final after = question.withAnswer(
        AnswerRecord(answeredAt: DateTime(2026, 9, 21), isCorrect: true),
      );
      expect(after.updatedAt, before);
    });

    test('履歴は上限を超えると古いものから捨てられる', () {
      var question = q();
      for (var i = 0; i < Question.maxAnswerHistory + 5; i++) {
        question = question.withAnswer(
          AnswerRecord(
            answeredAt: DateTime(2026, 1, 1).add(Duration(days: i)),
            isCorrect: true,
          ),
        );
      }
      expect(question.answeredCount, Question.maxAnswerHistory);
      // 残っているのは新しい側。
      expect(
        question.lastAnsweredAt,
        DateTime(2026, 1, 1).add(Duration(days: Question.maxAnswerHistory + 4)),
      );
      expect(
        question.answers.first.answeredAt,
        DateTime(2026, 1, 1).add(const Duration(days: 5)),
      );
    });

    test('JSON に往復しても履歴が保たれる', () {
      final question = q().withAnswer(
        AnswerRecord(answeredAt: DateTime(2026, 9, 21, 9, 30), isCorrect: true),
      );
      final restored = Question.fromJson(question.toJson());
      expect(restored.answeredCount, 1);
      expect(restored.lastAnsweredAt, DateTime(2026, 9, 21, 9, 30));
      expect(restored.lastIsCorrect, isTrue);
    });

    test('version 1 の JSON（answers 無し）も履歴なしとして読める', () {
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
        'explanation': '解説',
      };
      final restored = Question.fromJson(json);
      expect(restored.answers, isEmpty);
      expect(restored.lastAnswer, isNull);
    });

    test('日付が壊れた履歴は読み飛ばす', () {
      final json = {
        'id': 'q-1',
        'topicId': 't-1',
        'subTopicId': null,
        'text': '問題',
        'choices': const [],
        'answers': [
          {'answeredAt': 'これは日付ではない', 'isCorrect': true},
          {'answeredAt': '2026-09-21T09:30:00.000', 'isCorrect': false},
        ],
      };
      final restored = Question.fromJson(json);
      expect(restored.answeredCount, 1);
      expect(restored.lastIsCorrect, isFalse);
    });
  });
}
