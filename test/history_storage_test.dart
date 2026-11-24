import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/history_page.dart';
import 'package:flutter_quiz_app/history_storage.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/quiz_attempt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kiểm thử QuizAttempt model & JSON', () {
    test('toJson và fromJson bảo toàn dữ liệu', () {
      final now = DateTime(2026, 11, 23, 20, 30);
      final attempt = QuizAttempt(
        id: 'attempt_1',
        timestamp: now,
        isExam: true,
        topic: 1,
        totalQuestions: 10,
        correct: 8,
        wrong: 1,
        skipped: 1,
        durationSeconds: 150,
        expired: false,
        answers: {1: 'A', 2: 'B'},
        questionIds: [1, 2, 3],
      );

      expect(attempt.percent, 80);

      final json = attempt.toJson();
      final restored = QuizAttempt.fromJson(json);

      expect(restored.id, 'attempt_1');
      expect(restored.timestamp, now);
      expect(restored.isExam, isTrue);
      expect(restored.topic, 1);
      expect(restored.totalQuestions, 10);
      expect(restored.correct, 8);
      expect(restored.wrong, 1);
      expect(restored.skipped, 1);
      expect(restored.durationSeconds, 150);
      expect(restored.expired, isFalse);
      expect(restored.answers[1], 'A');
      expect(restored.answers[2], 'B');
      expect(restored.questionIds, [1, 2, 3]);
    });

    test('QuizAttempt.fromResult tính đúng tỷ lệ và sao chép kết quả', () {
      final q1 = Question.fromJson({
        'id': 10,
        'topic': 2,
        'level': 'easy',
        'question_vi': 'Q10 vi',
        'question_en': 'Q10 en',
        'explanation_vi': 'exp vi',
        'explanation_en': 'exp en',
        'correct_answer': 'A',
        'options': [
          {'id': 'A', 'vi': 'A vi', 'en': 'A en'},
          {'id': 'B', 'vi': 'B vi', 'en': 'B en'},
          {'id': 'C', 'vi': 'C vi', 'en': 'C en'},
          {'id': 'D', 'vi': 'D vi', 'en': 'D en'},
        ],
      });

      final items = [QuizItem(q1, Random(1))];
      final result = QuizResult(items, {10: 'A'}, expired: false);

      final attempt = QuizAttempt.fromResult(
        result: result,
        isExam: false,
        topic: 2,
        durationSeconds: 45,
      );

      expect(attempt.totalQuestions, 1);
      expect(attempt.correct, 1);
      expect(attempt.wrong, 0);
      expect(attempt.skipped, 0);
      expect(attempt.percent, 100);
      expect(attempt.durationSeconds, 45);
      expect(attempt.isExam, isFalse);
      expect(attempt.topic, 2);
    });
  });

  group('Kiểm thử MemoryHistoryStorage', () {
    test('Lưu, tải và sắp xếp mới nhất lên đầu', () async {
      final storage = MemoryHistoryStorage();
      expect(await storage.loadHistory(), isEmpty);

      final a1 = QuizAttempt(
        id: 'a1',
        timestamp: DateTime(2026, 11, 20),
        isExam: false,
        topic: 0,
        totalQuestions: 5,
        correct: 3,
        wrong: 2,
        skipped: 0,
        durationSeconds: 60,
      );

      final a2 = QuizAttempt(
        id: 'a2',
        timestamp: DateTime(2026, 11, 22),
        isExam: true,
        topic: 0,
        totalQuestions: 50,
        correct: 40,
        wrong: 5,
        skipped: 5,
        durationSeconds: 1800,
      );

      await storage.saveAttempt(a1);
      await storage.saveAttempt(a2);

      final list = await storage.loadHistory();
      expect(list, hasLength(2));
      expect(list.first.id, 'a2'); // a2 mới hơn nên đứng đầu
      expect(list.last.id, 'a1');

      // Xóa 1 bản ghi
      await storage.deleteAttempt('a1');
      final afterDelete = await storage.loadHistory();
      expect(afterDelete, hasLength(1));
      expect(afterDelete.single.id, 'a2');

      // Xóa sạch
      await storage.clearHistory();
      expect(await storage.loadHistory(), isEmpty);
    });
  });

  group('Kiểm thử giao diện HistoryPage', () {
    testWidgets('Hiện trạng thái rỗng khi chưa có lịch sử', (tester) async {
      final storage = MemoryHistoryStorage();

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryPage(
            historyStorage: storage,
            allQuestions: const [],
            language: QuestionLanguage.vietnamese,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử làm bài'), findsOneWidget);
      expect(find.text('Chưa có lượt làm bài nào.'), findsOneWidget);
    });

    testWidgets('Hiện danh sách lượt làm bài và lọc theo tab', (tester) async {
      final storage = MemoryHistoryStorage([
        QuizAttempt(
          id: 'p1',
          timestamp: DateTime(2026, 11, 23, 10, 0),
          isExam: false,
          topic: 1,
          totalQuestions: 10,
          correct: 8,
          wrong: 2,
          skipped: 0,
          durationSeconds: 120,
        ),
        QuizAttempt(
          id: 'e1',
          timestamp: DateTime(2026, 11, 23, 11, 0),
          isExam: true,
          topic: 0,
          totalQuestions: 50,
          correct: 35,
          wrong: 10,
          skipped: 5,
          durationSeconds: 2400,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryPage(
            historyStorage: storage,
            allQuestions: const [],
            language: QuestionLanguage.vietnamese,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mặc định tab Tất cả: hiện cả 2 thẻ
      expect(find.text('Luyện tập'), findsWidgets);
      expect(find.text('Thi thử'), findsWidgets);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);

      // Chuyển sang lọc Thi thử
      await tester.tap(find.widgetWithText(ChoiceChip, 'Thi thử'));
      await tester.pumpAndSettle();
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('80%'), findsNothing);

      // Chuyển sang lọc Luyện tập
      await tester.tap(find.widgetWithText(ChoiceChip, 'Luyện tập'));
      await tester.pumpAndSettle();
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('70%'), findsNothing);

      // Bấm nút xóa tất cả lịch sử trên AppBar
      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Xoá lịch sử làm bài?'), findsOneWidget);
      await tester.tap(find.text('Xoá lịch sử'));
      await tester.pumpAndSettle();

      expect(await storage.loadHistory(), isEmpty);
      expect(find.text('Chưa có lượt làm bài nào.'), findsOneWidget);
    });

    testWidgets('Giao diện tiếng Anh hiển thị nhãn chuẩn English', (
      tester,
    ) async {
      final storage = MemoryHistoryStorage();

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryPage(
            historyStorage: storage,
            allQuestions: const [],
            language: QuestionLanguage.english,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quiz History'), findsOneWidget);
      expect(find.text('No quiz history yet.'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Exam'), findsOneWidget);
    });
  });
}
