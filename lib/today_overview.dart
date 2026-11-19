import 'package:flutter/material.dart';

import 'learning_tools.dart';
import 'question.dart';
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
  });

  final List<Question> questions;
  final Future<List<Sm2Item>> cardsFuture;
  final VoidCallback onOpenCards;
  final VoidCallback onQuickPractice;
  final VoidCallback onExam;
  final ValueChanged<int> onTopic;
  final VoidCallback onPracticeSetup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('Ôn Flutter và Dart', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(
          'Hôm nay học gì?',
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
                    const Row(
                      children: [
                        Icon(Icons.layers_outlined),
                        SizedBox(width: 10),
                        Expanded(child: Text('Ôn tập Flashcard (SM-2)')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      cards == null ? 'Đang tải thẻ…' : '$due thẻ đến hạn',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (snapshot.hasError)
                      const Text('Chưa đọc được bộ thẻ. Mở bộ thẻ để thử lại.')
                    else if (cards != null)
                      Text(
                        '${cards.length} thẻ đã lưu · $due thẻ cần ôn hôm nay',
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onOpenCards,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(due > 0 ? 'Ôn thẻ ngay' : 'Mở bộ thẻ'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Luyện tập', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          '${questions.length} câu song ngữ · ${topicNames.length} khối kiến thức',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onQuickPractice,
              icon: const Icon(Icons.bolt_outlined),
              label: const Text('Luyện 10 câu'),
            ),
            OutlinedButton.icon(
              onPressed: onExam,
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Thi thử'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('Chọn chủ đề', style: theme.textTheme.titleLarge),
            ),
            TextButton(onPressed: onPracticeSetup, child: const Text('Tất cả')),
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
                    '${questions.where((q) => q.topic == topic).length} câu',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onTopic(topic),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Công cụ học tập', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('Gia sư AI'),
                subtitle: const Text('Giải thích theo câu hỏi và chủ đề'),
                trailing: const Chip(label: Text('Sắp có')),
                onTap: () => showLearningTool(context, LearningTool.assistant),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera học tập'),
                subtitle: const Text('Quét QR và chụp câu hỏi'),
                trailing: const Chip(label: Text('Sắp có')),
                onTap: () => showLearningTool(context, LearningTool.camera),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
