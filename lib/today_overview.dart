import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'learning_tools.dart';
import 'question.dart';
import 'quiz_attempt.dart';
import 'reminder_service.dart';
import 'reminder_tile.dart';
import 'sm2.dart';
import 'weakness_analyzer.dart';

class TodayOverview extends StatelessWidget {
  const TodayOverview({
    super.key,
    required this.questions,
    required this.cardsFuture,
    required this.onOpenCards,
    required this.onQuickPractice,
    required this.onExam,
    required this.onTopic,
    required this.onPracticeSetup,
    required this.onRetryCards,
    required this.reminder,
    this.historyFuture,
    this.onAdaptivePractice,
    this.language = QuestionLanguage.vietnamese,
    this.onCameraRequested,
    this.onAiTutor,
    this.onStatistics,
  });

  final List<Question> questions;
  final Future<List<Sm2Item>> cardsFuture;
  final VoidCallback onOpenCards;
  final VoidCallback onQuickPractice;
  final VoidCallback onExam;
  final ValueChanged<int> onTopic;
  final VoidCallback onPracticeSetup;

  /// Đọc lại bộ thẻ khi người dùng bấm "Thử lại" ở trạng thái lỗi.
  final VoidCallback onRetryCards;

  /// Dịch vụ nhắc ôn hằng ngày.
  final ReminderService reminder;

  /// Tương lai đọc danh sách lịch sử để phân tích điểm yếu.
  final Future<List<QuizAttempt>>? historyFuture;

  /// Bắt đầu lượt luyện tập thích ứng theo điểm yếu.
  final VoidCallback? onAdaptivePractice;

  /// Ngôn ngữ của nhãn giao diện.
  final QuestionLanguage language;
  final VoidCallback? onCameraRequested;

  /// Mở panel Gia sư AI với danh sách câu đã làm sai (do màn chính cung cấp).
  final VoidCallback? onAiTutor;
  final VoidCallback? onStatistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(language);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(s.todaySubtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(
          s.todayHeading,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 22),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<List<Sm2Item>>(
              future: cardsFuture,
              builder: (context, snapshot) {
                final cards = snapshot.data;
                final due = cards?.where((card) => card.isDue()).length ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.layers_outlined),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s.cardsTitle)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      cards == null ? s.loadingCards : s.cardsDue(due),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (snapshot.hasError)
                      TextButton.icon(
                        onPressed: onRetryCards,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(s.cardsRetry),
                      )
                    else if (cards != null)
                      Text(s.cardsSaved(cards.length, due)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onOpenCards,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(due > 0 ? s.openCardsDue : s.openCards),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          child: ReminderTile(service: reminder, strings: s),
        ),
        const SizedBox(height: 24),
        Text(s.practiceSection, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(s.bankSummary(questions.length, topicNames.length)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onQuickPractice,
              icon: const Icon(Icons.bolt_outlined),
              label: Text(s.quickPractice),
            ),
            OutlinedButton.icon(
              onPressed: onExam,
              icon: const Icon(Icons.timer_outlined),
              label: Text(s.examShort),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(s.pickTopic, style: theme.textTheme.titleLarge),
            ),
            TextButton(onPressed: onPracticeSetup, child: Text(s.all)),
          ],
        ),
        Card(
          child: Column(
            children: [
              for (final topic in [1, 3, 12])
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(topicName(topic, language)),
                  subtitle: Text(
                    '${questions.where((q) => q.topic == topic).length} ${s.unitQuestions}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onTopic(topic),
                ),
            ],
          ),
        ),
        if (historyFuture != null && onAdaptivePractice != null) ...[
          const SizedBox(height: 24),
          Text(s.weaknessHeading, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(s.weaknessSubtitle),
          const SizedBox(height: 12),
          FutureBuilder<List<QuizAttempt>>(
            future: historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _WeaknessDataStatus(message: s.loadingWeakness);
              }
              if (snapshot.hasError) {
                return _WeaknessDataStatus(
                  message: s.errorHistoryLoad,
                  onRetry: onRetryCards,
                  retryLabel: s.retry,
                );
              }
              final history = snapshot.data ?? const [];
              return FutureBuilder<List<Sm2Item>>(
                future: cardsFuture,
                builder: (context, cardSnap) {
                  if (cardSnap.connectionState != ConnectionState.done) {
                    return _WeaknessDataStatus(message: s.loadingWeakness);
                  }
                  if (cardSnap.hasError) {
                    return _WeaknessDataStatus(
                      message: s.errorWeaknessCardsLoad,
                      onRetry: onRetryCards,
                      retryLabel: s.retry,
                    );
                  }
                  final cards = cardSnap.data ?? const [];
                  final analysis = WeaknessAnalyzer.analyze(
                    history: history,
                    bank: questions,
                    flashcards: cards,
                  );
                  final weak = analysis.topWeakTopics(3);
                  if (!analysis.hasEnoughData ||
                      (weak.isEmpty && analysis.totalQuestionsAttempted == 0)) {
                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.insights_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.noWeaknessHint,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (weak.isEmpty) {
                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.noWeaknessFound,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in weak)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: item.accuracy < 0.6
                                    ? Colors.red.shade100
                                    : Colors.orange.shade100,
                                child: Text(
                                  'K${item.topic.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: item.accuracy < 0.6
                                        ? Colors.red.shade900
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                              title: Text(topicName(item.topic, language)),
                              subtitle: Text(
                                item.totalAnswered > 0
                                    ? s.accuracyText(item.accuracyPercent)
                                    : s.dueCardsCount(item.cardCount),
                              ),
                              trailing: Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(s.weakTopicBadge),
                              ),
                              onTap: () => onTopic(item.topic),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onAdaptivePractice,
                              icon: const Icon(Icons.bolt),
                              label: Text(s.practiceWeaknessBtn),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
        const SizedBox(height: 24),
        Text(s.toolsHeading, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: Text(s.aiTutor),
                subtitle: Text(s.aiTutorSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    onAiTutor ??
                    () => showLearningTool(
                      context,
                      LearningTool.assistant,
                      language: language,
                    ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(s.cameraTool),
                subtitle: Text(s.cameraSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    onCameraRequested ??
                    () => showLearningTool(
                      context,
                      LearningTool.camera,
                      language: language,
                    ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.question_answer_outlined),
                title: Text(s.aiOpenQuestionTitle),
                subtitle: Text(s.aiOpenQuestionSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLearningTool(
                  context,
                  LearningTool.askAi,
                  language: language,
                ),
              ),
            ],
          ),
        ),
        if (onStatistics != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.insights_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(s.homeStatisticsTitle),
              subtitle: Text(s.homeStatisticsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: onStatistics,
            ),
          ),
        ],
      ],
    );
  }
}

/// Avoid displaying a verdict while either input is unavailable or refreshing.
class _WeaknessDataStatus extends StatelessWidget {
  const _WeaknessDataStatus({
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = onRetry != null;
    return Card(
      elevation: 0,
      color: failed
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (failed)
                  Icon(Icons.error_outline, color: theme.colorScheme.error)
                else
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
            if (failed)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(retryLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
