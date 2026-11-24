import 'question.dart';

/// Đại diện cho một lượt làm bài đã hoàn thành (luyện tập hoặc thi thử).
class QuizAttempt {
  QuizAttempt({
    required this.id,
    required this.timestamp,
    required this.isExam,
    required this.topic,
    required this.totalQuestions,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.durationSeconds,
    this.expired = false,
    Map<int, String>? answers,
    List<int>? questionIds,
  }) : answers = Map.unmodifiable(answers ?? const {}),
       questionIds = List.unmodifiable(questionIds ?? const []);

  factory QuizAttempt.fromResult({
    required QuizResult result,
    required bool isExam,
    required int topic,
    required int durationSeconds,
    String? id,
    DateTime? timestamp,
  }) {
    final score = result.score;
    final now = timestamp ?? DateTime.now();
    return QuizAttempt(
      id: id ?? 'attempt_${now.millisecondsSinceEpoch}',
      timestamp: now,
      isExam: isExam,
      topic: topic,
      totalQuestions: result.items.length,
      correct: score.correct,
      wrong: score.wrong,
      skipped: score.skipped,
      durationSeconds: durationSeconds,
      expired: result.expired,
      answers: result.answers,
      questionIds: [for (final item in result.items) item.question.id],
    );
  }

  factory QuizAttempt.fromJson(Map<String, Object?> json) {
    final rawAnswers = json['answers'] as Map<String, Object?>? ?? {};
    final answers = <int, String>{
      for (final entry in rawAnswers.entries)
        int.parse(entry.key): entry.value as String,
    };
    final rawQIds = (json['questionIds'] as List<Object?>? ?? []).cast<int>();

    return QuizAttempt(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isExam: json['isExam'] as bool? ?? false,
      topic: json['topic'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int,
      correct: json['correct'] as int,
      wrong: json['wrong'] as int,
      skipped: json['skipped'] as int,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      expired: json['expired'] as bool? ?? false,
      answers: answers,
      questionIds: rawQIds,
    );
  }

  final String id;
  final DateTime timestamp;
  final bool isExam;
  final int topic; // 0: Tất cả các khối, 1..20: khối cụ thể
  final int totalQuestions;
  final int correct;
  final int wrong;
  final int skipped;
  final int durationSeconds;
  final bool expired;
  final Map<int, String> answers;
  final List<int> questionIds;

  int get percent =>
      totalQuestions == 0 ? 0 : (100 * correct / totalQuestions).round();

  Map<String, Object?> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'isExam': isExam,
    'topic': topic,
    'totalQuestions': totalQuestions,
    'correct': correct,
    'wrong': wrong,
    'skipped': skipped,
    'durationSeconds': durationSeconds,
    'expired': expired,
    'answers': {
      for (final entry in answers.entries) entry.key.toString(): entry.value,
    },
    'questionIds': questionIds,
  };
}
