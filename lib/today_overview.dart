import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'learning_tools.dart';
import 'question.dart';
import 'reminder_service.dart';
import 'reminder_tile.dart';
import 'sm2.dart';

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
    this.language = QuestionLanguage.vietnamese,
    this.onCameraRequested,
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

  /// Ngôn ngữ của nhãn giao diện.
  final QuestionLanguage language;
  final VoidCallback? onCameraRequested;

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
                  title: Text(topicNames[topic - 1]),
                  subtitle: Text(
                    '${questions.where((q) => q.topic == topic).length} ${s.unitQuestions}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onTopic(topic),
                ),
            ],
          ),
        ),
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
                trailing: Chip(label: Text(s.soon)),
                onTap: () => showLearningTool(context, LearningTool.assistant),
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
            ],
          ),
        ),
      ],
    );
  }
}
