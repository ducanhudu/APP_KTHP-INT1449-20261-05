import 'dart:math';

import 'question.dart';
import 'quiz_attempt.dart';
import 'sm2.dart';

/// Thống kê mức độ nắm vững của một khối kiến thức.
class TopicMastery {
  const TopicMastery({
    required this.topic,
    this.totalAnswered = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.skippedCount = 0,
    this.cardCount = 0,
  });

  final int topic; // 1..20
  final int totalAnswered;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int cardCount;

  double get accuracy =>
      totalAnswered == 0 ? 0.0 : (correctCount / totalAnswered);
  int get accuracyPercent => (accuracy * 100).round();
  double get errorRate =>
      totalAnswered == 0 ? 0.0 : (wrongCount / totalAnswered);

  /// Coi là khối yếu khi đã làm ít nhất 2 câu và tỷ lệ đúng dưới 70%,
  /// hoặc có từ 2 thẻ flashcard cần ôn trong khối này.
  bool get isWeak =>
      (totalAnswered >= 2 && accuracy < 0.7) ||
      (cardCount >= 2 && accuracy < 0.75);

  /// Điểm đánh giá mức độ yếu (càng cao càng cần ôn luyện).
  double get weaknessScore {
    if (totalAnswered == 0 && cardCount == 0) return 0.0;
    final accFactor = (1.0 - accuracy) * 0.6;
    final errFactor = errorRate * 0.25;
    final cardFactor = cardCount > 0 ? 0.15 : 0.0;
    return accFactor + errFactor + cardFactor;
  }
}

/// Kết quả phân tích điểm yếu tổng thể của người học.
class WeaknessAnalysisResult {
  const WeaknessAnalysisResult({
    required this.topicStats,
    required this.rankedWeakTopics,
    required this.hasEnoughData,
    required this.totalQuestionsAttempted,
  });

  final Map<int, TopicMastery> topicStats;

  /// Danh sách các khối yếu nhất được sắp xếp theo mức độ cần ôn giảm dần.
  final List<TopicMastery> rankedWeakTopics;

  /// Đã có dữ liệu bài làm để phân tích hay chưa.
  final bool hasEnoughData;

  /// Tổng số câu hỏi người dùng đã trả lời qua tất cả bài làm.
  final int totalQuestionsAttempted;

  /// Lấy Top N khối yếu nhất (mặc định 3 khối).
  List<TopicMastery> topWeakTopics([int n = 3]) =>
      rankedWeakTopics.take(n).toList();
}

/// Bộ phân tích năng lực và sinh đề luyện tập thích ứng theo điểm yếu.
class WeaknessAnalyzer {
  const WeaknessAnalyzer._();

