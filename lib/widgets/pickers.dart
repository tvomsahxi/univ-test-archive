import 'package:flutter/material.dart';

import '../models/quiz_models.dart';

/// 既存の題材から1つ選ぶモーダル。戻り値は選択された題材（キャンセル時は null）。
Future<Topic?> showTopicPicker(BuildContext context, List<Topic> topics) {
  return showModalBottomSheet<Topic>(
    context: context,
    showDragHandle: true,
    builder: (context) => _PickerSheet<Topic>(
      title: '題材を選択',
      items: topics,
      labelOf: (t) => t.name,
      emptyMessage: 'まだ題材がありません。「新しい題材」から作成してください。',
    ),
  );
}

/// 既存のサブ題材から1つ選ぶモーダル。
Future<SubTopic?> showSubTopicPicker(
    BuildContext context, List<SubTopic> subTopics) {
  return showModalBottomSheet<SubTopic>(
    context: context,
    showDragHandle: true,
    builder: (context) => _PickerSheet<SubTopic>(
      title: 'サブ題材を選択',
      items: subTopics,
      labelOf: (s) => s.name,
      emptyMessage: 'この題材にはまだサブ題材がありません。',
    ),
  );
}

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.emptyMessage,
  });

  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyMessage),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(labelOf(item)),
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 名前を1つ入力するだけのダイアログ（題材・サブ題材の新規作成 / 改名に使う）。
Future<String?> showNameInputDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String hint = '名前を入力',
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  final trimmed = result?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// 削除前の確認ダイアログ。true なら削除を実行する。
Future<bool> confirmDelete(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('削除の確認'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('削除する'),
        ),
      ],
    ),
  );
  return result ?? false;
}
