import 'package:flutter_quiz_app/sm2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Thuật toán SM-2 (SuperMemo-2)', () {
    const sm2 = Sm2();
    final baseDate = DateTime(2026, 11, 18);

    test('Thẻ mới tạo có trạng thái mặc định chính xác', () {
      final item = Sm2Item.initial(questionId: 101, now: baseDate);

      expect(item.questionId, 101);
      expect(item.repetitions, 0);
      expect(item.interval, 0);
      expect(item.easeFactor, 2.5);
      expect(item.nextReviewDate, baseDate);
      expect(item.lastReviewedAt, isNull);
      expect(item.isDue(baseDate), isTrue);
    });

    test(
      'Chuỗi nhớ tốt (Grade 5): interval tăng theo 1 -> 6 -> interval * EF',
      () {
        var item = Sm2Item.initial(questionId: 101, now: baseDate);

        // Lần 1: Grade 5 -> repetitions = 1, interval = 1, EF = 2.5 + 0.1 = 2.6
        item = sm2.review(item: item, grade: 5, reviewDate: baseDate);
        expect(item.repetitions, 1);
        expect(item.interval, 1);
        expect(item.easeFactor, 2.6);
        expect(item.nextReviewDate, DateTime(2026, 11, 19));

        // Lần 2: Grade 5 -> repetitions = 2, interval = 6, EF = 2.6 + 0.1 = 2.7
        final date2 = DateTime(2026, 11, 19);
        item = sm2.review(item: item, grade: 5, reviewDate: date2);
        expect(item.repetitions, 2);
        expect(item.interval, 6);
        expect(item.easeFactor, 2.7);
        expect(item.nextReviewDate, DateTime(2026, 11, 25));

        // Lần 3: Grade 5 -> repetitions = 3, interval = (6 * 2.8).round() = 17, EF = 2.7 + 0.1 = 2.8
        final date3 = DateTime(2026, 11, 25);
        item = sm2.review(item: item, grade: 5, reviewDate: date3);
        expect(item.repetitions, 3);
        expect(item.interval, 17);
        expect(item.easeFactor, 2.8);
        expect(item.nextReviewDate, DateTime(2026, 12, 12));

        // Lần 4: Grade 4 (nhớ đúng sau đắn đo) -> EF giữ nguyên 2.8, interval = (17 * 2.8).round() = 48
        final date4 = DateTime(2026, 12, 12);
        item = sm2.review(item: item, grade: 4, reviewDate: date4);
        expect(item.repetitions, 4);
        expect(item.interval, 48);
        expect(item.easeFactor, 2.8);
        expect(item.nextReviewDate, DateTime(2027, 1, 29));
      },
    );

    test('Khi quên hoặc làm sai (Grade < 3): repetitions reset về 0, interval reset về 1', () {
      // Giả sử thẻ đã qua 3 lần ôn tập thành công
      var item = Sm2Item(
        questionId: 42,
        repetitions: 3,
        interval: 16,
        easeFactor: 2.6,
        nextReviewDate: baseDate,
      );

      // Ôn tập lại nhưng quên (Grade 1):
      // EF' = 2.6 + (0.1 - 4 * (0.08 + 0.08)) = 2.6 - 0.54 = 2.06
      item = sm2.review(item: item, grade: 1, reviewDate: baseDate);

      expect(
        item.repetitions,
        0,
        reason: 'Repetitions phải bị reset về 0 khi quên',
      );
      expect(
        item.interval,
        1,
        reason: 'Interval phải reset về 1 ngày để ôn lại ngay hôm sau',
      );
      expect(item.easeFactor, 2.06);
      expect(item.nextReviewDate, DateTime(2026, 11, 19));
    });

    test('Ease Factor không bao giờ giảm xuống dưới ngưỡng tối thiểu 1.3', () {
      var item = Sm2Item.initial(questionId: 1, now: baseDate);

      // Liên tục đánh giá Grade 0 (quên hoàn toàn)
      for (var i = 0; i < 5; i++) {
        item = sm2.review(item: item, grade: 0, reviewDate: baseDate);
      }

      expect(item.easeFactor, equals(Sm2.minEaseFactor));
      expect(item.easeFactor, 1.3);
      expect(item.repetitions, 0);
      expect(item.interval, 1);
    });

    test('Kiểm tra hạn ôn tập isDue()', () {
      final item = Sm2Item(
        questionId: 10,
        repetitions: 1,
        interval: 3,
        nextReviewDate: DateTime(2026, 11, 21),
      );

      // Trước ngày đến hạn
      expect(item.isDue(DateTime(2026, 11, 20)), isFalse);
      // Đúng ngày đến hạn
      expect(item.isDue(DateTime(2026, 11, 21)), isTrue);
      // Quá hạn
      expect(item.isDue(DateTime(2026, 11, 22)), isTrue);
    });

    test('Chuyển đổi JSON (toJson / fromJson) bảo toàn dữ liệu', () {
      final original = Sm2Item(
        questionId: 99,
        repetitions: 2,
        interval: 6,
        easeFactor: 2.7,
        nextReviewDate: DateTime(2026, 11, 25),
        lastReviewedAt: DateTime(2026, 11, 19, 14, 30),
      );

      final json = original.toJson();
      final restored = Sm2Item.fromJson(json);

      expect(restored.questionId, original.questionId);
      expect(restored.repetitions, original.repetitions);
      expect(restored.interval, original.interval);
      expect(restored.easeFactor, original.easeFactor);
      expect(restored.nextReviewDate, original.nextReviewDate);
      expect(restored.lastReviewedAt, original.lastReviewedAt);
    });
  });
}
