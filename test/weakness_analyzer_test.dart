import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/app_strings.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/quiz_attempt.dart';
import 'package:flutter_quiz_app/reminder_service.dart';
import 'package:flutter_quiz_app/today_overview.dart';
import 'package:flutter_quiz_app/weakness_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Question makeQuestion(int id, int topic, {String correct = 'A'}) {
    return Question.fromJson({
      'id': id,
      'topic': topic,
      'level': 'medium',
      'question_vi': 'Câu hỏi $id',
      'question_en': 'Question $id',
      'explanation_vi': 'Giải thích $id',
      'explanation_en': 'Explanation $id',
      'correct_answer': correct,
      'options': [
        {'id': 'A', 'vi': 'Đáp án A', 'en': 'Option A'},
        {'id': 'B', 'vi': 'Đáp án B', 'en': 'Option B'},
        {'id': 'C', 'vi': 'Đáp án C', 'en': 'Option C'},
        {'id': 'D', 'vi': 'Đáp án D', 'en': 'Option D'},
      ],
    });
  }

  group('Kiểm thử WeaknessAnalyzer phân tích năng lực', () {
    final q1 = makeQuestion(1, 1); // Topic 1
    final q2 = makeQuestion(2, 1); // Topic 1
    final q3 = makeQuestion(3, 1); // Topic 1
    final q4 = makeQuestion(4, 2); // Topic 2
    final q5 = makeQuestion(5, 2); // Topic 2
    final q6 = makeQuestion(6, 3); // Topic 3

    final bank = [q1, q2, q3, q4, q5, q6];

    test('Xử lý khi chưa có lịch sử (Empty history)', () {
      final analysis = WeaknessAnalyzer.analyze(
        history: const [],
        bank: bank,
        flashcards: const [],
      );

      expect(analysis.hasEnoughData, isFalse);
      expect(analysis.totalQuestionsAttempted, 0);
      expect(analysis.topicStats.length, 20);

      // Sinh đề thích ứng khi chưa có lịch sử vẫn an toàn bốc đủ câu
      final adaptive = WeaknessAnalyzer.selectAdaptiveQuestions(
        analysis: analysis,
        bank: bank,
        history: const [],
        count: 3,
        random: Random(1),
      );
      expect(adaptive, hasLength(3));
      expect(adaptive.map((q) => q.id).toSet().length, 3);
    });

    test('Xếp hạng chính xác khối yếu nhất dựa trên tỷ lệ sai', () {
      // Giả lập lịch sử:
      // - Topic 1: làm 3 câu, sai cả 3 (q1, q2, q3) -> độ chính xác 0%
      // - Topic 2: làm 2 câu, đúng cả 2 (q4, q5) -> độ chính xác 100%
      final attempt = QuizAttempt(
        id: 'att_1',
        timestamp: DateTime(2026, 11, 23),
        isExam: false,
        topic: 0,
        totalQuestions: 5,
        correct: 2,
        wrong: 3,
        skipped: 0,
        durationSeconds: 100,
        answers: {
          1: 'B', // Sai (đáp án đúng là A)
          2: 'C', // Sai
          3: 'D', // Sai
          4: 'A', // Đúng
          5: 'A', // Đúng
        },
        questionIds: [1, 2, 3, 4, 5],
      );

      final analysis = WeaknessAnalyzer.analyze(
        history: [attempt],
        bank: bank,
        flashcards: const [],
      );

      expect(analysis.hasEnoughData, isTrue);
      expect(analysis.totalQuestionsAttempted, 5);

      final t1 = analysis.topicStats[1]!;
      expect(t1.totalAnswered, 3);
      expect(t1.correctCount, 0);
      expect(t1.wrongCount, 3);
      expect(t1.accuracyPercent, 0);
      expect(t1.isWeak, isTrue);

      final t2 = analysis.topicStats[2]!;
      expect(t2.totalAnswered, 2);
      expect(t2.correctCount, 2);
      expect(t2.accuracyPercent, 100);
      expect(t2.isWeak, isFalse);

      // Topic 1 phải đứng đầu danh sách khối yếu nhất
      expect(analysis.rankedWeakTopics.first.topic, 1);
    });

    test('Sinh đề thích ứng ưu tiên các câu từng làm sai trong khối yếu', () {
      final attempt = QuizAttempt(
        id: 'att_2',
        timestamp: DateTime(2026, 11, 23),
        isExam: false,
        topic: 0,
        totalQuestions: 4,
        correct: 1,
        wrong: 3,
        skipped: 0,
        durationSeconds: 60,
        answers: {
          1: 'B', // Sai
          2: 'C', // Sai
          3: 'A', // Đúng
          4: 'A', // Đúng
        },
        questionIds: [1, 2, 3, 4],
      );

      final analysis = WeaknessAnalyzer.analyze(history: [attempt], bank: bank);

      final adaptive = WeaknessAnalyzer.selectAdaptiveQuestions(
        analysis: analysis,
        bank: bank,
        history: [attempt],
        count: 2,
        random: Random(42),
      );

      expect(adaptive, hasLength(2));
      // Phải chứa ít nhất 1 câu mà người dùng từng làm sai
      final adaptiveIds = adaptive.map((q) => q.id).toSet();
      expect(adaptiveIds.intersection({1, 2}), isNotEmpty);
    });
  });

  group('Kiểm thử Widget TodayOverview với Card điểm yếu', () {
    testWidgets('Hiện gợi ý làm bài khi chưa có dữ liệu lịch sử', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayOverview(
              questions: const [],
              cardsFuture: Future.value(const []),
              historyFuture: Future.value(const []),
              onOpenCards: () {},
              onQuickPractice: () {},
              onExam: () {},
              onTopic: (_) {},
              onPracticeSetup: () {},
              onRetryCards: () {},
              onAdaptivePractice: () {},
              reminder: NotificationReminderService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khối cần cải thiện'), findsOneWidget);
      expect(find.text(AppStrings.vietnamese.noWeaknessHint), findsOneWidget);
    });

    testWidgets('Hiện danh sách khối yếu và nút luyện khi có lịch sử', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final q1 = makeQuestion(1, 1);
      final q2 = makeQuestion(2, 1);
      final bank = [q1, q2];

      final attempt = QuizAttempt(
        id: 'a1',
        timestamp: DateTime(2026, 11, 23),
        isExam: false,
        topic: 1,
        totalQuestions: 2,
        correct: 0,
        wrong: 2,
        skipped: 0,
        durationSeconds: 30,
        answers: {1: 'B', 2: 'B'},
        questionIds: [1, 2],
      );

      var adaptiveClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayOverview(
              questions: bank,
              cardsFuture: Future.value(const []),
              historyFuture: Future.value([attempt]),
              onOpenCards: () {},
              onQuickPractice: () {},
              onExam: () {},
              onTopic: (_) {},
              onPracticeSetup: () {},
              onRetryCards: () {},
              onAdaptivePractice: () => adaptiveClicked = true,
              reminder: NotificationReminderService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khối cần cải thiện'), findsOneWidget);
      expect(find.text('0% chính xác'), findsOneWidget);
      expect(find.text('Luyện 10 câu điểm yếu'), findsOneWidget);

      await tester.tap(find.text('Luyện 10 câu điểm yếu'));
      expect(adaptiveClicked, isTrue);
    });
  });
}
