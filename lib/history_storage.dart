import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quiz_attempt.dart';

abstract class HistoryStorage {
  Future<List<QuizAttempt>> loadHistory();
  Future<void> saveAttempt(QuizAttempt attempt);
  Future<void> deleteAttempt(String id);
  Future<void> clearHistory();
}

class SharedPrefsHistoryStorage implements HistoryStorage {
  const SharedPrefsHistoryStorage({
    this.key = 'flutter_lab_quiz_history_v1',
    this.maxItems = 100,
  });

  final String key;
  final int maxItems;

  static final Map<String, Future<void>> _queues = {};

  /// Tuần tự hoá mọi thao tác ghi đọc-sửa-ghi theo từng [key] để tránh race condition.
  Future<T> _synchronized<T>(Future<T> Function() action) {
    final previous = _queues[key] ?? Future<void>.value();
    final completer = Completer<void>();
    _queues[key] = completer.future;
    return previous.catchError((_) {}).then((_) => action()).whenComplete(() {
      if (identical(_queues[key], completer.future)) {
        _queues.remove(key);
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
  }

  Future<List<QuizAttempt>> _loadHistoryUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return const [];

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      debugPrint('Lỗi giải mã JSON lịch sử từ SharedPreferences: $e');
      return const [];
    }
    if (decoded is! List) {
      debugPrint(
        'Dữ liệu lịch sử trong SharedPreferences không phải danh sách.',
      );
      return const [];
    }

    final attempts = <QuizAttempt>[];
    for (final element in decoded) {
      try {
        if (element is Map<String, Object?>) {
          attempts.add(QuizAttempt.fromJson(element));
        } else if (element is Map) {
          attempts.add(
            QuizAttempt.fromJson(Map<String, Object?>.from(element)),
          );
        } else {
          debugPrint('Bỏ qua bản ghi lịch sử không hợp lệ: $element');
        }
      } catch (e) {
        debugPrint('Bỏ qua bản ghi lịch sử bị lỗi: $e');
      }
    }
    attempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return attempts;
  }

  Future<void> _writeHistoryUnlocked(List<QuizAttempt> attempts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode([for (final a in attempts) a.toJson()]),
    );
  }

  @override
  Future<List<QuizAttempt>> loadHistory() => _loadHistoryUnlocked();

  @override
  Future<void> saveAttempt(QuizAttempt attempt) => _synchronized(() async {
    final current = await _loadHistoryUnlocked();
    final updated = [
      attempt,
      for (final item in current)
        if (item.id != attempt.id) item,
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final trimmed = updated.take(maxItems).toList();
    await _writeHistoryUnlocked(trimmed);
  });

  @override
  Future<void> deleteAttempt(String id) => _synchronized(() async {
    final current = await _loadHistoryUnlocked();
    final filtered = current.where((a) => a.id != id).toList();
    await _writeHistoryUnlocked(filtered);
  });

  @override
  Future<void> clearHistory() => _synchronized(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  });
}

class MemoryHistoryStorage implements HistoryStorage {
  MemoryHistoryStorage([List<QuizAttempt>? initial])
    : _attempts = [...?initial];

  final List<QuizAttempt> _attempts;
  Future<void> _queue = Future<void>.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final previous = _queue;
    final completer = Completer<void>();
    _queue = completer.future;
    return previous.catchError((_) {}).then((_) => action()).whenComplete(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
  }

  @override
  Future<List<QuizAttempt>> loadHistory() async {
    final sorted = [..._attempts]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(sorted);
  }

  @override
  Future<void> saveAttempt(QuizAttempt attempt) => _synchronized(() async {
    _attempts.removeWhere((a) => a.id == attempt.id);
    _attempts.insert(0, attempt);
  });

  @override
  Future<void> deleteAttempt(String id) => _synchronized(() async {
    _attempts.removeWhere((a) => a.id == id);
  });

  @override
  Future<void> clearHistory() => _synchronized(() async {
    _attempts.clear();
  });
}
