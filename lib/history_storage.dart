import 'dart:convert';

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

  @override
  Future<List<QuizAttempt>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return const [];
      final list = (jsonDecode(raw) as List).cast<Map<String, Object?>>();
      final attempts = list.map(QuizAttempt.fromJson).toList();
      attempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return attempts;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {
    final current = await loadHistory();
    final updated = [
      attempt,
      for (final item in current)
        if (item.id != attempt.id) item,
    ];
    final trimmed = updated.take(maxItems).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode([for (final a in trimmed) a.toJson()]),
    );
  }

  @override
  Future<void> deleteAttempt(String id) async {
    final current = await loadHistory();
    final filtered = current.where((a) => a.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode([for (final a in filtered) a.toJson()]),
    );
  }

  @override
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

class MemoryHistoryStorage implements HistoryStorage {
  MemoryHistoryStorage([List<QuizAttempt>? initial])
    : _attempts = [...?initial];

  final List<QuizAttempt> _attempts;

  @override
  Future<List<QuizAttempt>> loadHistory() async {
    final sorted = [..._attempts]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(sorted);
  }

  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {
    _attempts.removeWhere((a) => a.id == attempt.id);
    _attempts.insert(0, attempt);
  }

  @override
  Future<void> deleteAttempt(String id) async {
    _attempts.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> clearHistory() async {
    _attempts.clear();
  }
}
