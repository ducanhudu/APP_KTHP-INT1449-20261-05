import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/error_state.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/sm2.dart';
import 'package:flutter_quiz_app/today_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_reminder_service.dart';

List<Question> loadBank() =>
    decodeQuestions(File('assets/flutter_quiz_300.json').readAsStringSync());

void main() {
  testWidgets('ErrorState luôn có lối ra: bấm "Thử lại" gọi callback', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorState(
            message: 'Không đọc được ngân hàng câu hỏi.',
            onRetry: () => retried++,
          ),
        ),
      ),
    );

    expect(find.text('Không đọc được ngân hàng câu hỏi.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(retried, 1);
  });

  testWidgets('TodayOverview hiện nút thử lại khi đọc bộ thẻ thất bại', (
    tester,
  ) async {
    final completer = Completer<List<Sm2Item>>();
    var retried = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayOverview(
            questions: loadBank(),
            cardsFuture: completer.future,
            onOpenCards: () {},
            onQuickPractice: () {},
            onExam: () {},
            onTopic: (_) {},
            onPracticeSetup: () {},
            onRetryCards: () => retried++,
            reminder: FakeReminderService(),
          ),
        ),
      ),
    );
    await tester.pump();

    completer.completeError(StateError('không đọc được thẻ'));
    await tester.pump();
    await tester.pump();

    final retry = find.textContaining('Thử lại');
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pump();
    expect(retried, 1);
  });
}
