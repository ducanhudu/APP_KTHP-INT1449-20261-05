import 'package:flutter_quiz_app/card_storage.dart';
import 'package:flutter_quiz_app/sm2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kiểm thử tầng lưu trữ Flashcard (CardStorage)', () {
    final now = DateTime(2026, 11, 19);

    test('Lưu trữ ban đầu rỗng', () async {
      final storage = MemoryCardStorage();
      final cards = await storage.loadCards();
      expect(cards, isEmpty);
    });

    test('Thêm danh sách câu sai vào bộ thẻ thành công', () async {
      final storage = MemoryCardStorage();
      final addedCount = await storage.addCards([10, 25, 42], now: now);

      expect(addedCount, 3, reason: 'Phải thêm đủ 3 thẻ mới');
      final cards = await storage.loadCards();
      expect(cards, hasLength(3));
      expect(cards.map((c) => c.questionId).toSet(), equals({10, 25, 42}));

      // Kiểm tra trạng thái khởi tạo
      for (final card in cards) {
        expect(card.repetitions, 0);
        expect(card.interval, 0);
        expect(card.easeFactor, 2.5);
        expect(card.nextReviewDate, now);
        expect(card.isDue(now), isTrue);
      }
    });

    test(
      'Chống trùng lặp (Deduplication): không tạo thêm thẻ nếu câu hỏi đã có',
      () async {
        final storage = MemoryCardStorage();
        await storage.addCards([1, 2, 3], now: now);

        // Thử thêm lại câu 2, 3 và câu mới 4
        final addedCount = await storage.addCards([2, 3, 4], now: now);
        expect(addedCount, 1, reason: 'Chỉ có câu 4 là thẻ mới');

        final cards = await storage.loadCards();
        expect(cards, hasLength(4));
        expect(cards.map((c) => c.questionId).toSet(), equals({1, 2, 3, 4}));
      },
    );

    test('Cập nhật thẻ sau khi ôn tập (SM-2 review)', () async {
      final storage = MemoryCardStorage();
      await storage.addCards([101], now: now);

      final initialCards = await storage.loadCards();
      final card = initialCards.first;

      // Thực hiện review SM-2 với grade 4
      const sm2 = Sm2();
      final reviewed = sm2.review(item: card, grade: 4, reviewDate: now);
      await storage.updateCard(reviewed);

      final updatedCards = await storage.loadCards();
      expect(updatedCards, hasLength(1));
      final updated = updatedCards.first;
      expect(updated.questionId, 101);
      expect(updated.repetitions, 1);
      expect(updated.interval, 1);
      expect(updated.nextReviewDate, DateTime(2026, 11, 20));
      expect(updated.lastReviewedAt, now);
    });

    test('Xoá một thẻ theo questionId', () async {
      final storage = MemoryCardStorage();
      await storage.addCards([1, 2, 3], now: now);

      await storage.removeCard(2);
      final cards = await storage.loadCards();
      expect(cards.map((c) => c.questionId).toList(), equals([1, 3]));
    });

    test('Xoá toàn bộ thẻ (clear)', () async {
      final storage = MemoryCardStorage();
      await storage.addCards([1, 2, 3], now: now);

      await storage.clear();
      final cards = await storage.loadCards();
      expect(cards, isEmpty);
    });

    test('Chuyển đổi toJson() và fromJson() bảo toàn dữ liệu', () {
      final original = Sm2Item(
        questionId: 99,
        repetitions: 3,
        interval: 15,
        easeFactor: 2.7,
        nextReviewDate: DateTime(2026, 12, 5),
        lastReviewedAt: DateTime(2026, 11, 20, 10, 30),
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
