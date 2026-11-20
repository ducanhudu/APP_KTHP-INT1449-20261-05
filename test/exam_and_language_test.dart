import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/main.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

List<Question> loadBank() =>
    decodeQuestions(File('assets/flutter_quiz_300.json').readAsStringSync());

/// Mở [QuizPage] qua một nút bấm để bắt được kết quả trả về khi trang đóng.
Future<QuizResult? Function()> openQuiz(
  WidgetTester tester,
  Widget Function() builder,
) async {
  QuizResult? captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              captured = await Navigator.of(
                context,
              ).push<QuizResult>(MaterialPageRoute(builder: (_) => builder()));
            },
            child: const Text('Mở bài'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở bài'));
  await tester.pumpAndSettle();
  return () => captured;
}

void main() {
  testWidgets('Hết giờ thì tự nộp bài và đánh dấu expired', (tester) async {
    final bank = loadBank();
    final items = createQuiz(bank, 3, random: Random(9));

    var now = DateTime(2026, 11, 20, 8);
    QuizResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<QuizResult>(
                  MaterialPageRoute(
                    builder: (_) => QuizPage(
                      items: items,
                      language: QuestionLanguage.vietnamese,
                      timed: true,
                      onLanguageChanged: (_) {},
                      examDuration: const Duration(minutes: 1),
                      clock: () => now,
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
    expect(find.text('01:00'), findsOneWidget);
    expect(find.text('Thi thử'), findsOneWidget);

    // Vượt quá hạn nộp: đồng hồ nhảy 2 phút, timer 250ms sẽ gọi _tick.
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      result,
      isNotNull,
      reason: 'hết giờ phải tự nộp, không chờ người dùng',
    );
    expect(result!.expired, isTrue);
    expect(result!.items, hasLength(3));
    expect(result!.answers, isEmpty, reason: 'chưa chọn đáp án nào');
    expect(
      find.text('Mở bài'),
      findsOneWidget,
      reason: 'phải quay về màn trước',
    );
  });

  testWidgets('Đổi ngôn ngữ giữa bài không làm mất đáp án đã chọn', (
    tester,
  ) async {
    final bank = loadBank();
    final items = createQuiz(bank, 3, random: Random(4));

    final resultOf = await openQuiz(
      tester,
      () => QuizPage(
        items: items,
        language: QuestionLanguage.vietnamese,
        timed: false,
        onLanguageChanged: (_) {},
      ),
    );

    // Chọn đáp án A của câu 1.
    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pumpAndSettle();
    expect(find.text('Câu 1/3 · Đã chọn 1'), findsOneWidget);

    // Đổi sang English ngay giữa bài.
    await tester.tap(find.byTooltip('Ngôn ngữ câu hỏi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(find.text('Question 1/3 · Answered 1'), findsOneWidget);
    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(
      chips.where((chip) => chip.selected).length,
      1,
      reason: 'đáp án đã chọn vẫn phải ở trạng thái chọn sau khi đổi ngôn ngữ',
    );

    // Nộp bài: đáp án vẫn được tính theo mã lựa chọn.
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    final result = resultOf();
    expect(result, isNotNull);
    expect(
      result!.answers[items.first.question.id],
      items.first.choices.first.id,
    );
  });
}
