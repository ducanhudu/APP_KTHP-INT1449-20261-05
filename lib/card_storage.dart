import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sm2.dart';

/// Giao diện lưu trữ bộ thẻ ghi nhớ (Flashcard) ôn tập SM-2.
abstract class CardStorage {
  /// Nạp toàn bộ danh sách thẻ từ bộ nhớ cục bộ.
  Future<List<Sm2Item>> loadCards();

  /// Lưu toàn bộ danh sách thẻ xuống bộ nhớ.
  Future<void> saveCards(List<Sm2Item> cards);

  /// Thêm danh sách ID câu hỏi vào bộ thẻ.
  /// Tự động bỏ qua các câu hỏi đã tồn tại trong bộ thẻ (chống trùng lặp).
  /// Trả về số lượng thẻ mới thực tế được thêm vào.
  Future<int> addCards(Iterable<int> questionIds, {DateTime? now});

  /// Cập nhật trạng thái một thẻ sau khi ôn tập (SM-2 review).
  Future<void> updateCard(Sm2Item item);

  /// Xoá một thẻ theo ID câu hỏi.
  Future<void> removeCard(int questionId);

  /// Xoá toàn bộ thẻ trong bộ nhớ.
  Future<void> clear();
}

/// Hiện thực lưu trữ thẻ dùng SharedPreferences (bền vững trên Android/iOS/Desktop).
class SharedPrefsCardStorage implements CardStorage {
  const SharedPrefsCardStorage();

  static const String storageKey = 'flutter_quiz_cards_sm2';

  @override
  Future<List<Sm2Item>> loadCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final cards = <Sm2Item>[];
      for (final element in decoded) {
        if (element is Map<String, Object?>) {
          cards.add(Sm2Item.fromJson(element));
        } else if (element is Map) {
          cards.add(Sm2Item.fromJson(Map<String, Object?>.from(element)));
        }
      }
      return cards;
    } catch (e) {
      debugPrint('Lỗi đọc dữ liệu thẻ từ SharedPreferences: $e');
      return [];
    }
  }

  @override
  Future<void> saveCards(List<Sm2Item> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(cards.map((c) => c.toJson()).toList());
    await prefs.setString(storageKey, data);
  }

  @override
  Future<int> addCards(Iterable<int> questionIds, {DateTime? now}) async {
    final cards = await loadCards();
    final existingIds = cards.map((c) => c.questionId).toSet();
    var added = 0;

    for (final qId in questionIds) {
      if (!existingIds.contains(qId)) {
        cards.add(Sm2Item.initial(questionId: qId, now: now));
        existingIds.add(qId);
        added++;
      }
    }

    if (added > 0) {
      await saveCards(cards);
    }
    return added;
  }

  @override
  Future<void> updateCard(Sm2Item item) async {
    final cards = await loadCards();
    final index = cards.indexWhere((c) => c.questionId == item.questionId);
    if (index != -1) {
      cards[index] = item;
    } else {
      cards.add(item);
    }
    await saveCards(cards);
  }

  @override
  Future<void> removeCard(int questionId) async {
    final cards = await loadCards();
    cards.removeWhere((c) => c.questionId == questionId);
    await saveCards(cards);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}

/// Hiện thực lưu trữ trong RAM dùng cho Unit Test và Widget Test.
class MemoryCardStorage implements CardStorage {
  MemoryCardStorage([List<Sm2Item>? initial]) {
    if (initial != null) {
      for (final card in initial) {
        _cards[card.questionId] = card;
      }
    }
  }

  final Map<int, Sm2Item> _cards = {};

  @override
  Future<List<Sm2Item>> loadCards() async => _cards.values.toList();

  @override
  Future<void> saveCards(List<Sm2Item> cards) async {
    _cards.clear();
    for (final card in cards) {
      _cards[card.questionId] = card;
    }
  }

  @override
  Future<int> addCards(Iterable<int> questionIds, {DateTime? now}) async {
    var added = 0;
    for (final qId in questionIds) {
      if (!_cards.containsKey(qId)) {
        _cards[qId] = Sm2Item.initial(questionId: qId, now: now);
        added++;
      }
    }
    return added;
  }

  @override
  Future<void> updateCard(Sm2Item item) async {
    _cards[item.questionId] = item;
  }

  @override
  Future<void> removeCard(int questionId) async {
    _cards.remove(questionId);
  }

  @override
  Future<void> clear() async {
    _cards.clear();
  }
}
