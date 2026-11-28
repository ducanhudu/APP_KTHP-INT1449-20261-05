import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'history_storage.dart';
import 'question.dart';
import 'quiz_attempt.dart';
import 'study_statistics.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    super.key,
    required this.historyStorage,
    required this.questions,
    required this.language,
  });

  final HistoryStorage historyStorage;
  final List<Question> questions;
  final QuestionLanguage language;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  AppStrings get s => AppStrings.of(widget.language);
  late Future<List<QuizAttempt>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.historyStorage.loadHistory();
  }

  Future<void> _reload() async {
    final history = widget.historyStorage.loadHistory();
    setState(() => _historyFuture = history);
    try {
      await history;
    } catch (_) {
      // The FutureBuilder displays the error and offers another retry.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.statisticsTitle)),
      body: FutureBuilder<List<QuizAttempt>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.errorHistoryLoad),
                  const SizedBox(height: 8),
                  FilledButton.tonal(onPressed: _reload, child: Text(s.retry)),
                ],
              ),
            );
          }

          final statistics = StudyStatistics.fromHistory(
            history: snapshot.data ?? const [],
            bank: widget.questions,
          );
          if (statistics.attemptCount == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.statisticsEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _SummaryCard(statistics: statistics, strings: s),
                const SizedBox(height: 24),
                Text(s.statisticsTrend, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(s.statisticsTrendSubtitle),
                const SizedBox(height: 12),
                _RecentScoresChart(attempts: statistics.recentAttempts),
                const SizedBox(height: 24),
                Text(s.statisticsByTopic, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (statistics.topicProgress.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(s.statisticsTopicsUnavailable),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < statistics.topicProgress.length;
                            index++
                          ) ...[
                            if (index > 0) const Divider(height: 24),
                            _TopicProgressRow(
                              item: statistics.topicProgress[index],
                              language: widget.language,
                              strings: s,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.statistics, required this.strings});

  final StudyStatistics statistics;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.statisticsSummary, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    value: '${statistics.attemptCount}',
                    label: strings.statisticsAttempts,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: '${statistics.totalQuestions}',
                    label: strings.statisticsQuestions,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: '${statistics.scorePercent}%',
                    label: strings.statisticsAverage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              strings.statisticsAnswerBreakdown(
                statistics.correct,
                statistics.wrong,
                statistics.skipped,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _RecentScoresChart extends StatelessWidget {
  const _RecentScoresChart({required this.attempts});

  final List<QuizAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        child: SizedBox(
          height: 146,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < attempts.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Text(
                          '${attempts[index].percent}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: math.max(
                                0.04,
                                attempts[index].percent / 100,
                              ),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dateLabel(attempts[index].timestamp),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _TopicProgressRow extends StatelessWidget {
  const _TopicProgressRow({
    required this.item,
    required this.language,
    required this.strings,
  });

  final TopicProgress item;
  final QuestionLanguage language;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                topicLabel(item.topic, language),
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text('${item.scorePercent}%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: item.scorePercent / 100,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.statisticsTopicBreakdown(
            item.correct,
            item.totalQuestions,
            item.wrong,
            item.skipped,
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
