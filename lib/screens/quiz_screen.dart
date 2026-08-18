import 'dart:convert';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/quiz_models.dart';

/// 出題画面。題材（またはサブ題材）内の問題をランダムな順で出題する。
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.topicId,
    this.subTopicId,
    required this.title,
  });

  final String topicId;
  final String? subTopicId;
  final String title;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  int _index = 0;
  Set<int> _selected = {};
  bool _answered = false;
  int _correctCount = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    // 出題開始時に一度だけスナップショットを取り、シャッフルする。
    final repo = RepositoryScope.of(context);
    _questions = repo.questionsIn(widget.topicId,
        subTopicId: widget.subTopicId)
      ..shuffle();
  }

  Question get _current => _questions[_index];
  bool get _isDone => _index >= _questions.length;

  void _toggleChoice(int i) {
    if (_answered) return;
    setState(() {
      if (_current.answerType == AnswerType.single) {
        _selected = {i};
      } else {
        _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
      }
    });
  }

  void _submit() {
    if (_selected.isEmpty) return;
    setState(() {
      _answered = true;
      if (_current.isCorrectAnswer(_selected)) _correctCount++;
    });
  }

  void _next() {
    setState(() {
      _index++;
      _selected = {};
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('出題できる問題がありません')),
      );
    }
    if (_isDone) return _buildResult(context);

    final q = _current;
    final theme = Theme.of(context);
    final isCorrect = _answered && q.isCorrectAnswer(_selected);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_index + (_answered ? 1 : 0)) / _questions.length,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('第 ${_index + 1} 問 / 全 ${_questions.length} 問　（${q.answerType.label}）',
              style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(q.text, style: theme.textTheme.titleLarge),
          if (q.imageBase64 != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(q.imageBase64!),
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < q.choices.length; i++)
            _ChoiceCard(
              text: q.choices[i].text,
              selected: _selected.contains(i),
              answered: _answered,
              isCorrectChoice: q.choices[i].isCorrect,
              multiple: q.answerType == AnswerType.multiple,
              onTap: () => _toggleChoice(i),
            ),
          const SizedBox(height: 16),

          // ------------------------------------------ 回答結果と解説
          if (_answered) ...[
            Card(
              color: isCorrect
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.circle_outlined : Icons.close,
                          color: isCorrect ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? '正解！' : '不正解…',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isCorrect
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    if (q.explanation.trim().isNotEmpty) ...[
                      const Divider(),
                      Text('解説', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(q.explanation),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                  _index + 1 < _questions.length ? '次の問題へ' : '結果を見る'),
            ),
          ] else
            FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _submit,
              icon: const Icon(Icons.check),
              label: const Text('回答する'),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final theme = Theme.of(context);
    final rate = (_correctCount / _questions.length * 100).round();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('結果', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text('$_correctCount / ${_questions.length} 問正解（$rate%）',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _questions.shuffle();
                    _index = 0;
                    _selected = {};
                    _answered = false;
                    _correctCount = 0;
                  });
                },
                icon: const Icon(Icons.replay),
                label: const Text('もう一度挑戦'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.text,
    required this.selected,
    required this.answered,
    required this.isCorrectChoice,
    required this.multiple,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool answered;
  final bool isCorrectChoice;
  final bool multiple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? borderColor;
    Widget? trailing;
    if (answered) {
      // 回答後は正解の選択肢を緑、誤って選んだ選択肢を赤で示す。
      if (isCorrectChoice) {
        borderColor = Colors.green;
        trailing = const Icon(Icons.circle_outlined, color: Colors.green);
      } else if (selected) {
        borderColor = Colors.red;
        trailing = const Icon(Icons.close, color: Colors.red);
      }
    } else if (selected) {
      borderColor = theme.colorScheme.primary;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor ?? theme.dividerColor,
          width: borderColor != null ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          multiple
              ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
              : (selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
          color: selected ? theme.colorScheme.primary : null,
        ),
        title: Text(text),
        trailing: trailing,
      ),
    );
  }
}
