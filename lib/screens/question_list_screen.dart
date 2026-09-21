import 'package:flutter/material.dart';

import '../main.dart';
import '../models/quiz_models.dart';
import '../theme/prairie_theme.dart';
import '../widgets/pickers.dart';
import '../widgets/prairie.dart';
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
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final sub = topic?.subTopicById(q.subTopicId);
                return PrairieTile(
                  accent: index.isEven
                      ? PrairieColors.ochre
                      : PrairieColors.moss,
                  child: ListTile(
                    // 通し番号は円ではなく方形で囲み、直線構成を保つ。
                    leading: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: PrairieColors.stone,
                          width: 1.5,
                        ),
                      ),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      q.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        '正解 ${q.correctIndexes.length} 個',
                        if (sub != null) sub.name,
                        if (q.imageBase64 != null) '画像あり',
                      ].join(' / '),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuestionEditorScreen(questionId: q.id),
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: '削除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await confirmDelete(
                          context,
                          'この問題を削除しますか？\n「${_preview(q)}」',
                        );
                        if (ok) await repo.deleteQuestion(q.id);
                      },
                    ),
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
