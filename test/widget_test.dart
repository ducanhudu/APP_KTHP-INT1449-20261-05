import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/card_storage.dart';
import 'package:flutter_quiz_app/flashcard_page.dart';
import 'package:flutter_quiz_app/main.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Reject missing bilingual content, duplicate IDs and invalid answers',
    () {
      final source = File('assets/flutter_quiz_300.json').readAsStringSync();
      final invalidCases = <void Function(List<dynamic>)>[
        (rows) => rows.removeLast(),
        (rows) => rows[1]['id'] = rows[0]['id'],
        (rows) => rows[0]['question_en'] = '  ',
        (rows) => rows[0]['question_vi'] = '',
        (rows) => rows[0]['explanation_en'] = '',
        (rows) => rows[0]['options'][0]['vi'] = '',
        (rows) => rows[0]['options'][0]['en'] = ' ',
        (rows) => rows[0]['options'][0]['id'] = rows[0]['options'][1]['id'],
        (rows) => rows[0]['correct_answer'] = 'missing',
      ];
      for (final change in invalidCases) {
        final rows = jsonDecode(source) as List<dynamic>;
        change(rows);
        expect(() => decodeQuestions(jsonEncode(rows)), throwsFormatException);
      }
    },
  );

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
    final items = createQuiz(bank, 3, random: Random(23));
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
    await tester.tap(find.byType(QuizOptionTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nộp bài'));
    await tester.pumpAndSettle();
    expect(
      result!.answers[items.first.question.id],
      items.first.choices.first.id,
    );
    expect(result!.items, hasLength(3));
    expect(result!.score.skipped, 2);
  });

  testWidgets(
    'ResultPage saves wrong questions to storage and shows Flashcard entry',
    (tester) async {
      final bank = decodeQuestions(
        File('assets/flutter_quiz_300.json').readAsStringSync(),
      );
      final storage = MemoryCardStorage();
      final items = createQuiz(bank, 3, random: Random(23));

      // Giả lập câu trả lời: câu đầu trả lời sai, 2 câu sau bỏ trống
      final first = items.first.question;
      final wrongChoice = items.first.choices.firstWhere(
        (c) => c.id != first.correctId,
      );
      final answers = <int, String>{first.id: wrongChoice.id};
      final quizResult = QuizResult(items, answers);

      await tester.pumpWidget(
        MaterialApp(
          home: ResultPage(
            result: quizResult,
            language: QuestionLanguage.vietnamese,
            storage: storage,
          ),
        ),
      );

      // Kiểm tra nút "Lưu 1 câu sai vào thẻ" hiện đúng số
      expect(find.text('Lưu 1 câu sai vào thẻ'), findsOneWidget);
      await tester.tap(find.text('Lưu 1 câu sai vào thẻ'));
      await tester.pumpAndSettle();

      // Xác nhận đã lưu đúng 1 thẻ vào storage với ID câu sai
      final cards = await storage.loadCards();
      expect(cards, hasLength(1));
      expect(cards.first.questionId, first.id);
      expect(cards.first.repetitions, 0);
      expect(cards.first.isDue(), isTrue);

      // Mở màn hình FlashcardPage với storage vừa lưu, kiểm tra hiện thẻ
      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardPage(
            allQuestions: bank,
            storage: storage,
            language: QuestionLanguage.vietnamese,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Thấy thẻ 1/1 và nút xem đáp án
      expect(find.text('Thẻ 1/1'), findsOneWidget);
      expect(find.text('Xem đáp án & giải thích'), findsOneWidget);
    },
  );
  test('Sample result creates exact 1 correct, 1 wrong, 1 skipped run', () {
    final bank = decodeQuestions(
      File('assets/flutter_quiz_300.json').readAsStringSync(),
    );
    final sample = createSampleResult(bank);
    expect(sample.items, hasLength(3));
    expect(sample.score.correct, 1);
    expect(sample.score.wrong, 1);
    expect(sample.score.skipped, 1);
    expect(sample.score.total, 3);
    expect(sample.score.percent, 33);
  });

  test(
    'QuestionCard stores questionId and resolves original question from bank',
    () {
      final bank = decodeQuestions(
        File('assets/flutter_quiz_300.json').readAsStringSync(),
      );
      final targetQuestion = bank[5];
      final card = QuestionCard(
        id: 'card_5',
        questionId: targetQuestion.id,
        note: 'Thẻ ôn tập mẫu',
      );

      expect(card.questionId, targetQuestion.id);
      final resolvedQuestion = card.resolve(bank);
      expect(resolvedQuestion, isNotNull);
      expect(resolvedQuestion!.id, targetQuestion.id);
      expect(resolvedQuestion.vi, targetQuestion.vi);
    },
  );
}
