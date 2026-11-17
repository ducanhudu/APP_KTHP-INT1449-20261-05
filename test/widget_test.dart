import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/main.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'The real bank supports a unique 50-question exam and scoring by ID',
    () {
      final bank = decodeQuestions(
        File('assets/flutter_quiz_300.json').readAsStringSync(),
      );
      expect(bank, hasLength(300));
      expect(bank.map((question) => question.topic).toSet(), hasLength(20));
      final exam = createQuiz(bank, 50, random: Random(23));
      expect(exam.map((item) => item.question.id).toSet(), hasLength(50));

      final first = exam[0].question;
      final second = exam[1].question;
      final result = QuizResult(exam, {
        first.id: first.correctId,
        second.id: exam[1].choices
            .firstWhere((choice) => choice.id != second.correctId)
            .id,
      });
      expect(result.score.correct, 1);
      expect(result.score.wrong, 1);
      expect(result.score.skipped, 48);
      expect(result.wrongQuestions.single.id, second.id);
      expect(
        result.byTopic.values.fold(0, (sum, score) => sum + score.total),
        50,
      );
    },
  );

  testWidgets('Practice submits answers by ID and preserves unanswered items', (
    tester,
  ) async {
    final bank = decodeQuestions(
      File('assets/flutter_quiz_300.json').readAsStringSync(),
    );
    final items = createQuiz(bank, 5, random: Random(23));
    QuizResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<QuizResult>(
                  MaterialPageRoute(
                    builder: (_) => QuizPage(
                      items: items,
                      language: QuestionLanguage.vietnamese,
                      timed: false,
                      onLanguageChanged: (_) {},
                    ),
                  ),
                );
              },
              child: const Text('Mở bài'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở bài'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nộp bài'));
    await tester.pumpAndSettle();
    expect(
      result!.answers[items.first.question.id],
      items.first.choices.first.id,
    );
    expect(result!.score.skipped, 4);
  });
}
