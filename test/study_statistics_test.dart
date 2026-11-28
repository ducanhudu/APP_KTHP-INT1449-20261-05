import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/app_strings.dart';
import 'package:flutter_quiz_app/history_storage.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/quiz_attempt.dart';
import 'package:flutter_quiz_app/statistics_page.dart';
import 'package:flutter_quiz_app/study_statistics.dart';
import 'package:flutter_quiz_app/today_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_reminder_service.dart';

Question question({
  required int id,
  required int topic,
  String correct = 'A',
}) => Question.fromJson({
  'id': id,
  'topic': topic,
  'level': 'easy',
  'question_vi': 'Câu $id',
  'question_en': 'Question $id',
  'explanation_vi': 'Giải thích',
  'explanation_en': 'Explanation',
  'correct_answer': correct,
  'options': [
    {'id': 'A', 'vi': 'A', 'en': 'A'},
    {'id': 'B', 'vi': 'B', 'en': 'B'},
    {'id': 'C', 'vi': 'C', 'en': 'C'},
    {'id': 'D', 'vi': 'D', 'en': 'D'},
  ],
});

QuizAttempt attempt({
  required String id,
  required DateTime timestamp,
  required int total,
  required int correct,
  required int wrong,
  required int skipped,
  int topic = 0,
  List<int> questionIds = const [],
  Map<int, String> answers = const {},
}) => QuizAttempt(
  id: id,
  timestamp: timestamp,
  isExam: false,
  topic: topic,
  totalQuestions: total,
  correct: correct,
  wrong: wrong,
  skipped: skipped,
  durationSeconds: 30,
  questionIds: questionIds,
  answers: answers,
);

void main() {
  final questions = [
    question(id: 1, topic: 1),
    question(id: 2, topic: 2),
    question(id: 3, topic: 2, correct: 'B'),
  ];

  test('summarizes results by topic and orders recent attempts', () {
    final earlier = attempt(
      id: 'old',
      timestamp: DateTime(2026, 11, 20),
      total: 4,
      correct: 2,
      wrong: 1,
      skipped: 1,
      topic: 1,
    );
    final latest = attempt(
      id: 'latest',
      timestamp: DateTime(2026, 11, 28),
      total: 3,
      correct: 1,
      wrong: 1,
      skipped: 1,
      questionIds: [1, 2, 3],
      answers: {1: 'A', 2: 'B'},
    );

    final stats = StudyStatistics.fromHistory(
      history: [latest, earlier],
      bank: questions,
    );

    expect(stats.attemptCount, 2);
    expect(stats.totalQuestions, 7);
    expect(stats.correct, 3);
    expect(stats.wrong, 2);
    expect(stats.skipped, 2);
    expect(stats.scorePercent, 43);
    expect(stats.recentAttempts.map((item) => item.id), ['old', 'latest']);
    expect(stats.topicProgress.map((item) => item.topic), [2, 1]);
    expect(stats.topicProgress.first.correct, 0);
    expect(stats.topicProgress.first.wrong, 1);
    expect(stats.topicProgress.first.skipped, 1);
    expect(stats.topicProgress.first.scorePercent, 0);
  });

  test('keeps only the requested number of most recent attempts', () {
    final history = [
      for (var day = 1; day <= 9; day++)
        attempt(
          id: '$day',
          timestamp: DateTime(2026, 11, day),
          total: 1,
          correct: 1,
          wrong: 0,
          skipped: 0,
        ),
    ];
    final stats = StudyStatistics.fromHistory(
      history: history,
      bank: questions,
      recentLimit: 3,
    );
    expect(stats.recentAttempts.map((item) => item.id), ['7', '8', '9']);
  });

  testWidgets('renders score trend and topic progress', (tester) async {
    final storage = MemoryHistoryStorage([
      attempt(
        id: 'today',
        timestamp: DateTime(2026, 11, 28),
        total: 3,
        correct: 1,
        wrong: 1,
        skipped: 1,
        questionIds: [1, 2, 3],
        answers: {1: 'A', 2: 'B'},
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: StatisticsPage(
          historyStorage: storage,
          questions: questions,
          language: QuestionLanguage.vietnamese,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.vietnamese.statisticsTitle), findsOneWidget);
    expect(find.text('33%'), findsNWidgets(2));
    expect(find.text('K02 · Công cụ và môi trường'), findsOneWidget);
    expect(find.textContaining('0/2 đúng'), findsOneWidget);
  });

  testWidgets('home overview exposes the statistics screen', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayOverview(
            questions: questions,
            cardsFuture: Future.value([]),
            onOpenCards: () {},
            onQuickPractice: () {},
            onExam: () {},
            onTopic: (_) {},
            onPracticeSetup: () {},
            onRetryCards: () {},
            reminder: FakeReminderService(),
            onStatistics: () => opened = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final link = find.text(AppStrings.vietnamese.homeStatisticsTitle);
    await tester.ensureVisible(link);
    await tester.tap(link);
    expect(opened, isTrue);
  });

  testWidgets('shows empty state without attempt history', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StatisticsPage(
          historyStorage: MemoryHistoryStorage(),
          questions: questions,
          language: QuestionLanguage.english,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.english.statisticsEmpty), findsOneWidget);
  });
}
