import 'question.dart';
import 'quiz_attempt.dart';

/// Kết quả học tập được tổng hợp từ lịch sử làm bài đã lưu.
class StudyStatistics {
  StudyStatistics._({
    required this.attemptCount,
    required this.totalQuestions,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.recentAttempts,
    required this.topicProgress,
  });

  factory StudyStatistics.fromHistory({
    required List<QuizAttempt> history,
    required List<Question> bank,
    int recentLimit = 7,
  }) {
    var totalQuestions = 0;
    var correct = 0;
    var wrong = 0;
    var skipped = 0;
    final correctByTopic = <int, int>{};
    final wrongByTopic = <int, int>{};
    final skippedByTopic = <int, int>{};
    final questionById = {for (final question in bank) question.id: question};

    for (final attempt in history) {
      totalQuestions += attempt.totalQuestions;
      correct += attempt.correct;
      wrong += attempt.wrong;
      skipped += attempt.skipped;

      var mappedQuestions = 0;
      for (final id in attempt.questionIds.toSet()) {
        final question = questionById[id];
        if (question == null) continue;
        mappedQuestions++;
        final answer = attempt.answers[id];
        if (answer == null) {
          skippedByTopic.update(
            question.topic,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        } else if (answer == question.correctId) {
          correctByTopic.update(
            question.topic,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        } else {
          wrongByTopic.update(
            question.topic,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }

      // Older/synthetic history may not contain question IDs. Keep its topic
      // summary useful when the entire attempt belongs to one known topic.
      if (mappedQuestions == 0 && attempt.topic > 0) {
        correctByTopic.update(
          attempt.topic,
          (count) => count + attempt.correct,
          ifAbsent: () => attempt.correct,
        );
        wrongByTopic.update(
          attempt.topic,
          (count) => count + attempt.wrong,
          ifAbsent: () => attempt.wrong,
        );
        skippedByTopic.update(
          attempt.topic,
          (count) => count + attempt.skipped,
          ifAbsent: () => attempt.skipped,
        );
      }
    }

    final topicIds = {
      ...correctByTopic.keys,
      ...wrongByTopic.keys,
      ...skippedByTopic.keys,
    };
    final topicProgress =
        [
          for (final topic in topicIds)
            TopicProgress(
              topic: topic,
              correct: correctByTopic[topic] ?? 0,
              wrong: wrongByTopic[topic] ?? 0,
              skipped: skippedByTopic[topic] ?? 0,
            ),
        ]..sort((a, b) {
          final accuracyOrder = a.scorePercent.compareTo(b.scorePercent);
          return accuracyOrder != 0
              ? accuracyOrder
              : b.totalQuestions.compareTo(a.totalQuestions);
        });

    final sortedHistory = [...history]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final recentAttempts = sortedHistory.length <= recentLimit
        ? sortedHistory
        : sortedHistory.sublist(sortedHistory.length - recentLimit);

    return StudyStatistics._(
      attemptCount: history.length,
      totalQuestions: totalQuestions,
      correct: correct,
      wrong: wrong,
      skipped: skipped,
      recentAttempts: List.unmodifiable(recentAttempts),
      topicProgress: List.unmodifiable(topicProgress),
    );
  }

  final int attemptCount;
  final int totalQuestions;
  final int correct;
  final int wrong;
  final int skipped;
  final List<QuizAttempt> recentAttempts;
  final List<TopicProgress> topicProgress;

  int get scorePercent =>
      totalQuestions == 0 ? 0 : (correct * 100 / totalQuestions).round();
}

/// Kết quả gộp của một chủ đề; câu bỏ trống vẫn tính trong tổng câu được hỏi.
class TopicProgress {
  const TopicProgress({
    required this.topic,
    required this.correct,
    required this.wrong,
    required this.skipped,
  });

  final int topic;
  final int correct;
  final int wrong;
  final int skipped;

  int get totalQuestions => correct + wrong + skipped;
  int get scorePercent =>
      totalQuestions == 0 ? 0 : (correct * 100 / totalQuestions).round();
}
