import 'dart:convert';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/quiz_models.dart';
import '../theme/prairie_theme.dart';
import '../widgets/prairie.dart';

/// 出題画面。渡された問題プールからランダムな順で出題する。
///
/// 問題の選び方(題材全体 / サブ題材 / 上限付き / 将来の「間違えた問題だけ」など)は
/// 呼び出し側(QuizRepository.buildQuizSet)が決め、この画面は出題に専念する。
/// 解答するたび、解答日時と正誤をリポジトリへ記録する。
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.pool,
    this.limit,
    required this.title,
  });

  /// 出題対象の問題プール。
  final List<Question> pool;

  /// 1回の出題数の上限。null なら全問。
  final int? limit;

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

  @override
  void initState() {
    super.initState();
    _startNewRun();
  }

  /// プールをシャッフルし、上限を適用して新しい出題を始める。
  void _startNewRun() {
    final pool = [...widget.pool]..shuffle();
    final limit = widget.limit;
    _questions = (limit != null && limit > 0 && limit < pool.length)
        ? pool.sublist(0, limit)
        : pool;
    _index = 0;
    _selected = {};
    _answered = false;
    _correctCount = 0;
  }

  Question get _current => _questions[_index];
  bool get _isDone => _index >= _questions.length;

  void _toggleChoice(int i) {
    if (_answered) return;
    setState(() {
      _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
    });
  }

  void _submit() {
    if (_selected.isEmpty) return;
    final question = _current;
    final isCorrect = question.isCorrectAnswer(_selected);
    setState(() {
      _answered = true;
      if (isCorrect) _correctCount++;
    });
    // 解答日時と正誤を残す。復習の履歴として後から参照できる。
    RepositoryScope.of(context).recordAnswer(question.id, isCorrect: isCorrect);
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
          Text(
            '第 ${_index + 1} 問 ／ 全 ${_questions.length} 問',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          const PrairieRule(accent: PrairieColors.cherokee),
          const SizedBox(height: 16),
          Text(q.text, style: theme.textTheme.titleLarge),
          if (q.imageBase64 != null) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: PrairieColors.stone),
              ),
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
              onTap: () => _toggleChoice(i),
            ),
          const SizedBox(height: 16),

          // ------------------------------------------ 回答結果と解説
          if (_answered) ...[
            PrairieCard(
              accent: isCorrect ? PrairieColors.moss : PrairieColors.brick,
              background: PrairieColors.sand,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        color: isCorrect
                            ? PrairieColors.moss
                            : PrairieColors.brick,
                        child: Icon(
                          isCorrect ? Icons.check : Icons.close,
                          color: PrairieColors.parchment,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isCorrect ? '正解' : '不正解',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isCorrect
                              ? PrairieColors.moss
                              : PrairieColors.brick,
                        ),
                      ),
                    ],
                  ),
                  if (q.explanation.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const PrairieRule(),
                    const SizedBox(height: 12),
                    Text('解説', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(q.explanation),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward),
              label: Text(_index + 1 < _questions.length ? '次の問題へ' : '結果を見る'),
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
      body: Column(
        children: [
          const ArtGlassBanner(height: 72),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('結果', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      decoration: const BoxDecoration(
                        color: PrairieColors.sand,
                        border: Border(
                          top: BorderSide(
                            color: PrairieColors.cherokee,
                            width: 3,
                          ),
                          bottom: BorderSide(
                            color: PrairieColors.cherokee,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_correctCount / ${_questions.length}',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '正答率 $rate%',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    FilledButton.icon(
                      onPressed: () => setState(_startNewRun),
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
          ),
        ],
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
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool answered;
  final bool isCorrectChoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 回答後は正解を草原の緑、誤って選んだものを煉瓦色で示す。
    Color accent = PrairieColors.stone;
    Color background = PrairieColors.parchment;
    Widget? trailing;
    if (answered) {
      if (isCorrectChoice) {
        accent = PrairieColors.moss;
        background = PrairieColors.moss.withValues(alpha: 0.08);
        trailing = const Icon(Icons.check, color: PrairieColors.moss);
      } else if (selected) {
        accent = PrairieColors.brick;
        background = PrairieColors.brick.withValues(alpha: 0.08);
        trailing = const Icon(Icons.close, color: PrairieColors.brick);
      }
    } else if (selected) {
      accent = PrairieColors.cherokee;
      background = PrairieColors.sand;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // 背景色は Material 側に置く（ListTile のインク効果を隠さないため）。
      child: Material(
        color: background,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accent, width: 6),
              top: const BorderSide(color: PrairieColors.stone),
              right: const BorderSide(color: PrairieColors.stone),
              bottom: const BorderSide(color: PrairieColors.stone),
            ),
          ),
          child: ListTile(
            onTap: onTap,
            // 選択の印も方形。角丸を避けて直線構成を保つ。
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? PrairieColors.cherokee : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? PrairieColors.cherokee
                      : PrairieColors.stone,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: PrairieColors.parchment,
                    )
                  : null,
            ),
            title: Text(text, style: theme.textTheme.bodyLarge),
            trailing: trailing,
          ),
        ),
      ),
    );
  }
}
