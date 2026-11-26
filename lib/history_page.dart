import 'dart:math';

import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'card_storage.dart';
import 'history_storage.dart';
import 'main.dart';
import 'question.dart';
import 'quiz_attempt.dart';

enum HistoryFilter { all, practice, exam }

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.historyStorage,
    required this.allQuestions,
    required this.language,
    this.cardStorage = const SharedPrefsCardStorage(),
  });

  final HistoryStorage historyStorage;
  final List<Question> allQuestions;
  final QuestionLanguage language;
  final CardStorage cardStorage;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  AppStrings get s => AppStrings.of(widget.language);
  late Future<List<QuizAttempt>> _historyFuture;
  HistoryFilter _filter = HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _historyFuture = widget.historyStorage.loadHistory();
    });
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.confirmClearHistory),
        content: Text(s.confirmClearHistoryContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.clearHistory),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.historyStorage.clearHistory();
      _reload();
    }
  }

  Future<void> _deleteAttempt(QuizAttempt attempt) async {
    await widget.historyStorage.deleteAttempt(attempt.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.historyAttemptDeleted),
        duration: const Duration(seconds: 2),
      ),
    );
    _reload();
  }

  void _reviewAttempt(QuizAttempt attempt) {
    if (widget.allQuestions.isEmpty || attempt.questionIds.isEmpty) return;

    final questionMap = {for (final q in widget.allQuestions) q.id: q};
    final quizItems = <QuizItem>[];
    for (final qId in attempt.questionIds) {
      final question = questionMap[qId];
      if (question != null) {
        quizItems.add(QuizItem(question, Random(qId)));
      }
    }
    if (quizItems.isEmpty) return;

    final result = QuizResult(
      quizItems,
      attempt.answers,
      expired: attempt.expired,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultPage(
          result: result,
          language: widget.language,
          storage: widget.cardStorage,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.historyTitle),
        actions: [
          IconButton(
            tooltip: s.clearHistory,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(s.historyFilterAll),
                  selected: _filter == HistoryFilter.all,
                  onSelected: (val) {
                    if (val) setState(() => _filter = HistoryFilter.all);
                  },
                ),
                ChoiceChip(
                  label: Text(s.historyFilterPractice),
                  selected: _filter == HistoryFilter.practice,
                  onSelected: (val) {
                    if (val) setState(() => _filter = HistoryFilter.practice);
                  },
                ),
                ChoiceChip(
                  label: Text(s.historyFilterExam),
                  selected: _filter == HistoryFilter.exam,
                  onSelected: (val) {
                    if (val) setState(() => _filter = HistoryFilter.exam);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<QuizAttempt>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? const [];
                final filtered = list.where((item) {
                  return switch (_filter) {
                    HistoryFilter.all => true,
                    HistoryFilter.practice => !item.isExam,
                    HistoryFilter.exam => item.isExam,
                  };
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.emptyHistory,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final durationStr = s.historyDuration(
                      item.durationSeconds ~/ 60,
                      item.durationSeconds % 60,
                    );
                    final topicText = item.topic == 0
                        ? s.allTopics
                        : topicLabel(item.topic, widget.language);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _reviewAttempt(item),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    avatar: Icon(
                                      item.isExam
                                          ? Icons.timer_outlined
                                          : Icons.school_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      item.isExam
                                          ? s.historyExamLabel
                                          : s.historyPracticeLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      topicText,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    tooltip: s.historyDeleteAttempt,
                                    onPressed: () => _deleteAttempt(item),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${item.percent}%',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: item.percent >= 80
                                              ? Colors.green.shade700
                                              : item.percent >= 50
                                              ? Colors.orange.shade800
                                              : Colors.red.shade700,
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      s.scoreLine(
                                        item.correct,
                                        item.wrong,
                                        item.skipped,
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(item.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    durationStr,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