  /// Phân tích dữ liệu lịch sử làm bài và bộ thẻ flashcard.
  static WeaknessAnalysisResult analyze({
    required List<QuizAttempt> history,
    required List<Question> bank,
    List<Sm2Item>? flashcards,
  }) {
    final questionMap = {for (final q in bank) q.id: q};

    // Đếm số thẻ ghi nhớ theo từng khối
    final cardsPerTopic = <int, int>{};
    for (final card in flashcards ?? const <Sm2Item>[]) {
      final q = questionMap[card.questionId];
      if (q != null) {
        cardsPerTopic.update(q.topic, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    // Tích lũy kết quả đúng / sai / bỏ trống theo từng khối
    final correctPerTopic = <int, int>{};
    final wrongPerTopic = <int, int>{};
    final skippedPerTopic = <int, int>{};
    final totalPerTopic = <int, int>{};
    var totalQuestionsAttempted = 0;

    for (final attempt in history) {
      for (final qId in attempt.questionIds) {
        final q = questionMap[qId];
        if (q == null) continue;

        totalQuestionsAttempted++;
        final answer = attempt.answers[qId];
        if (answer == null) {
          skippedPerTopic.update(q.topic, (v) => v + 1, ifAbsent: () => 1);
        } else if (answer == q.correctId) {
          correctPerTopic.update(q.topic, (v) => v + 1, ifAbsent: () => 1);
          totalPerTopic.update(q.topic, (v) => v + 1, ifAbsent: () => 1);
        } else {
          wrongPerTopic.update(q.topic, (v) => v + 1, ifAbsent: () => 1);
          totalPerTopic.update(q.topic, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    final stats = <int, TopicMastery>{};
    for (var topic = 1; topic <= topicNames.length; topic++) {
      stats[topic] = TopicMastery(
        topic: topic,
        totalAnswered: totalPerTopic[topic] ?? 0,
        correctCount: correctPerTopic[topic] ?? 0,
        wrongCount: wrongPerTopic[topic] ?? 0,
        skippedCount: skippedPerTopic[topic] ?? 0,
        cardCount: cardsPerTopic[topic] ?? 0,
      );
    }

    // Lọc và sắp xếp các khối có dữ liệu và có điểm yếu
    final activeTopics = stats.values
        .where((m) => m.totalAnswered > 0 || m.cardCount > 0)
        .toList();

    activeTopics.sort((a, b) => b.weaknessScore.compareTo(a.weaknessScore));

    final weakTopics = activeTopics
        .where((m) => m.isWeak || m.accuracy < 0.75)
        .toList();

    return WeaknessAnalysisResult(
      topicStats: stats,
      rankedWeakTopics: weakTopics.isNotEmpty ? weakTopics : activeTopics,
      hasEnoughData:
          totalQuestionsAttempted > 0 || (flashcards?.isNotEmpty ?? false),
      totalQuestionsAttempted: totalQuestionsAttempted,
    );
  }

  /// Sinh danh sách câu hỏi thích ứng tập trung vào các khối yếu.
  static List<Question> selectAdaptiveQuestions({
    required WeaknessAnalysisResult analysis,
    required List<Question> bank,
    required List<QuizAttempt> history,
    List<Sm2Item>? flashcards,
    int count = 10,
    Random? random,
  }) {
    final rng = random ?? Random();
    final questionMap = {for (final q in bank) q.id: q};

    // Xác định các khối mục tiêu
    final targetTopics = analysis.topWeakTopics(3).map((m) => m.topic).toSet();

    // Thu thập các câu hỏi người dùng từng làm sai
    final pastWrongIds = <int>{};
    for (final attempt in history) {
      for (final entry in attempt.answers.entries) {
        final q = questionMap[entry.key];
        if (q != null && entry.value != q.correctId) {
          pastWrongIds.add(q.id);
        }
      }
    }

    // Thu thập ID các câu trong bộ thẻ flashcard
    final cardIds = {
      for (final card in flashcards ?? const <Sm2Item>[]) card.questionId,
    };

    final selectedQuestions = <Question>[];
    final selectedIds = <int>{};

    void addQuestion(Question q) {
      if (selectedQuestions.length < count && selectedIds.add(q.id)) {
        selectedQuestions.add(q);
      }
    }

    // Ưu tiên 1: Câu hỏi từng làm sai thuộc khối yếu mục tiêu
    final targetPool =
        bank.where((q) => targetTopics.contains(q.topic)).toList()
          ..shuffle(rng);

    for (final q in targetPool) {
      if (pastWrongIds.contains(q.id)) addQuestion(q);
    }

    // Ưu tiên 2: Câu hỏi có trong bộ thẻ ghi nhớ thuộc khối yếu
    for (final q in targetPool) {
      if (cardIds.contains(q.id)) addQuestion(q);
    }

    // Ưu tiên 3: Các câu hỏi khác trong khối yếu mục tiêu
    for (final q in targetPool) {
      addQuestion(q);
    }

    // Nếu vẫn chưa đủ số lượng câu, bốc thêm từ toàn bộ ngân hàng
    if (selectedQuestions.length < count) {
      final allPool = bank.toList()..shuffle(rng);
      for (final q in allPool) {
        if (pastWrongIds.contains(q.id)) addQuestion(q);
      }
      for (final q in allPool) {
        addQuestion(q);
      }
    }

    return selectedQuestions..shuffle(rng);
  }
}
