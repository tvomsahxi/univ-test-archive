import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/pickers.dart';
import 'question_list_screen.dart';
import 'quiz_screen.dart';

/// 題材の詳細。サブ題材の一覧・出題開始・問題一覧への入口。
class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final topic = repo.topicById(topicId);
    if (topic == null) {
      // 別画面で削除された場合はホームへ戻す。
      return const Scaffold(body: SizedBox.shrink());
    }
    final totalCount = repo.countIn(topicId);
    final uncategorizedCount =
        repo.countIn(topicId, onlyUncategorized: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(topic.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              switch (value) {
                case 'rename':
                  final name = await showNameInputDialog(context,
                      title: '題材名を変更', initialValue: topic.name);
                  if (name != null) await repo.renameTopic(topicId, name);
                case 'delete':
                  final ok = await confirmDelete(context,
                      '題材「${topic.name}」を削除しますか？\n配下のサブ題材と $totalCount 問もすべて削除されます。');
                  if (ok) {
                    await repo.deleteTopic(topicId);
                    navigator.pop();
                    messenger.showSnackBar(
                        SnackBar(content: Text('「${topic.name}」を削除しました')));
                  }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('題材名を変更')),
              PopupMenuItem(value: 'delete', child: Text('題材を削除')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: totalCount == 0
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            topicId: topicId,
                            title: topic.name,
                          ),
                        ),
                      ),
              icon: const Icon(Icons.play_arrow),
              label: Text('この題材全体から出題（$totalCount 問）'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('題材内の問題一覧'),
            subtitle: Text('$totalCount 問'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuestionListScreen(
                  topicId: topicId,
                  title: '${topic.name} の問題',
                ),
              ),
            ),
          ),
          if (uncategorizedCount > 0)
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('サブ題材なしの問題'),
              subtitle: Text('$uncategorizedCount 問'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuestionListScreen(
                    topicId: topicId,
                    onlyUncategorized: true,
                    title: '${topic.name} / サブ題材なし',
                  ),
                ),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('サブ題材',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (topic.subTopics.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('まだサブ題材がありません（例: 第1回、第2回 …）'),
            ),
          for (final sub in topic.subTopics)
            _SubTopicTile(topicId: topicId, subTopicId: sub.id),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await showNameInputDialog(context,
              title: '新しいサブ題材', hint: '例: 第3回');
          if (name != null) await repo.addSubTopic(topicId, name);
        },
        icon: const Icon(Icons.add),
        label: const Text('サブ題材を追加'),
      ),
    );
  }
}

class _SubTopicTile extends StatelessWidget {
  const _SubTopicTile({required this.topicId, required this.subTopicId});

  final String topicId;
  final String subTopicId;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final topic = repo.topicById(topicId);
    final sub = topic?.subTopicById(subTopicId);
    if (topic == null || sub == null) return const SizedBox.shrink();
    final count = repo.countIn(topicId, subTopicId: subTopicId);

    return ListTile(
      leading: const Icon(Icons.topic_outlined),
      title: Text(sub.name),
      subtitle: Text('$count 問'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionListScreen(
            topicId: topicId,
            subTopicId: subTopicId,
            title: '${topic.name} / ${sub.name}',
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'このサブ題材から出題',
            icon: const Icon(Icons.play_arrow),
            onPressed: count == 0
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          topicId: topicId,
                          subTopicId: subTopicId,
                          title: '${topic.name} / ${sub.name}',
                        ),
                      ),
                    ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'rename':
                  final name = await showNameInputDialog(context,
                      title: 'サブ題材名を変更', initialValue: sub.name);
                  if (name != null) {
                    await repo.renameSubTopic(topicId, subTopicId, name);
                  }
                case 'delete':
                  await _deleteSubTopic(context, repo, sub.name, count);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('名前を変更')),
              PopupMenuItem(value: 'delete', child: Text('削除')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubTopic(BuildContext context, dynamic repo,
      String name, int count) async {
    if (count == 0) {
      final ok = await confirmDelete(context, 'サブ題材「$name」を削除しますか？');
      if (ok) {
        await repo.deleteSubTopic(topicId, subTopicId,
            deleteQuestions: false);
      }
      return;
    }
    // 問題が残っている場合は、問題ごと消すか題材直下へ移すか選ばせる。
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('「$name」の削除'),
        content: Text('このサブ題材には $count 問あります。問題をどうしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('keep'),
            child: const Text('問題は残す'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop('delete'),
            child: const Text('問題ごと削除'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    await repo.deleteSubTopic(topicId, subTopicId,
        deleteQuestions: choice == 'delete');
  }
}
