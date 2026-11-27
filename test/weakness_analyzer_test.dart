import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/app_strings.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/quiz_attempt.dart';
import 'package:flutter_quiz_app/reminder_service.dart';
import 'package:flutter_quiz_app/sm2.dart';
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

    test('Khối chỉ có 1 thẻ ghi nhớ (chưa làm quiz) không bị xếp yếu hơn khối làm sai nhiều', () {
      final attempt = QuizAttempt(
        id: 'att_quiz_vs_card',
        timestamp: DateTime(2026, 11, 27),
        isExam: false,
        topic: 1,
        totalQuestions: 3,
        correct: 1,
        wrong: 2,
        skipped: 0,
        durationSeconds: 45,
        answers: {1: 'A', 2: 'B', 3: 'C'},
        questionIds: [1, 2, 3],
      );
      // Topic 3 chỉ có 1 thẻ đến hạn ôn, chưa làm câu quiz nào.
      final dueCardTopic3 = Sm2Item.initial(
        questionId: 6,
        now: DateTime(2020, 1, 1),
      );

      final analysis = WeaknessAnalyzer.analyze(
        history: [attempt],
        bank: bank,
        flashcards: [dueCardTopic3],
      );

      expect(
        analysis.topicStats[1]!.weaknessScore,
        greaterThan(analysis.topicStats[3]!.weaknessScore),
      );
      expect(analysis.rankedWeakTopics.map((t) => t.topic), [1]);
    });

    test('Đạt 100% ở tất cả khối đã làm: rankedWeakTopics rỗng, không gắn nhãn yếu', () {
      final attempt = QuizAttempt(
        id: 'att_100',
        timestamp: DateTime(2026, 11, 27),
        isExam: false,
        topic: 2,
        totalQuestions: 2,
        correct: 2,
        wrong: 0,
        skipped: 0,
        durationSeconds: 30,
        answers: {4: 'A', 5: 'A'},
        questionIds: [4, 5],
      );

      final analysis = WeaknessAnalyzer.analyze(
        history: [attempt],
        bank: bank,
        flashcards: const [],
      );

      expect(analysis.hasEnoughData, isTrue);
      expect(analysis.rankedWeakTopics, isEmpty);
    });

    test(
      'selectAdaptiveQuestions chỉ ưu tiên câu sai theo kết quả gần nhất',
      () {
        final oldAttempt = QuizAttempt(
          id: 'old',
          timestamp: DateTime(2026, 11, 20),
          isExam: false,
          topic: 1,
          totalQuestions: 2,
          correct: 0,
          wrong: 2,
          skipped: 0,
          durationSeconds: 30,
          answers: {1: 'B', 2: 'B'}, // Cả q1 và q2 từng sai
          questionIds: [1, 2],
        );
        final newerAttempt = QuizAttempt(
          id: 'new',
          timestamp: DateTime(2026, 11, 27),
          isExam: false,
          topic: 1,
          totalQuestions: 2,
          correct: 1,
          wrong: 1,
          skipped: 0,
          durationSeconds: 30,
          answers: {
            1: 'A',
            2: 'C',
          }, // q1 đã làm đúng ở lượt gần nhất, q2 vẫn sai
          questionIds: [1, 2],
        );

        final analysis = WeaknessAnalyzer.analyze(
          history: [newerAttempt, oldAttempt],
          bank: bank,
        );

        final adaptive = WeaknessAnalyzer.selectAdaptiveQuestions(
          analysis: analysis,
          bank: [q1, q2],
          history: [
            oldAttempt,
            newerAttempt,
          ], // Cố tình truyền không theo thứ tự
          count: 1,
          random: Random(1),
        );

        expect(adaptive.single.id, 2);
      },
    );

    test('Bỏ qua thẻ đã thuộc (chưa đến hạn) và câu bỏ trống khi tính hasEnoughData', () {
      final blankAttempt = QuizAttempt(
        id: 'blank',
        timestamp: DateTime(2026, 11, 27),
        isExam: false,
        topic: 1,
        totalQuestions: 2,
        correct: 0,
        wrong: 0,
        skipped: 2,
        durationSeconds: 10,
        answers: const {},
        questionIds: [1, 2],
      );
      final futureCard = Sm2Item(
        questionId: 6,
        repetitions: 3,
        interval: 10,
        easeFactor: 2.5,
        nextReviewDate: DateTime(2099, 1, 1),
      );

      final analysis = WeaknessAnalyzer.analyze(
        history: [blankAttempt],
        bank: bank,
        flashcards: [futureCard],
      );

      expect(analysis.totalQuestionsAttempted, 0);
      expect(analysis.topicStats[1]!.skippedCount, 2);
      expect(analysis.topicStats[3]!.cardCount, 0);
      expect(analysis.hasEnoughData, isFalse);
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

    testWidgets(
      'Hiện thông báo tích cực khi đã làm bài đạt 100% và không có khối yếu',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final q1 = makeQuestion(1, 1);
        final q2 = makeQuestion(2, 1);
        final attempt = QuizAttempt(
          id: 'perfect_1',
          timestamp: DateTime(2026, 11, 27),
          isExam: false,
          topic: 1,
          totalQuestions: 2,
          correct: 2,
          wrong: 0,
          skipped: 0,
          durationSeconds: 20,
          answers: {1: 'A', 2: 'A'},
          questionIds: [1, 2],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodayOverview(
                questions: [q1, q2],
                cardsFuture: Future.value(const []),
                historyFuture: Future.value([attempt]),
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

        expect(
          find.text(AppStrings.vietnamese.noWeaknessFound),
          findsOneWidget,
        );
        expect(find.text(AppStrings.vietnamese.weakTopicBadge), findsNothing);
      },
    );

    testWidgets(
      'Không lặp nhãn khi khối yếu chỉ có thẻ đến hạn (hiển thị số thẻ đến hạn)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final q1 = makeQuestion(1, 1);
        final q2 = makeQuestion(2, 1);
        final due1 = Sm2Item.initial(questionId: 1, now: DateTime(2020, 1, 1));
        final due2 = Sm2Item.initial(questionId: 2, now: DateTime(2020, 1, 1));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodayOverview(
                questions: [q1, q2],
                cardsFuture: Future.value([due1, due2]),
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

        expect(find.text('2 thẻ đến hạn cần ôn'), findsOneWidget);
        expect(find.text('Cần củng cố'), findsOneWidget);
      },
    );

    testWidgets(
      'Hiện thông báo lỗi kèm nút Thử lại khi đọc historyFuture thất bại',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        var retried = false;
        final completer = Completer<List<QuizAttempt>>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TodayOverview(
                questions: const [],
                cardsFuture: Future.value(const []),
                historyFuture: completer.future,
                onOpenCards: () {},
                onQuickPractice: () {},
                onExam: () {},
                onTopic: (_) {},
                onPracticeSetup: () {},
                onRetryCards: () => retried = true,
                onAdaptivePractice: () {},
                reminder: NotificationReminderService(),
              ),
            ),
          ),
        );
        completer.completeError(StateError('Read failure'));
        await tester.pumpAndSettle();

        expect(
          find.text(AppStrings.vietnamese.errorHistoryLoad),
          findsOneWidget,
        );
        expect(find.text(AppStrings.vietnamese.retry), findsOneWidget);

        await tester.tap(find.text(AppStrings.vietnamese.retry));
        expect(retried, isTrue);
      },
    );
  });
}
