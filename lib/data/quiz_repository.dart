import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/quiz_models.dart';
import 'storage.dart';

/// 問題・題材の一覧を保持し、変更のたびに JSON へ保存するリポジトリ。
class QuizRepository extends ChangeNotifier {
  QuizRepository(this._storage);

  final QuizStorage _storage;

  List<Topic> _topics = [];
  List<Question> _questions = [];
  bool _loading = true;
  String? _errorMessage;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  List<Topic> get topics => List.unmodifiable(_topics);
  List<Question> get questions => List.unmodifiable(_questions);

  /// 起動時に JSON ファイルから読み込む。
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final raw = await _storage.read();
      if (raw != null) {
        final data = QuizData.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        _topics = [...data.topics];
        _questions = [...data.questions];
      }
      _errorMessage = null;
    } catch (e) {
      // 壊れた JSON でアプリが起動できなくならないよう、空データで続行する。
      _errorMessage = '保存データの読み込みに失敗しました: $e';
      _topics = [];
      _questions = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> storageLocation() => _storage.describeLocation();

  QuizData get data => QuizData(topics: _topics, questions: _questions);

  String exportJson() => const JsonEncoder.withIndent('  ').convert(data.toJson());

  Future<void> _persist() async {
    try {
      await _storage.write(jsonEncode(data.toJson()));
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '保存に失敗しました: $e';
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- 題材

  Topic? topicById(String? id) {
    if (id == null) return null;
    for (final topic in _topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  Future<Topic> addTopic(String name) async {
    final topic = Topic(id: generateId('t'), name: name.trim());
    _topics = [..._topics, topic];
    await _persist();
    return topic;
  }

  Future<void> renameTopic(String topicId, String name) async {
    _topics = [
      for (final topic in _topics)
        topic.id == topicId ? topic.copyWith(name: name.trim()) : topic,
    ];
    await _persist();
  }

  /// 題材を削除する。配下のサブ題材と問題もまとめて削除される。
  Future<void> deleteTopic(String topicId) async {
    _topics = _topics.where((topic) => topic.id != topicId).toList();
    _questions = _questions.where((q) => q.topicId != topicId).toList();
    await _persist();
  }

  // ------------------------------------------------------------ サブ題材

  Future<SubTopic> addSubTopic(String topicId, String name) async {
    final sub = SubTopic(id: generateId('s'), name: name.trim());
    _topics = [
      for (final topic in _topics)
        topic.id == topicId
            ? topic.copyWith(subTopics: [...topic.subTopics, sub])
            : topic,
    ];
    await _persist();
    return sub;
  }

  Future<void> renameSubTopic(
      String topicId, String subTopicId, String name) async {
    _topics = [
      for (final topic in _topics)
        if (topic.id != topicId)
          topic
        else
          topic.copyWith(subTopics: [
            for (final sub in topic.subTopics)
              sub.id == subTopicId ? sub.copyWith(name: name.trim()) : sub,
          ]),
    ];
    await _persist();
  }

  /// サブ題材を削除する。
  /// [deleteQuestions] が false のときは、配下の問題を題材直下（未分類）へ移す。
  Future<void> deleteSubTopic(
    String topicId,
    String subTopicId, {
    required bool deleteQuestions,
  }) async {
    _topics = [
      for (final topic in _topics)
        if (topic.id != topicId)
          topic
        else
          topic.copyWith(
            subTopics:
                topic.subTopics.where((sub) => sub.id != subTopicId).toList(),
          ),
    ];
    if (deleteQuestions) {
      _questions = _questions
          .where((q) => !(q.topicId == topicId && q.subTopicId == subTopicId))
          .toList();
    } else {
      _questions = [
        for (final q in _questions)
          if (q.topicId == topicId && q.subTopicId == subTopicId)
            q.copyWith(clearSubTopic: true)
          else
            q,
      ];
    }
    await _persist();
  }

  // ---------------------------------------------------------------- 問題

  Question? questionById(String id) {
    for (final q in _questions) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// 題材（サブ題材を指定した場合はその中）に属する問題。
  /// [subTopicId] に null を渡し [onlyUncategorized] を true にすると、
  /// サブ題材が未設定の問題だけを返す。
  List<Question> questionsIn(
    String topicId, {
    String? subTopicId,
    bool onlyUncategorized = false,
  }) {
    return _questions.where((q) {
      if (q.topicId != topicId) return false;
      if (subTopicId != null) return q.subTopicId == subTopicId;
      if (onlyUncategorized) return q.subTopicId == null;
      return true;
    }).toList();
  }

  int countIn(String topicId, {String? subTopicId, bool onlyUncategorized = false}) =>
      questionsIn(topicId,
              subTopicId: subTopicId, onlyUncategorized: onlyUncategorized)
          .length;

  Future<void> addQuestion(Question question) async {
    _questions = [..._questions, question];
    await _persist();
  }

  Future<void> updateQuestion(Question question) async {
    _questions = [
      for (final q in _questions) q.id == question.id ? question : q,
    ];
    await _persist();
  }

  Future<void> deleteQuestion(String id) async {
    _questions = _questions.where((q) => q.id != id).toList();
    await _persist();
  }

  // ------------------------------------------------------- インポート

  /// 書き出した JSON を読み込んで、現在のデータを置き換える。
  Future<void> importJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('JSON の形式が正しくありません');
    }
    final data = QuizData.fromJson(Map<String, dynamic>.from(decoded));
    _topics = [...data.topics];
    _questions = [...data.questions];
    await _persist();
  }
}
