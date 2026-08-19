import 'dart:math';

final Random _idRandom = Random();
int _idCounter = 0;

/// ID 生成。外部パッケージに依存せず、実用上十分な一意性を確保する。
///
/// 乱数の上限には 2^30 を 16 進リテラルで指定している。`1 << 32` のような
/// シフト式は Web(dart2js)では JavaScript の 32bit シフト仕様で 0 になり、
/// `nextInt` が RangeError を投げるため使わないこと。
String generateId(String prefix) {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rand = _idRandom.nextInt(0x40000000).toRadixString(36);
  final seq = (_idCounter++).toRadixString(36);
  return '$prefix-$now-$rand$seq';
}

/// 4択のうちの1つ。
class Choice {
  const Choice({required this.text, required this.isCorrect});

  final String text;
  final bool isCorrect;

  Choice copyWith({String? text, bool? isCorrect}) =>
      Choice(text: text ?? this.text, isCorrect: isCorrect ?? this.isCorrect);

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
        text: (json['text'] ?? '') as String,
        isCorrect: json['isCorrect'] == true,
      );

  Map<String, dynamic> toJson() => {'text': text, 'isCorrect': isCorrect};
}

/// サブ題材（例: 第3回 授業）。
class SubTopic {
  const SubTopic({required this.id, required this.name});

  final String id;
  final String name;

  SubTopic copyWith({String? name}) =>
      SubTopic(id: id, name: name ?? this.name);

  factory SubTopic.fromJson(Map<String, dynamic> json) => SubTopic(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// 題材（例: 情報科学概論）。サブ題材を子に持つ2階層構造。
class Topic {
  const Topic({required this.id, required this.name, this.subTopics = const []});

  final String id;
  final String name;
  final List<SubTopic> subTopics;

  SubTopic? subTopicById(String? id) {
    if (id == null) return null;
    for (final sub in subTopics) {
      if (sub.id == id) return sub;
    }
    return null;
  }

  Topic copyWith({String? name, List<SubTopic>? subTopics}) => Topic(
        id: id,
        name: name ?? this.name,
        subTopics: subTopics ?? this.subTopics,
      );

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        subTopics: ((json['subTopics'] as List<dynamic>?) ?? const [])
            .map((e) => SubTopic.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subTopics': subTopics.map((e) => e.toJson()).toList(),
      };
}

/// 1問分のデータ。画像は Base64 で JSON に同梱する（画像の利用は稀な想定）。
class Question {
  Question({
    required this.id,
    required this.topicId,
    required this.subTopicId,
    required this.text,
    required this.choices,
    this.imageBase64,
    this.explanation = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String topicId;
  final String? subTopicId;
  final String text;
  final String? imageBase64;
  final List<Choice> choices;
  final String explanation;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 正解の選択肢の添字。
  Set<int> get correctIndexes => {
        for (var i = 0; i < choices.length; i++)
          if (choices[i].isCorrect) i,
      };

  bool isCorrectAnswer(Set<int> selected) {
    final correct = correctIndexes;
    return selected.length == correct.length && selected.containsAll(correct);
  }

  Question copyWith({
    String? topicId,
    String? subTopicId,
    bool clearSubTopic = false,
    String? text,
    String? imageBase64,
    bool clearImage = false,
    List<Choice>? choices,
    String? explanation,
    DateTime? updatedAt,
  }) =>
      Question(
        id: id,
        topicId: topicId ?? this.topicId,
        subTopicId: clearSubTopic ? null : (subTopicId ?? this.subTopicId),
        text: text ?? this.text,
        imageBase64: clearImage ? null : (imageBase64 ?? this.imageBase64),
        choices: choices ?? this.choices,
        explanation: explanation ?? this.explanation,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        topicId: json['topicId'] as String,
        subTopicId: json['subTopicId'] as String?,
        text: (json['text'] ?? '') as String,
        imageBase64: json['imageBase64'] as String?,
        choices: ((json['choices'] as List<dynamic>?) ?? const [])
            .map((e) => Choice.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        // 旧形式の 'answerType' は無視する（常に複数選択として扱う）。
        explanation: (json['explanation'] ?? '') as String,
        createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String),
        updatedAt: DateTime.tryParse((json['updatedAt'] ?? '') as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'topicId': topicId,
        'subTopicId': subTopicId,
        'text': text,
        'imageBase64': imageBase64,
        'choices': choices.map((e) => e.toJson()).toList(),
        'explanation': explanation,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// JSON ファイルに保存される全データ。
class QuizData {
  const QuizData({required this.topics, required this.questions});

  const QuizData.empty()
      : topics = const [],
        questions = const [];

  static const int schemaVersion = 1;

  final List<Topic> topics;
  final List<Question> questions;

  factory QuizData.fromJson(Map<String, dynamic> json) => QuizData(
        topics: ((json['topics'] as List<dynamic>?) ?? const [])
            .map((e) => Topic.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        questions: ((json['questions'] as List<dynamic>?) ?? const [])
            .map((e) => Question.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'version': schemaVersion,
        'topics': topics.map((e) => e.toJson()).toList(),
        'questions': questions.map((e) => e.toJson()).toList(),
      };
}
