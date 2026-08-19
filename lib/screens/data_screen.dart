import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/file_saver.dart';
import '../main.dart';

/// データ管理画面。保存先の確認、JSON の書き出し / 読み込みができる。
///
/// モバイル / デスクトップでは JSON ファイルに常時自動保存されるが、
/// Web は localStorage 保存のため、この画面からの書き出しがバックアップ手段になる。
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('データ管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<String>(
            future: repo.storageLocation(),
            builder: (context, snapshot) => ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('保存先'),
              subtitle: Text(snapshot.data ?? '確認中…'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('JSON をファイルとして保存'),
            subtitle: const Text(
                'Web ではブラウザのダウンロード、モバイルでは exports フォルダに保存されます'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final message =
                    await saveJsonFile(repo.exportJson(), 'questions.json');
                messenger.showSnackBar(SnackBar(content: Text(message)));
              } catch (e) {
                messenger.showSnackBar(
                    SnackBar(content: Text('保存に失敗しました: $e')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_all),
            title: const Text('JSON を書き出す（クリップボードへコピー）'),
            subtitle: const Text('バックアップや他端末への移行に使えます'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: repo.exportJson()));
              messenger.showSnackBar(
                  const SnackBar(content: Text('JSON をコピーしました')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.paste),
            title: const Text('JSON を読み込む（貼り付け）'),
            subtitle: const Text('現在のデータはすべて置き換えられます'),
            onTap: () => _showImportDialog(context),
          ),
        ],
      ),
    );
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
      messenger.showSnackBar(
          SnackBar(content: Text('読み込みに失敗しました: $e')));
    }
  }
}
