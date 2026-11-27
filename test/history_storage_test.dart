import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/card_storage.dart';
import 'package:flutter_quiz_app/error_state.dart';
import 'package:flutter_quiz_app/history_page.dart';
import 'package:flutter_quiz_app/history_storage.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/quiz_attempt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    testWidgets(
      'Bấm "Làm lại X câu sai" từ Lịch sử mở lại bài luyện tập với các câu sai',
      (tester) async {
        final q1 = Question.fromJson({
          'id': 101,
          'topic': 1,
          'level': 'easy',
          'question_vi': 'Câu 101',
          'question_en': 'Question 101',
          'explanation_vi': 'Giải thích 101',
          'explanation_en': 'Exp 101',
          'correct_answer': 'A',
          'options': [
            {'id': 'A', 'vi': 'Đúng', 'en': 'Right'},
            {'id': 'B', 'vi': 'Sai', 'en': 'Wrong'},
            {'id': 'C', 'vi': 'Khác 1', 'en': 'Other 1'},
            {'id': 'D', 'vi': 'Khác 2', 'en': 'Other 2'},
          ],
        });
        final attempt = QuizAttempt(
          id: 'retry_1',
          timestamp: DateTime(2026, 11, 27, 10, 0),
          isExam: false,
          topic: 1,
          totalQuestions: 1,
          correct: 0,
          wrong: 1,
          skipped: 0,
          durationSeconds: 30,
          answers: {101: 'B'},
          questionIds: [101],
        );
        final storage = MemoryHistoryStorage([attempt]);
        List<Question>? retriedQuestions;

        await tester.pumpWidget(
          MaterialApp(
            home: HistoryPage(
              historyStorage: storage,
              allQuestions: [q1],
              language: QuestionLanguage.vietnamese,
              onRetryWrong: (wrong) async {
                retriedQuestions = wrong;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('0%'));
        await tester.pumpAndSettle();
        expect(find.text('Làm lại 1 câu sai'), findsOneWidget);

        await tester.tap(find.text('Làm lại 1 câu sai'));
        await tester.pumpAndSettle();

        expect(retriedQuestions, isNotNull);
        expect(retriedQuestions!.map((q) => q.id), [101]);
      },
    );

    testWidgets('Hiện ErrorState và nút Thử lại khi tải lịch sử thất bại', (
      tester,
    ) async {
      final storage = _FlakyHistoryStorage();

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

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Không đọc được lịch sử làm bài.'), findsOneWidget);

      storage.shouldFail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsNothing);
      expect(find.text('Chưa có lượt làm bài nào.'), findsOneWidget);
    });

    testWidgets(
      'Chạm bản ghi không còn câu hỏi hợp lệ hiển thị SnackBar thông báo',
      (tester) async {
        final attempt = QuizAttempt(
          id: 'missing_q',
          timestamp: DateTime(2026, 11, 27, 10, 0),
          isExam: false,
          topic: 1,
          totalQuestions: 1,
          correct: 1,
          wrong: 0,
          skipped: 0,
          durationSeconds: 20,
          answers: {999: 'A'},
          questionIds: [999],
        );
        final storage = MemoryHistoryStorage([attempt]);

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

        await tester.tap(find.text('100%'));
        await tester.pump();

        expect(
          find.text('Không thể ôn lại vì câu hỏi không còn khả dụng.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Kiểm thử SharedPrefsHistoryStorage & CardStorage an toàn dữ liệu', () {
    test('Bỏ qua bản ghi JSON hỏng nhưng vẫn giữ bản ghi hợp lệ và không ghi đè mất lịch sử', () async {
      final valid = QuizAttempt(
        id: 'valid_1',
        timestamp: DateTime(2026, 11, 27, 9, 0),
        isExam: false,
        topic: 1,
        totalQuestions: 5,
        correct: 4,
        wrong: 1,
        skipped: 0,
        durationSeconds: 60,
      );
      SharedPreferences.setMockInitialValues({
        'flutter_lab_quiz_history_v1': jsonEncode([
          valid.toJson(),
          {'id': 'corrupt_missing_fields'},
          'not_even_a_map',
        ]),
      });

      const storage = SharedPrefsHistoryStorage();
      final loaded = await storage.loadHistory();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'valid_1');

      final next = QuizAttempt(
        id: 'valid_2',
        timestamp: DateTime(2026, 11, 27, 10, 0),
        isExam: true,
        topic: 0,
        totalQuestions: 10,
        correct: 9,
        wrong: 1,
        skipped: 0,
        durationSeconds: 120,
      );
      await storage.saveAttempt(next);

      final afterSave = await storage.loadHistory();
      expect(afterSave.map((a) => a.id), ['valid_2', 'valid_1']);
    });

    test('Thao tác xoá/ghi đồng thời được tuần tự hoá, không khôi phục nhầm dữ liệu', () async {
      final a1 = QuizAttempt(
        id: 'c1',
        timestamp: DateTime(2026, 11, 27, 8, 0),
        isExam: false,
        topic: 1,
        totalQuestions: 1,
        correct: 1,
        wrong: 0,
        skipped: 0,
        durationSeconds: 10,
      );
      final a2 = QuizAttempt(
        id: 'c2',
        timestamp: DateTime(2026, 11, 27, 9, 0),
        isExam: false,
        topic: 1,
        totalQuestions: 1,
        correct: 1,
        wrong: 0,
        skipped: 0,
        durationSeconds: 10,
      );
      final a3 = QuizAttempt(
        id: 'c3',
        timestamp: DateTime(2026, 11, 27, 10, 0),
        isExam: false,
        topic: 1,
        totalQuestions: 1,
        correct: 1,
        wrong: 0,
        skipped: 0,
        durationSeconds: 10,
      );

      SharedPreferences.setMockInitialValues({});
      const historyStorage = SharedPrefsHistoryStorage();
      await Future.wait([
        historyStorage.saveAttempt(a1),
        historyStorage.saveAttempt(a2),
        historyStorage.saveAttempt(a3),
      ]);
      expect((await historyStorage.loadHistory()).length, 3);

      await Future.wait([
        historyStorage.deleteAttempt('c1'),
        historyStorage.deleteAttempt('c2'),
      ]);
      final remaining = await historyStorage.loadHistory();
      expect(remaining.map((a) => a.id).toList(), ['c3']);

      const cardStorage = SharedPrefsCardStorage();
      await Future.wait([
        cardStorage.addCards([10]),
        cardStorage.addCards([20]),
        cardStorage.addCards([30]),
      ]);
      final cards = await cardStorage.loadCards();
      expect(cards.map((c) => c.questionId).toSet(), {10, 20, 30});
    });
  });
}

class _FlakyHistoryStorage implements HistoryStorage {
  bool shouldFail = true;

  @override
  Future<List<QuizAttempt>> loadHistory() async {
    if (shouldFail) throw StateError('Lỗi đọc dữ liệu');
    return const [];
  }

  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {}

  @override
  Future<void> deleteAttempt(String id) async {}

  @override
  Future<void> clearHistory() async {}
}
