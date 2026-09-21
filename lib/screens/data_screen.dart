import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/file_saver.dart';
import '../main.dart';
import '../theme/prairie_theme.dart';
import '../widgets/prairie.dart';

/// データ管理画面。保存先の確認、JSON の書き出し / 読み込みができる。
///
/// モバイル / デスクトップでは JSON ファイルに常時自動保存されるが、
/// Web は localStorage 保存のため、この画面からの書き出しがバックアップ手段になる。
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  /// バックアップを取るたびに上書きしないよう、日付を入れたファイル名にする。
  static String fileNameFor(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'questions-$y$m$d.json';
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final questionCount = repo.questions.length;
    final topicCount = repo.topics.length;

    return Scaffold(
      appBar: AppBar(title: const Text('データ管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------ 書き出し（主操作）
          PrairieCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  kIsWeb ? 'JSON をダウンロード' : 'JSON を保存',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '題材 $topicCount 件 ／ 問題 $questionCount 問',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                const PrairieRule(),
                const SizedBox(height: 12),
                Text(
                  kIsWeb
                      ? 'ブラウザのダウンロードとして保存されます。'
                      : '保存先を選べます。「ファイルに保存」で本体へ、'
                            '「Google ドライブ」などのアプリを選べばクラウドへ送れます。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _save(context),
                  icon: Icon(kIsWeb ? Icons.download : Icons.ios_share),
                  label: Text(kIsWeb ? 'ダウンロード' : '保存先を選んで保存'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ------------------------------------------ その他の操作
          const PrairieSectionHeader('そのほか', accent: PrairieColors.ochre),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.copy_all),
            title: const Text('JSON をクリップボードにコピー'),
            subtitle: const Text('テキストとして貼り付けて移行したいとき'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: repo.exportJson()));
              messenger.showSnackBar(
                const SnackBar(content: Text('JSON をコピーしました')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.paste),
            title: const Text('JSON を読み込む（貼り付け）'),
            subtitle: const Text('現在のデータはすべて置き換えられます'),
            onTap: () => _showImportDialog(context),
          ),
          const SizedBox(height: 32),

          // ------------------------------------------ 自動保存先の説明
          const PrairieSectionHeader('自動保存先', accent: PrairieColors.moss),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: repo.storageLocation(),
            builder: (context, snapshot) => ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(snapshot.data ?? '確認中…'),
              subtitle: const Text('変更のたびに自動で保存されています'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final repo = RepositoryScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await saveJsonFile(
        repo.exportJson(),
        fileNameFor(DateTime.now()),
      );
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    }
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final repo = RepositoryScope.of(context);
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON を読み込む'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '書き出した JSON を貼り付けてください',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('置き換えて読み込む'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await repo.importJson(controller.text);
      messenger.showSnackBar(const SnackBar(content: Text('読み込みました')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('読み込みに失敗しました: $e')));
    }
  }
}
