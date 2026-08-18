import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/pickers.dart';
import 'data_screen.dart';
import 'question_editor_screen.dart';
import 'topic_screen.dart';

/// 題材の一覧（ホーム画面）。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('問題集アーカイブ'),
        actions: [
          IconButton(
            tooltip: 'データ管理',
            icon: const Icon(Icons.save_alt),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DataScreen()),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (repo.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              if (repo.errorMessage != null)
                MaterialBanner(
                  content: Text(repo.errorMessage!),
                  leading: const Icon(Icons.warning_amber),
                  actions: const [SizedBox.shrink()],
                ),
              Expanded(
                child: repo.topics.isEmpty
                    ? const _EmptyHome()
                    : ListView.builder(
                        itemCount: repo.topics.length,
                        itemBuilder: (context, index) {
                          final topic = repo.topics[index];
                          final count = repo.countIn(topic.id);
                          return ListTile(
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(topic.name),
                            subtitle: Text(
                                '$count 問 / サブ題材 ${topic.subTopics.length} 件'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TopicScreen(topicId: topic.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add-topic',
            onPressed: () async {
              final name = await showNameInputDialog(context,
                  title: '新しい題材', hint: '例: 情報科学概論');
              if (name != null) await repo.addTopic(name);
            },
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('題材を追加'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add-question',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const QuestionEditorScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('問題を作成'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'まだ題材がありません。\n「題材を追加」で教科を作るか、\n「問題を作成」から始めてください。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
