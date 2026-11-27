import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/app_strings.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/quiz_attempt.dart';
import 'package:flutter_quiz_app/sm2.dart';
import 'package:flutter_quiz_app/today_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_reminder_service.dart';

void main() {
  final bank = decodeQuestions(
    File('assets/flutter_quiz_300.json').readAsStringSync(),
  );
  final perfect = QuizAttempt(
    id: 'perfect',
    timestamp: DateTime(2026, 11, 28),
    isExam: false,
    topic: bank.first.topic,
    totalQuestions: 1,
    correct: 1,
    wrong: 0,
    skipped: 0,
    durationSeconds: 10,
    questionIds: [bank.first.id],
    answers: {bank.first.id: bank.first.correctId},
  );

  Widget overview({
    required Future<List<Sm2Item>> cards,
    required Future<List<QuizAttempt>> history,
    QuestionLanguage language = QuestionLanguage.vietnamese,
    VoidCallback? onRetry,
  }) => MaterialApp(
    home: Scaffold(
      body: TodayOverview(
        questions: bank,
        cardsFuture: cards,
        historyFuture: history,
        onOpenCards: () {},
        onQuickPractice: () {},
        onExam: () {},
        onTopic: (_) {},
        onPracticeSetup: () {},
        onRetryCards: onRetry ?? () {},
        onAdaptivePractice: () {},
        reminder: FakeReminderService(),
        language: language,
      ),
    ),
  );

  Future<void> open(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Wait for cards before declaring there are no weak topics', (
    tester,
  ) async {
    final cards = Completer<List<Sm2Item>>();
    await open(
      tester,
      overview(cards: cards.future, history: Future.value([perfect])),
    );
    expect(find.text(AppStrings.vietnamese.noWeaknessFound), findsNothing);
    expect(find.text(AppStrings.vietnamese.noWeaknessHint), findsNothing);
    cards.complete([]);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.vietnamese.noWeaknessFound), findsOneWidget);
  });

  testWidgets('Wait for history before interpreting due cards', (tester) async {
    final history = Completer<List<QuizAttempt>>();
    final due = [
      for (final q in bank.take(2))
        Sm2Item.initial(questionId: q.id, now: DateTime(2020)),
    ];
    await open(
      tester,
      overview(cards: Future.value(due), history: history.future),
    );
    expect(find.text(AppStrings.vietnamese.weakTopicBadge), findsNothing);
    expect(find.text(AppStrings.vietnamese.noWeaknessFound), findsNothing);
    history.complete([]);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.vietnamese.weakTopicBadge), findsOneWidget);
  });

  for (final language in [
    QuestionLanguage.vietnamese,
    QuestionLanguage.english,
  ]) {
    final strings = AppStrings.of(language);
    testWidgets('Card read errors can be retried in ${language.name}', (
      tester,
    ) async {
      final cards = Completer<List<Sm2Item>>();
      Future<List<Sm2Item>> cardsFuture = cards.future;
      final history = Future.value([perfect]);
      var retries = 0;
      await open(
        tester,
        StatefulBuilder(
          builder: (context, setState) => overview(
            cards: cardsFuture,
            history: history,
            language: language,
            onRetry: () {
              retries++;
              setState(() {
                cardsFuture = Future.value([]);
              });
            },
          ),
        ),
      );
      cards.completeError(StateError('Cards unavailable'));
      await tester.pumpAndSettle();
      expect(find.text(strings.noWeaknessFound), findsNothing);
      expect(find.text(strings.retry), findsOneWidget);
      await tester.tap(find.text(strings.retry));
      await tester.pumpAndSettle();
      expect(retries, 1);
      expect(find.text(strings.noWeaknessFound), findsOneWidget);
    });

    testWidgets(
      'One due card without a quiz stays neutral in ${language.name}',
      (tester) async {
        await open(
          tester,
          overview(
            cards: Future.value([
              Sm2Item.initial(questionId: bank.first.id, now: DateTime(2020)),
            ]),
            history: Future.value([]),
            language: language,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(strings.noWeaknessFound), findsNothing);
        expect(find.text(strings.noWeaknessHint), findsOneWidget);
      },
    );
  }

  testWidgets('Refreshing cards hides the previous no-weakness verdict', (
    tester,
  ) async {
    Future<List<Sm2Item>> cards = Future.value([]);
    final history = Future.value([perfect]);
    late StateSetter rebuild;
    await open(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return overview(cards: cards, history: history);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.vietnamese.noWeaknessFound), findsOneWidget);
    final refreshed = Completer<List<Sm2Item>>();
    rebuild(() {
      cards = refreshed.future;
    });
    await tester.pump();
    expect(find.text(AppStrings.vietnamese.noWeaknessFound), findsNothing);
    refreshed.complete([]);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.vietnamese.noWeaknessFound), findsOneWidget);
  });
}
