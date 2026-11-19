import 'package:flutter_quiz_app/card_storage.dart';
import 'package:flutter_quiz_app/sm2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kiểm thử tầng lưu trữ thật (`SharedPrefsCardStorage`).
///
/// Các test cũ chỉ chạy trên `MemoryCardStorage` nên chưa chứng minh được yêu
/// cầu "mở lại app vẫn còn bộ thẻ" của đề 33. Ở đây mỗi lần đọc lại đều tạo
/// một instance mới để mô phỏng việc khởi động lại ứng dụng.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storage = SharedPrefsCardStorage();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SharedPrefsCardStorage: dữ liệu còn sau khi mở lại app', () {
    test('Thêm thẻ rồi đọc lại bằng instance mới: thẻ vẫn còn', () async {
      final added = await storage.addCards([7, 8, 9]);
      expect(added, 3);

      final reloaded = await const SharedPrefsCardStorage().loadCards();
      expect(reloaded, hasLength(3));
      expect(reloaded.map((card) => card.questionId).toSet(), {7, 8, 9});
      for (final card in reloaded) {
        expect(card.repetitions, 0);
        expect(card.interval, 0);
        expect(card.easeFactor, 2.5);
      }
    });

    test('Ôn thẻ rồi mở lại: lịch SM-2 mới được giữ nguyên', () async {
      await storage.addCards([42]);
      final card = (await storage.loadCards()).single;

      final reviewed = const Sm2().review(
        item: card,
        grade: 5,
        reviewDate: DateTime(2026, 11, 19),
      );
      await storage.updateCard(reviewed);

      final reloaded = await const SharedPrefsCardStorage().loadCards();
      expect(reloaded.single.questionId, 42);
      expect(reloaded.single.repetitions, 1);
      expect(reloaded.single.interval, 1);
      expect(reloaded.single.easeFactor, closeTo(2.6, 0.001));
      expect(reloaded.single.nextReviewDate, DateTime(2026, 11, 20));
      expect(reloaded.single.isDue(DateTime(2026, 11, 19)), isFalse);
      expect(reloaded.single.isDue(DateTime(2026, 11, 20)), isTrue);
    });

    test('Xoá thẻ rồi mở lại: thẻ đã xoá không quay lại', () async {
      await storage.addCards([1, 2]);
      await storage.removeCard(1);

      final reloaded = await const SharedPrefsCardStorage().loadCards();
      expect(reloaded.map((card) => card.questionId), [2]);
    });

    test('Xoá sạch rồi mở lại: bộ thẻ rỗng', () async {
      await storage.addCards([1, 2, 3]);
      await storage.clear();

      final reloaded = await const SharedPrefsCardStorage().loadCards();
      expect(reloaded, isEmpty);
    });

    test('Thêm trùng câu hỏi không tạo thẻ thứ hai', () async {
      await storage.addCards([5, 5, 6]);
      final reloaded = await const SharedPrefsCardStorage().loadCards();
      expect(reloaded.map((card) => card.questionId).toSet(), {5, 6});
    });

    test('JSON hỏng trong bộ nhớ không làm app dừng', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsCardStorage.storageKey: '{broken',
      });

      expect(await const SharedPrefsCardStorage().loadCards(), isEmpty);
    });

    test('Dữ liệu không phải danh sách được bỏ qua an toàn', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsCardStorage.storageKey: '{"a": 1}',
      });

      expect(await const SharedPrefsCardStorage().loadCards(), isEmpty);
    });
  });
}
