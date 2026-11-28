import 'package:flutter/material.dart';

import 'card_storage.dart';
import 'learning_tools.dart';
import 'question.dart';
import 'question_prompt.dart';
import 'sm2.dart';

/// Màn hình ôn tập thẻ ghi nhớ (Flashcard) theo thuật toán SM-2.
class FlashcardPage extends StatefulWidget {
  const FlashcardPage({
    super.key,
    required this.allQuestions,
    this.storage = const SharedPrefsCardStorage(),
    this.language = QuestionLanguage.vietnamese,
    this.embedded = false,
    this.onCardsChanged,
    this.onCardGraded,
    this.onPracticeRequested,
  });

  final List<Question> allQuestions;
  final CardStorage storage;
  final QuestionLanguage language;
  final bool embedded;
  final VoidCallback? onCardsChanged;

  /// Gọi sau mỗi lần chấm mức nhớ, dùng để ghi nhận ngày học cho chuỗi.
  final VoidCallback? onCardGraded;
  final VoidCallback? onPracticeRequested;

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  late QuestionLanguage language = widget.language;
  List<Sm2Item> allCards = [];
  bool loading = true;
  bool onlyDue = true;
  int currentIndex = 0;
  bool showAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void didUpdateWidget(covariant FlashcardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) language = widget.language;
  }

  Future<void> _loadCards() async {
    final loaded = await widget.storage.loadCards();
    if (!mounted) return;
    setState(() {
      allCards = loaded;
      loading = false;
      currentIndex = 0;
      showAnswer = false;
    });
  }

  List<Sm2Item> get activeCards {
    if (onlyDue) {
      return allCards.where((card) => card.isDue()).toList();
    }
    return allCards;
  }

  Question? _findQuestion(int questionId) {
    for (final q in widget.allQuestions) {
      if (q.id == questionId) return q;
    }
    return null;
  }

  Future<void> _rateCard(Sm2Item item, int grade) async {
    const sm2 = Sm2();
    final updated = sm2.review(item: item, grade: grade);
    await widget.storage.updateCard(updated);
    widget.onCardsChanged?.call();
    widget.onCardGraded?.call();

    if (!mounted) return;

    // Cập nhật lại trong danh sách local
    setState(() {
      final idx = allCards.indexWhere((c) => c.questionId == item.questionId);
      if (idx != -1) {
        allCards[idx] = updated;
      }
      showAnswer = false;
      if (currentIndex < activeCards.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          grade < 3
              ? 'Đã đặt lịch: Ôn lại ngày mai.'
              : 'Đã cập nhật: Hẹn ôn lại sau ${updated.interval} ngày.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteCard(int questionId) async {
    await widget.storage.removeCard(questionId);
    widget.onCardsChanged?.call();
    if (!mounted) return;
    setState(() {
      allCards.removeWhere((c) => c.questionId == questionId);
      if (currentIndex >= activeCards.length && currentIndex > 0) {
        currentIndex--;
      }
      showAnswer = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xoá thẻ khỏi bộ ôn tập.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentList = activeCards;
    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : allCards.isEmpty
        ? _buildEmptyState()
        : currentList.isEmpty
        ? _buildCompletedDueState(totalCards: allCards.length)
        : _buildCardStudyView(currentList);
    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thẻ ghi nhớ SM-2'),
        actions: [
          PopupMenuButton<QuestionLanguage>(
            tooltip: 'Đổi ngôn ngữ thẻ',
            icon: const Icon(Icons.translate),
            onSelected: (value) => setState(() => language = value),
            itemBuilder: (_) => [
              for (final value in QuestionLanguage.values)
                PopupMenuItem(value: value, child: Text(value.label)),
            ],
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.style_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thẻ ghi nhớ',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy luyện tập hoặc thi thử, sau đó lưu các câu làm sai để bắt đầu lộ trình ôn tập theo lịch lặp lại ngắt quãng SM-2.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                widget.onPracticeRequested ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Quay lại luyện tập'),
          ),
        ],
      ),
    ),
  );

  Widget _buildCompletedDueState({required int totalCards}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Đã xong hôm nay!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã hoàn thành toàn bộ thẻ cần ôn cho ngày hôm nay trong tổng số $totalCards thẻ.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => setState(() => onlyDue = false),
            icon: const Icon(Icons.all_inclusive),
            label: Text('Ôn tiếp tất cả $totalCards thẻ'),
          ),
        ],
      ),
    ),
  );

  Widget _buildCardStudyView(List<Sm2Item> currentList) {
    if (currentIndex >= currentList.length) {
      currentIndex = 0;
    }
    final card = currentList[currentIndex];
    final question = _findQuestion(card.questionId);

    if (question == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Không tìm thấy câu hỏi mã ID #${card.questionId}'),
            ElevatedButton(
              onPressed: () => _deleteCard(card.questionId),
              child: const Text('Xoá thẻ lỗi này'),
            ),
          ],
        ),
      );
    }

    final dueDateStr =
        '${card.nextReviewDate.day.toString().padLeft(2, '0')}/${card.nextReviewDate.month.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Thanh bộ lọc & Tiến độ
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Thẻ ${currentIndex + 1}/${currentList.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Đến hạn'),
                  icon: Icon(Icons.alarm),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Tất cả'),
                  icon: Icon(Icons.view_carousel),
                ),
              ],
              selected: {onlyDue},
              onSelectionChanged: (set) {
                setState(() {
                  onlyDue = set.first;
                  currentIndex = 0;
                  showAnswer = false;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Thẻ thông tin SM-2
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Lặp: ${card.repetitions} lần · Cách: ${card.interval} ngày',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Hạn: $dueDateStr (EF: ${card.easeFactor})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Xoá thẻ này',
                  onPressed: () => _deleteCard(card.questionId),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Khung nội dung câu hỏi (Mặt trước)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${topicLabel(question.topic, language)} · ${question.level}',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 8),
                QuestionPrompt(question: question, language: language),
                const SizedBox(height: 16),
                const Text(
                  'Lựa chọn:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                for (final (index, choice) in question.choices.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${String.fromCharCode(65 + index)}. ${language.display(choice.vi, choice.en)}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Mặt sau: Đáp án & Giải thích & Đánh giá
        if (!showAnswer)
          FilledButton.icon(
            onPressed: () => setState(() => showAnswer = true),
            icon: const Icon(Icons.visibility),
            label: const Text('Xem đáp án & giải thích'),
          )
        else ...[
          Card(
            color: Colors.green.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.green, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Đáp án đúng: ${question.correctId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    language.display(
                      question.explanationVi,
                      question.explanationEn,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showLearningTool(
              context,
              LearningTool.assistant,
              question: question,
              language: language,
            ),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Hỏi AI về câu này · Sắp có'),
          ),
          const SizedBox(height: 20),
          Text(
            'Đánh giá mức độ nhớ (SM-2):',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.cancel, color: Colors.red),
                label: const Text('1: Quên (Mai ôn lại)'),
                onPressed: () => _rateCard(card, 1),
              ),
              ActionChip(
                avatar: const Icon(Icons.help_outline, color: Colors.orange),
                label: const Text('3: Khó nhớ'),
                onPressed: () => _rateCard(card, 3),
              ),
              ActionChip(
                avatar: const Icon(
                  Icons.thumb_up_alt_outlined,
                  color: Colors.blue,
                ),
                label: const Text('4: Nhớ tốt'),
                onPressed: () => _rateCard(card, 4),
              ),
              ActionChip(
                avatar: const Icon(Icons.verified, color: Colors.green),
                label: const Text('5: Rất dễ'),
                onPressed: () => _rateCard(card, 5),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
