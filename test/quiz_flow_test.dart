import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/card_storage.dart';
import 'package:flutter_quiz_app/main.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

List<Question> loadBank() =>
    decodeQuestions(File('assets/flutter_quiz_300.json').readAsStringSync());

void main() {
  test(
    'Xáo trộn lựa chọn: cùng một câu, seed khác nhau cho thứ tự khác nhau',
    () {
      final bank = loadBank();
      final question = bank.first;
      final orders = <List<String>>{};

      for (var seed = 0; seed < 12; seed++) {
        final item = QuizItem(question, Random(seed));
        final ids = item.choices.map((choice) => choice.id).toList();
        expect(ids.toSet(), {'A', 'B', 'C', 'D'}, reason: 'seed $seed');

        final shuffledCorrect = item.choices.firstWhere(
          (choice) => choice.id == question.correctId,
        );
        final originalCorrect = question.choices.firstWhere(
          (choice) => choice.id == question.correctId,
        );
        expect(shuffledCorrect.vi, originalCorrect.vi);
        expect(shuffledCorrect.en, originalCorrect.en);

        orders.add(ids);
      }

      expect(
        orders.length,
        greaterThan(1),
        reason: '12 seed phải sinh ra ít nhất hai thứ tự lựa chọn khác nhau',
      );
      expect(question.choices.map((choice) => choice.id).toList(), [
        'A',
        'B',
        'C',
        'D',
      ], reason: 'danh sách lựa chọn gốc không được bị xáo trộn');
    },
  );

  test('Làm lại câu sai: chỉ gồm câu chọn sai, bỏ qua câu bỏ trống', () {
    final bank = loadBank();
    final items = createQuiz(bank, 5, random: Random(7));

    final wrongItem = items[1];
    final wrongChoiceId = wrongItem.choices
        .firstWhere((choice) => choice.id != wrongItem.question.correctId)
        .id;
    final rightItem = items[3];

    final result = QuizResult(items, <int, String>{
      wrongItem.question.id: wrongChoiceId,
      rightItem.question.id: rightItem.question.correctId,
    });

    expect(result.score.correct, 1);
    expect(result.score.wrong, 1);
    expect(result.score.skipped, 3);
    expect(result.wrongQuestions, hasLength(1));
    expect(result.wrongQuestions.single.id, wrongItem.question.id);
    expect(
      result.wrongQuestions.map((question) => question.id),
      isNot(contains(rightItem.question.id)),
    );
  });

  testWidgets('Nộp bài trắng: kết quả 0% và không hiện nút làm lại', (
    tester,
  ) async {
    final bank = loadBank();
    final items = createQuiz(bank, 3, random: Random(11));
    final result = QuizResult(items, <int, String>{});

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(result: result, language: QuestionLanguage.vietnamese),
      ),
    );

    // "0%" xuất hiện cả ở điểm tổng và ở từng dòng thống kê theo khối.
    expect(find.text('0%'), findsWidgets);
    expect(find.text('0 đúng · 0 sai · 3 bỏ trống'), findsOneWidget);
    expect(find.textContaining('Làm lại'), findsNothing);
    expect(result.wrongQuestions, isEmpty);
  });

  testWidgets('Màn hình chính đọc lại số thẻ sau khi bộ thẻ thay đổi', (
    tester,
  ) async {
    final storage = MemoryCardStorage();
    await tester.pumpWidget(MaterialApp(home: QuizHome(storage: storage)));
    // Màn hình chính có CircularProgressIndicator khi nạp ngân hàng câu hỏi nên
    // không dùng pumpAndSettle được; chờ future nạp xong bằng runAsync.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.text('0 thẻ đã lưu · 0 thẻ cần ôn hôm nay'), findsOneWidget);

    // Giả lập vừa lưu 2 câu sai thành thẻ ở màn hình kết quả.
    await storage.addCards([1, 2]);

    // Mở rồi đóng bộ thẻ: màn hình chính phải đọc lại, không hiện số cũ.
    await tester.tap(find.text('Ôn tập Flashcard (SM-2)'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pageBack();
    await tester.pump();

    // Chờ có giới hạn cho future đọc lại bộ thẻ hoàn tất.
    const expected = '2 thẻ đã lưu · 2 thẻ cần ôn hôm nay';
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(expected).evaluate().isNotEmpty) break;
    }

    expect(find.text(expected), findsOneWidget);
  });
}
