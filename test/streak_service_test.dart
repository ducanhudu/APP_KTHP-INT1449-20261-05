import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/app_strings.dart';
import 'package:flutter_quiz_app/streak_card.dart';
import 'package:flutter_quiz_app/streak_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = StreakService();
  DateTime day(int dayOfMonth) => DateTime(2026, 3, dayOfMonth);

  group('StreakService.record', () {
    test('lần học đầu tiên mở chuỗi một ngày', () {
      final update = service.record(const StreakState(), day(1));

      expect(update.counted, isTrue);
      expect(update.extended, isFalse);
      expect(update.state.current, 1);
      expect(update.state.best, 1);
      expect(update.state.lastStudyDay, day(1));
      expect(update.milestone, isNull);
    });

    test('học nhiều lần trong cùng một ngày chỉ tính một lần', () {
      final first = service.record(const StreakState(), day(1));
      final second = service.record(
        first.state,
        day(1).add(const Duration(hours: 9)),
      );

      expect(second.counted, isFalse);
      expect(second.state.current, 1);
      expect(second.state.best, 1);
      expect(second.milestone, isNull);
    });

    test('ba ngày liên tiếp chạm mốc 3 và ghi nhận đã khen', () {
      var state = const StreakState();
      final milestones = <int?>[];

      for (final value in [1, 2, 3]) {
        final update = service.record(state, day(value));
        state = update.state;
        milestones.add(update.milestone);
        expect(state.current, value);
      }

      expect(milestones, [null, null, 3]);
      expect(state.best, 3);
      expect(state.celebrated, contains(3));
    });

    test('mốc đã khen không hiện lại ở những ngày sau', () {
      var state = const StreakState();
      for (final value in [1, 2, 3, 4, 5, 6, 7]) {
        state = service.record(state, day(value)).state;
      }

      expect(state.current, 7);
      expect(state.celebrated, containsAll(<int>[3, 7]));

      final eighth = service.record(state, day(8));
      expect(eighth.milestone, isNull);
      expect(eighth.state.current, 8);
    });

    test('nghỉ một ngày thì chuỗi về 1 nhưng giữ kỷ lục', () {
      var state = const StreakState();
      for (final value in [1, 2, 3]) {
        state = service.record(state, day(value)).state;
      }

      final afterGap = service.record(state, day(5));

      expect(afterGap.counted, isTrue);
      expect(afterGap.state.current, 1);
      expect(afterGap.state.best, 3);
      expect(afterGap.extended, isFalse);
    });

    test('ngày lưu ở tương lai thì bắt đầu lại thay vì cộng sai', () {
      final future = StreakState(current: 5, best: 5, lastStudyDay: day(10));

      final update = service.record(future, day(2));

      expect(update.state.current, 1);
      expect(update.state.best, 5);
      expect(update.state.lastStudyDay, day(2));
    });

    test('chuỗi mới vượt kỷ lục thì cập nhật kỷ lục', () {
      var state = StreakState(current: 2, best: 4, lastStudyDay: day(1));

      final update = service.record(state, day(2));

      expect(update.state.current, 3);
      expect(update.state.best, 4);

      state = update.state;
      state = StreakState(
        current: 4,
        best: 4,
        lastStudyDay: day(2),
        celebrated: state.celebrated,
      );
      final next = service.record(state, day(3));

      expect(next.state.current, 5);
      expect(next.state.best, 5);
    });
  });

  group('mốc kế tiếp', () {
    test('trả về mốc gần nhất còn chưa đạt', () {
      expect(StreakService.nextMilestone(0), 3);
      expect(StreakService.nextMilestone(2), 3);
      expect(StreakService.nextMilestone(3), 7);
      expect(StreakService.nextMilestone(13), 14);
      expect(StreakService.nextMilestone(100), isNull);
      expect(StreakService.nextMilestone(250), isNull);
    });

    test('chỉ báo mốc chưa được khen', () {
      expect(StreakService.milestoneReached(3, <int>{}), 3);
      expect(StreakService.milestoneReached(3, <int>{3}), isNull);
      expect(StreakService.milestoneReached(8, <int>{3, 7}), isNull);
      expect(StreakService.milestoneReached(8, <int>{3}), 7);
    });
  });

  group('lưu trữ chuỗi', () {
    test('JSON giữ đủ trường và đọc lại được', () {
      final state = StreakState(
        current: 4,
        best: 9,
        lastStudyDay: day(6),
        celebrated: const <int>{3},
      );

      final restored = StreakState.fromJson(state.toJson());

      expect(restored.current, 4);
      expect(restored.best, 9);
      expect(restored.lastStudyDay, day(6));
      expect(restored.celebrated, contains(3));
    });

    test('JSON hỏng hoặc thiếu trường thì về trạng thái rỗng', () {
      final restored = StreakState.fromJson(<String, Object?>{
        'current': 'không phải số',
        'lastStudyDay': 'không phải ngày',
        'celebrated': 'không phải danh sách',
      });

      expect(restored.current, 0);
      expect(restored.best, 0);
      expect(restored.lastStudyDay, isNull);
      expect(restored.celebrated, isEmpty);
    });

    test('bản lưu trong RAM đọc lại đúng dữ liệu vừa ghi', () async {
      final storage = MemoryStreakStorage();
      expect((await storage.load()).current, 0);

      final update = service.record(const StreakState(), day(1));
      await storage.save(update.state);

      final loaded = await storage.load();
      expect(loaded.current, 1);
      expect(loaded.lastStudyDay, day(1));
    });
  });

  group('thẻ chuỗi học', () {
    testWidgets('hiện số ngày, kỷ lục và mốc kế tiếp', (tester) async {
      final state = StreakState(
        current: 5,
        best: 9,
        lastStudyDay: day(6),
        celebrated: const <int>{3},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(
              future: Future<StreakState>.value(state),
              strings: AppStrings.vietnamese,
              now: DateTime(2026, 3, 6, 20),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chuỗi học'), findsOneWidget);
      expect(find.text('5 ngày liên tiếp'), findsOneWidget);
      expect(find.text('Kỷ lục 9 ngày'), findsOneWidget);
      expect(find.text('Hôm nay đã học'), findsOneWidget);
      expect(find.text('Mốc 7 ngày · còn 2 ngày'), findsOneWidget);
    });

    testWidgets('chưa học ngày nào thì mời bắt đầu chuỗi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(
              future: Future<StreakState>.value(const StreakState()),
              strings: AppStrings.vietnamese,
              now: DateTime(2026, 3, 6),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 ngày liên tiếp'), findsOneWidget);
      expect(
        find.text('Học một lượt hôm nay để bắt đầu chuỗi'),
        findsOneWidget,
      );
      expect(find.text('Mốc 3 ngày · còn 3 ngày'), findsOneWidget);
    });

    testWidgets('hôm nay chưa học nhưng đã có chuỗi thì nhắc giữ chuỗi', (
      tester,
    ) async {
      final state = StreakState(
        current: 2,
        best: 2,
        lastStudyDay: DateTime(2026, 3, 5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(
              future: Future<StreakState>.value(state),
              strings: AppStrings.vietnamese,
              now: DateTime(2026, 3, 6, 8),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Học một lượt hôm nay để giữ chuỗi'), findsOneWidget);
    });
  });

  group('ghi nhận tuần tự', () {
    test('hai lần ghi đồng thời chỉ cộng một ngày', () async {
      final storage = _SlowStreakStorage();
      final tracker = StreakTracker(storage);

      final results = await Future.wait(<Future<StreakUpdate>>[
        tracker.recordStudy(day(1)),
        tracker.recordStudy(day(1)),
      ]);

      expect(results.where((update) => update.counted).length, 1);
      expect(storage.state.current, 1);
      expect(storage.saves, 1);
    });

    test('ghi hai ngày liên tiếp vẫn đọc đúng trạng thái mới nhất', () async {
      final storage = _SlowStreakStorage();
      final tracker = StreakTracker(storage);

      final first = await tracker.recordStudy(day(1));
      final second = await tracker.recordStudy(day(2));

      expect(first.state.current, 1);
      expect(second.state.current, 2);
      expect(storage.state.current, 2);
      expect(storage.state.lastStudyDay, day(2));
    });
  });
}

/// Bản lưu có độ trễ để hai lần ghi chen nhau, dùng kiểm tra xếp hàng.
class _SlowStreakStorage implements StreakStorage {
  StreakState state = const StreakState();
  int saves = 0;

  @override
  Future<StreakState> load() async {
    await Future<void>.delayed(Duration.zero);
    return state;
  }

  @override
  Future<void> save(StreakState value) async {
    saves++;
    await Future<void>.delayed(Duration.zero);
    state = value;
  }
}
