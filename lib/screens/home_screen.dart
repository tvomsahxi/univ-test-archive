import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/prairie_theme.dart';
import '../widgets/pickers.dart';
import '../widgets/prairie.dart';
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
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DataScreen())),
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
              const ArtGlassBanner(),
              Expanded(
                child: repo.topics.isEmpty
                    ? const _EmptyHome()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 160),
                        itemCount: repo.topics.length,
                        itemBuilder: (context, index) {
                          final topic = repo.topics[index];
                          final count = repo.countIn(topic.id);
                          // 行ごとに差し色を替え、色ガラスの並びを思わせる律動を作る。
                          final accent = index.isEven
                              ? PrairieColors.ochre
                              : PrairieColors.moss;
                          return PrairieTile(
                            accent: accent,
                            child: ListTile(
                              leading: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(color: accent, width: 2),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(topic.name),
                              subtitle: Text(
                                '$count 問 ／ サブ題材 ${topic.subTopics.length} 件',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TopicScreen(topicId: topic.id),
                                ),
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
            backgroundColor: PrairieColors.ink,
            onPressed: () async {
              final name = await showNameInputDialog(
                context,
                title: '新しい題材',
                hint: '例: 情報科学概論',
              );
              if (name != null) await repo.addTopic(name);
            },
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('題材を追加'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'add-question',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuestionEditorScreen()),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 交差する直線だけで構成した記号。
            SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(painter: _CrossingLinesMark()),
            ),
            const SizedBox(height: 28),
            Text(
              'まだ題材がありません。\n「題材を追加」で教科を作るか、\n「問題を作成」から始めてください。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// 直交する線が層をなす、プレーリー様式の平面図のような記号。
class _CrossingLinesMark extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 6;
    final thin = Paint()
      ..color = PrairieColors.stone
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final bold = Paint()
      ..color = PrairieColors.ink.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // 水平線を主、垂直線を従として、張り出した軒のように長さを変える。
    canvas.drawLine(Offset(0, u * 2), Offset(size.width, u * 2), bold);
    canvas.drawLine(Offset(u, u * 4), Offset(size.width - u, u * 4), thin);
    canvas.drawLine(Offset(u * 2, 0), Offset(u * 2, size.height - u), thin);
    canvas.drawLine(Offset(u * 4, u), Offset(u * 4, size.height), thin);

    canvas.drawRect(
      Rect.fromCenter(center: Offset(u * 2, u * 2), width: u, height: u),
      Paint()..color = PrairieColors.cherokee,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(u * 4, u * 4),
        width: u * 0.7,
        height: u * 0.7,
      ),
      Paint()..color = PrairieColors.ochre,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
