import 'package:flutter_test/flutter_test.dart';
import 'package:univ_test_archive/data/quiz_repository.dart';
import 'package:univ_test_archive/data/storage_base.dart';
import 'package:univ_test_archive/models/quiz_models.dart';

/// テスト用のインメモリ保存先。
class MemoryStorage implements QuizStorage {
  String? saved;

  @override
  Future<String?> read() async => saved;

  @override
  Future<void> write(String json) async => saved = json;

  @override
  Future<String> describeLocation() async => 'memory';
}

Question buildQuestion({
  required String topicId,
  String? subTopicId,
  Set<int> correct = const {0},
}) {
  return Question(
    id: generateId('q'),
    topicId: topicId,
    subTopicId: subTopicId,
    text: 'テスト問題',
    choices: [
      for (var i = 0; i < 4; i++)
        Choice(text: '選択肢$i', isCorrect: correct.contains(i)),
    ],
    explanation: '解説',
  );
}

void main() {
  group('正誤判定', () {
    test('正解が1つの問題: その選択肢だけ選べば正解', () {
      final q = buildQuestion(topicId: 't1', correct: {2});
      expect(q.isCorrectAnswer({2}), isTrue);
      expect(q.isCorrectAnswer({0}), isFalse);
      expect(q.isCorrectAnswer({0, 2}), isFalse);
    });

    test('正解が複数の問題: 過不足なく選んだ場合のみ正解', () {
      final q = buildQuestion(topicId: 't1', correct: {1, 3});
      expect(q.isCorrectAnswer({1, 3}), isTrue);
      expect(q.isCorrectAnswer({1}), isFalse);
      expect(q.isCorrectAnswer({1, 2, 3}), isFalse);
    });
  });

  group('JSON 保存と読み込み', () {
    test('保存したデータを次回起動時に読み込める', () async {
      final storage = MemoryStorage();
      final repo = QuizRepository(storage);
      await repo.load();

      final topic = await repo.addTopic('情報科学概論');
      final sub = await repo.addSubTopic(topic.id, '第1回');
      await repo.addQuestion(buildQuestion(
        topicId: topic.id,
        subTopicId: sub.id,
        correct: {0, 2},
      ));

      // 「次回起動」を再現: 同じ保存先から新しいリポジトリで読み込む。
      final repo2 = QuizRepository(storage);
      await repo2.load();

      expect(repo2.topics, hasLength(1));
      expect(repo2.topics.first.name, '情報科学概論');
      expect(repo2.topics.first.subTopics.first.name, '第1回');
      expect(repo2.questions, hasLength(1));
      final q = repo2.questions.first;
      expect(q.correctIndexes, {0, 2});
      expect(q.explanation, '解説');
    });

    test('壊れた JSON でも空データで起動できる', () async {
      final storage = MemoryStorage()..saved = '{ broken json';
      final repo = QuizRepository(storage);
      await repo.load();
      expect(repo.topics, isEmpty);
      expect(repo.questions, isEmpty);
      expect(repo.errorMessage, isNotNull);
    });
  });

  group('題材とサブ題材', () {
    test('題材の削除は配下の問題も削除する', () async {
      final repo = QuizRepository(MemoryStorage());
      await repo.load();
      final t1 = await repo.addTopic('数学');
      final t2 = await repo.addTopic('物理');
      await repo.addQuestion(buildQuestion(topicId: t1.id));
      await repo.addQuestion(buildQuestion(topicId: t2.id));

      await repo.deleteTopic(t1.id);
      expect(repo.topics.map((t) => t.name), ['物理']);
      expect(repo.questions, hasLength(1));
      expect(repo.questions.first.topicId, t2.id);
    });

    test('サブ題材削除時に問題を未分類として残せる', () async {
      final repo = QuizRepository(MemoryStorage());
      await repo.load();
      final t = await repo.addTopic('数学');
      final s = await repo.addSubTopic(t.id, '第1回');
      await repo.addQuestion(
          buildQuestion(topicId: t.id, subTopicId: s.id));

      await repo.deleteSubTopic(t.id, s.id, deleteQuestions: false);
      expect(repo.topicById(t.id)!.subTopics, isEmpty);
      expect(repo.questions, hasLength(1));
      expect(repo.questions.first.subTopicId, isNull);
      expect(repo.countIn(t.id, onlyUncategorized: true), 1);
    });

    test('サブ題材削除時に問題ごと削除できる', () async {
      final repo = QuizRepository(MemoryStorage());
      await repo.load();
      final t = await repo.addTopic('数学');
      final s = await repo.addSubTopic(t.id, '第1回');
      await repo.addQuestion(
          buildQuestion(topicId: t.id, subTopicId: s.id));
      await repo.addQuestion(buildQuestion(topicId: t.id));

      await repo.deleteSubTopic(t.id, s.id, deleteQuestions: true);
      expect(repo.questions, hasLength(1));
      expect(repo.questions.first.subTopicId, isNull);
    });

    test('サブ題材での絞り込み', () async {
      final repo = QuizRepository(MemoryStorage());
      await repo.load();
      final t = await repo.addTopic('数学');
      final s1 = await repo.addSubTopic(t.id, '第1回');
      final s2 = await repo.addSubTopic(t.id, '第2回');
      await repo
          .addQuestion(buildQuestion(topicId: t.id, subTopicId: s1.id));
      await repo
          .addQuestion(buildQuestion(topicId: t.id, subTopicId: s1.id));
      await repo
          .addQuestion(buildQuestion(topicId: t.id, subTopicId: s2.id));

      expect(repo.countIn(t.id), 3);
      expect(repo.countIn(t.id, subTopicId: s1.id), 2);
      expect(repo.countIn(t.id, subTopicId: s2.id), 1);
    });
  });

  group('出題セットの作成', () {
    test('上限なしなら全問、上限ありなら指定数だけ返す', () async {
      final repo = QuizRepository(MemoryStorage());
      await repo.load();
      final t = await repo.addTopic('数学');
      for (var i = 0; i < 5; i++) {
        await repo.addQuestion(buildQuestion(topicId: t.id));
      }

      expect(repo.buildQuizSet(t.id), hasLength(5));
      expect(repo.buildQuizSet(t.id, limit: 3), hasLength(3));
      // 上限がプールより大きい場合は全問。
      expect(repo.buildQuizSet(t.id, limit: 10), hasLength(5));
      // 0 以下の上限は「制限なし」扱い。
      expect(repo.buildQuizSet(t.id, limit: 0), hasLength(5));
    });

    test('上限付きでも重複なくプール内の問題だけが選ばれる', () async {
      final repo = QuizRepository(MemoryStorage());
      await repo.load();
      final t = await repo.addTopic('数学');
      for (var i = 0; i < 6; i++) {
        await repo.addQuestion(buildQuestion(topicId: t.id));
      }
      final poolIds = repo.questionsIn(t.id).map((q) => q.id).toSet();

      final set = repo.buildQuizSet(t.id, limit: 4);
      final ids = set.map((q) => q.id).toSet();
      expect(ids, hasLength(4));
      expect(poolIds.containsAll(ids), isTrue);
    });

    test('サブ題材を指定するとその中からだけ選ばれる', () async {
      final repo = QuizRepository(MemoryStorage());
      await repo.load();
      final t = await repo.addTopic('数学');
      final s = await repo.addSubTopic(t.id, '第1回');
      await repo
          .addQuestion(buildQuestion(topicId: t.id, subTopicId: s.id));
      await repo.addQuestion(buildQuestion(topicId: t.id));

      final set = repo.buildQuizSet(t.id, subTopicId: s.id);
      expect(set, hasLength(1));
      expect(set.single.subTopicId, s.id);
    });
  });

  group('書き出しと読み込み', () {
    test('exportJson を importJson で復元できる', () async {
      final repo = QuizRepository(MemoryStorage());
      await repo.load();
      final t = await repo.addTopic('英語');
      await repo.addQuestion(buildQuestion(topicId: t.id));
      final exported = repo.exportJson();

      final repo2 = QuizRepository(MemoryStorage());
      await repo2.load();
      await repo2.importJson(exported);
      expect(repo2.topics.first.name, '英語');
      expect(repo2.questions, hasLength(1));
    });

    test('不正な JSON の importJson は例外を投げ、データは変わらない', () async {
      final repo = QuizRepository(MemoryStorage());
      await repo.load();
      await repo.addTopic('英語');
      await expectLater(repo.importJson('not json'), throwsA(anything));
      expect(repo.topics, hasLength(1));
    });
  });
}
