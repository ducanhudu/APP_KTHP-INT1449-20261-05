import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quiz_app/card_storage.dart';
import 'package:flutter_quiz_app/history_page.dart';
import 'package:flutter_quiz_app/history_storage.dart';
import 'package:flutter_quiz_app/main.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/quiz_attempt.dart';
import 'package:flutter_quiz_app/today_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_reminder_service.dart';

class FailingHistory extends MemoryHistoryStorage {
  @override
  Future<void> saveAttempt(QuizAttempt attempt) async =>
      throw StateError('disk full');
}

void main() {
  setUp(() => rootBundle.evict('assets/flutter_quiz_300.json'));
  Future<void> open(WidgetTester tester, HistoryStorage storage) async {
    tester.view.physicalSize = const Size(440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      FlutterLab(
        storage: MemoryCardStorage(),
        historyStorage: storage,
        reminder: FakeReminderService(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
  }

  for (final failing in [false, true]) {
    testWidgets('Submit still shows result; history failure=$failing', (
      tester,
    ) async {
      final history = failing ? FailingHistory() : MemoryHistoryStorage();
      await open(tester, history);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 câu'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bắt đầu luyện tập'));
      await tester.tap(find.text('Bắt đầu luyện tập'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nộp bài'));
      await tester.pumpAndSettle();
      expect(find.text('Kết quả'), findsOneWidget);
      expect(find.text('0 đúng · 0 sai · 3 bỏ trống'), findsOneWidget);
      final saved = await history.loadHistory();
      expect(saved.length, failing ? 0 : 1);
      if (!failing) {
        expect(saved.single.questionIds, hasLength(3));
        expect(saved.single.skipped, 3);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Returning after clearing history refreshes weakness data', (
    tester,
  ) async {
    final history = MemoryHistoryStorage([
      QuizAttempt(
        id: 'old',
        timestamp: DateTime(2026),
        isExam: false,
        topic: 1,
        totalQuestions: 2,
        correct: 0,
        wrong: 2,
        skipped: 0,
        durationSeconds: 5,
        questionIds: [1, 2],
        answers: {1: 'D', 2: 'D'},
      ),
    ]);
    await open(tester, history);
    final before = tester.widget<TodayOverview>(find.byType(TodayOverview));
    expect(await before.historyFuture, hasLength(1));
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    final after = tester.widget<TodayOverview>(find.byType(TodayOverview));
    expect(await after.historyFuture, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('History filters fit a narrow English screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bank = decodeQuestions(
      File('assets/flutter_quiz_300.json').readAsStringSync(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryPage(
          historyStorage: MemoryHistoryStorage(),
          allQuestions: bank,
          language: QuestionLanguage.english,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('English history shows English topic names and Cancel label', (
    tester,
  ) async {
    final bank = decodeQuestions(
      File('assets/flutter_quiz_300.json').readAsStringSync(),
    );
    final history = MemoryHistoryStorage([
      QuizAttempt(
        id: 'attempt_en',
        timestamp: DateTime(2026, 11, 26, 20, 0),
        isExam: false,
        topic: 1,
        totalQuestions: 1,
        correct: 1,
        wrong: 0,
        skipped: 0,
        durationSeconds: 42,
        questionIds: [1],
        answers: {1: 'C'},
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryPage(
          historyStorage: history,
          allQuestions: bank,
          language: QuestionLanguage.english,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Tên khối phải theo ngôn ngữ nhãn, không chỉ nội dung câu hỏi.
    expect(find.textContaining('Dart basics'), findsOneWidget);
    expect(find.textContaining('Dart căn bản'), findsNothing);

    // Hộp thoại xoá lịch sử dùng nhãn theo ngôn ngữ, không so sánh chuỗi.
    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Hủy'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gia sư AI mở danh sách câu đã sai rồi mở panel giải thích', (
    tester,
  ) async {
    final history = MemoryHistoryStorage([
      QuizAttempt(
        id: 'ai_seed',
        timestamp: DateTime(2026, 11, 27, 19, 0),
        isExam: false,
        topic: 1,
        totalQuestions: 1,
        correct: 0,
        wrong: 1,
        skipped: 0,
        durationSeconds: 12,
        questionIds: [1],
        answers: {1: 'D'},
      ),
    ]);
    await open(tester, history);
    final tile = find.text('Gia sư AI');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();

    // Nút phải có ngữ cảnh câu hỏi, không mở panel rỗng.
    expect(find.text('Chọn câu để hỏi AI'), findsOneWidget);
    expect(find.textContaining('#1'), findsWidgets);
    expect(find.text('Sắp có'), findsNothing);

    await tester.tap(find.textContaining('#1').last);
    await tester.pumpAndSettle();
    expect(find.text('Giải thích AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gia sư AI hướng dẫn khi chưa có câu sai nào', (tester) async {
    await open(tester, MemoryHistoryStorage());
    final tile = find.text('Gia sư AI');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Trang Hôm nay có thêm thẻ chuỗi học nên phải bảo đảm ô này hiện ra hẳn.
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có câu nào làm sai'), findsOneWidget);
    expect(find.text('Chọn câu để hỏi AI'), findsNothing);
  });

  testWidgets('Exam history ignores the selected practice topic', (
    tester,
  ) async {
    final history = MemoryHistoryStorage();
    await open(tester, history);
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    tester
        .widget<DropdownButtonFormField<int>>(
          find.byType(DropdownButtonFormField<int>),
        )
        .onChanged!(1);
    await tester.pumpAndSettle();
    final exam = find.text('Thi thử · 50 câu · 50 phút');
    await tester.ensureVisible(exam);
    await tester.tap(exam);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nộp bài'));
    await tester.pumpAndSettle();
    final saved = (await history.loadHistory()).single;
    expect(saved.isExam, isTrue);
    expect(saved.topic, 0);
    expect(saved.questionIds, hasLength(50));
    expect(saved.skipped, 50);
  });
}
