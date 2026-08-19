import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../models/quiz_models.dart';
import '../widgets/pickers.dart';

/// 問題の新規作成 / 編集画面。
class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({
    super.key,
    this.questionId,
    this.initialTopicId,
    this.initialSubTopicId,
  });

  /// 編集対象。null なら新規作成。
  final String? questionId;
  final String? initialTopicId;
  final String? initialSubTopicId;

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  static const int choiceCount = 4;

  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();
  final List<TextEditingController> _choiceControllers =
      List.generate(choiceCount, (_) => TextEditingController());

  String? _topicId;
  String? _subTopicId;
  final List<bool> _correct = List.filled(choiceCount, false);
  String? _imageBase64;
  bool _initialized = false;

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (final c in _choiceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _topicId = widget.initialTopicId;
    _subTopicId = widget.initialSubTopicId;
    final id = widget.questionId;
    if (id != null) {
      final q = RepositoryScope.of(context).questionById(id);
      if (q != null) {
        _topicId = q.topicId;
        _subTopicId = q.subTopicId;
        _questionController.text = q.text;
        _explanationController.text = q.explanation;
        _imageBase64 = q.imageBase64;
        for (var i = 0; i < choiceCount; i++) {
          if (i < q.choices.length) {
            _choiceControllers[i].text = q.choices[i].text;
            _correct[i] = q.choices[i].isCorrect;
          }
        }
      }
    }
  }

  Future<void> _pickTopic() async {
    final repo = RepositoryScope.of(context);
    // 既存の題材から選ぶか、新規作成するかを選択できる。
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('既存の題材から選ぶ'),
              onTap: () => Navigator.of(context).pop('existing'),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('新しい題材を作る'),
              onTap: () => Navigator.of(context).pop('new'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'existing') {
      final topic = await showTopicPicker(context, repo.topics);
      if (topic != null) {
        setState(() {
          _topicId = topic.id;
          _subTopicId = null;
        });
      }
    } else {
      final name = await showNameInputDialog(context,
          title: '新しい題材', hint: '例: 情報科学概論');
      if (name != null) {
        final topic = await repo.addTopic(name);
        setState(() {
          _topicId = topic.id;
          _subTopicId = null;
        });
      }
    }
  }

  Future<void> _pickSubTopic() async {
    final repo = RepositoryScope.of(context);
    final topic = repo.topicById(_topicId);
    if (topic == null) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.topic_outlined),
              title: const Text('既存のサブ題材から選ぶ'),
              onTap: () => Navigator.of(context).pop('existing'),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('新しいサブ題材を作る'),
              onTap: () => Navigator.of(context).pop('new'),
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('サブ題材なしにする'),
              onTap: () => Navigator.of(context).pop('none'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case 'existing':
        final sub = await showSubTopicPicker(context, topic.subTopics);
        if (sub != null) setState(() => _subTopicId = sub.id);
      case 'new':
        final name = await showNameInputDialog(context,
            title: '新しいサブ題材', hint: '例: 第3回');
        if (name != null) {
          final sub = await repo.addSubTopic(topic.id, name);
          setState(() => _subTopicId = sub.id);
        }
      case 'none':
        setState(() => _subTopicId = null);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1600);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _imageBase64 = base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('画像の読み込みに失敗しました: $e')));
    }
  }

  Future<void> _save() async {
    final repo = RepositoryScope.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_topicId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('題材を選択してください')));
      return;
    }
    if (!_correct.contains(true)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('正解の選択肢に丸を付けてください')));
      return;
    }

    final choices = [
      for (var i = 0; i < choiceCount; i++)
        Choice(
          text: _choiceControllers[i].text.trim(),
          isCorrect: _correct[i],
        ),
    ];

    final navigator = Navigator.of(context);
    final existingId = widget.questionId;
    if (existingId != null) {
      final original = repo.questionById(existingId);
      if (original != null) {
        await repo.updateQuestion(original.copyWith(
          topicId: _topicId,
          subTopicId: _subTopicId,
          clearSubTopic: _subTopicId == null,
          text: _questionController.text.trim(),
          imageBase64: _imageBase64,
          clearImage: _imageBase64 == null,
          choices: choices,
          explanation: _explanationController.text.trim(),
        ));
      }
    } else {
      await repo.addQuestion(Question(
        id: generateId('q'),
        topicId: _topicId!,
        subTopicId: _subTopicId,
        text: _questionController.text.trim(),
        imageBase64: _imageBase64,
        choices: choices,
        explanation: _explanationController.text.trim(),
      ));
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final topic = repo.topicById(_topicId);
    final sub = topic?.subTopicById(_subTopicId);
    final isEditing = widget.questionId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '問題を編集' : '問題を作成')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ------------------------------------------------ 題材の選択
            Text('題材', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTopic,
                    icon: const Icon(Icons.folder_outlined),
                    label: Text(topic?.name ?? '題材を選択（必須）'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: topic == null ? null : _pickSubTopic,
                    icon: const Icon(Icons.topic_outlined),
                    label: Text(sub?.name ?? 'サブ題材なし'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ------------------------------------------------ 問題文
            Text('問題文', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _questionController,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '問題文を入力',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? '問題文は必須です' : null,
            ),
            const SizedBox(height: 8),
            if (_imageBase64 != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(_imageBase64!),
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _imageBase64 = null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('画像を削除'),
              ),
            ] else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('画像を添付（任意）'),
                ),
              ),
            const SizedBox(height: 16),

            // ------------------------------------------------ 選択肢
            Text('選択肢', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '正解に丸を付けてください（1つでも複数でも可）',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < choiceCount; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '正解にする',
                      icon: Icon(
                        _correct[i]
                            ? Icons.circle_outlined
                            : Icons.radio_button_unchecked,
                        color: _correct[i]
                            ? Colors.redAccent
                            : Theme.of(context).disabledColor,
                        size: 28,
                      ),
                      onPressed: () =>
                          setState(() => _correct[i] = !_correct[i]),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _choiceControllers[i],
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: '選択肢 ${i + 1}',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? '選択肢を入力してください'
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // ------------------------------------------------ 解説
            Text('解説', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _explanationController,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '回答の解説を入力（回答後に表示されます）',
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEditing ? '変更を保存' : '問題を保存'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
