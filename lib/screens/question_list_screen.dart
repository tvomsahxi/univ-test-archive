import 'package:flutter/material.dart';

import '../main.dart';
import '../models/quiz_models.dart';
import '../widgets/pickers.dart';
import 'question_editor_screen.dart';

/// 題材 / サブ題材内の問題一覧。編集・削除ができる。
class QuestionListScreen extends StatelessWidget {
  const QuestionListScreen({
    super.key,
    required this.topicId,
    this.subTopicId,
    this.onlyUncategorized = false,
    required this.title,
  });

  final String topicId;
  final String? subTopicId;
  final bool onlyUncategorized;
  final String title;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final topic = repo.topicById(topicId);
    final questions = repo.questionsIn(
      topicId,
      subTopicId: subTopicId,
      onlyUncategorized: onlyUncategorized,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: questions.isEmpty
          ? const Center(child: Text('問題がありません'))
          : ListView.separated(
              itemCount: questions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final q = questions[index];
                final sub = topic?.subTopicById(q.subTopicId);
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(
                    q.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text([
                    q.answerType.label,
                    if (sub != null) sub.name,
                    if (q.imageBase64 != null) '画像あり',
                  ].join(' / ')),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          QuestionEditorScreen(questionId: q.id),
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: '削除',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await confirmDelete(
                          context, 'この問題を削除しますか？\n「${_preview(q)}」');
                      if (ok) await repo.deleteQuestion(q.id);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestionEditorScreen(
              initialTopicId: topicId,
              initialSubTopicId: subTopicId,
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('ここに問題を追加'),
      ),
    );
  }

  String _preview(Question q) =>
      q.text.length <= 30 ? q.text : '${q.text.substring(0, 30)}…';
}
