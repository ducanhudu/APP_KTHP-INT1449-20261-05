import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Các mốc chuỗi học được khen thưởng, tính theo số ngày liên tiếp.
const List<int> streakMilestones = <int>[3, 7, 14, 30, 50, 100];

/// Trạng thái chuỗi học lưu trên máy.
///
/// Chỉ giữ những gì cần để tính chuỗi: ngày học gần nhất, chuỗi hiện tại, kỷ
/// lục và các mốc đã được khen để không chúc mừng lặp lại.
@immutable
class StreakState {
  const StreakState({
    this.current = 0,
    this.best = 0,
    this.lastStudyDay,
    this.celebrated = const <int>{},
  });

  /// Số ngày liên tiếp hiện tại.
  final int current;

  /// Kỷ lục dài nhất từng đạt.
  final int best;

  /// Ngày (đã cắt về 00:00) của lượt học gần nhất; null nếu chưa học lần nào.
  final DateTime? lastStudyDay;

  /// Các mốc đã chúc mừng, tránh hiện lại hộp thoại.
  final Set<int> celebrated;

  bool get isEmpty => current == 0 && lastStudyDay == null;

  /// Ngày [day] có được tính là đã học không.
  bool studiedOn(DateTime day) {
    final last = lastStudyDay;
    if (last == null) return false;
    return last.year == day.year &&
        last.month == day.month &&
        last.day == day.day;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'current': current,
    'best': best,
    'lastStudyDay': lastStudyDay == null
        ? null
        : StreakService.dateKey(lastStudyDay!),
    'celebrated': celebrated.toList()..sort(),
  };

  factory StreakState.fromJson(Map<String, Object?> json) {
    final rawDay = json['lastStudyDay'];
    final rawCelebrated = json['celebrated'];
    return StreakState(
      current: _positiveInt(json['current']),
      best: _positiveInt(json['best']),
      lastStudyDay: rawDay is String ? DateTime.tryParse(rawDay) : null,
      celebrated: <int>{
        if (rawCelebrated is List)
          for (final item in rawCelebrated)
            if (item is int && item > 0) item,
      },
    );
  }

  static int _positiveInt(Object? value) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.toInt();
    return 0;
  }
}

/// Kết quả của một lần ghi nhận ngày học.
@immutable
class StreakUpdate {
  const StreakUpdate({
    required this.state,
    required this.counted,
    required this.extended,
    this.milestone,
  });

  final StreakState state;

  /// true khi hôm nay là ngày học mới được ghi vào chuỗi.
  final bool counted;

  /// true khi chuỗi tăng thêm so với lần học trước.
  final bool extended;

  /// Mốc vừa đạt trong lần ghi này, null nếu không có.
  final int? milestone;
}

/// Luật tính chuỗi học, tách khỏi giao diện để test được với ngày cố định.
class StreakService {
  const StreakService();

  /// Cắt thời điểm về đầu ngày để so sánh theo ngày, bỏ phần giờ.
  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Khoá ngày dạng yyyy-MM-dd dùng khi lưu JSON.
  static String dateKey(DateTime value) {
    final day = dayOf(value);
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayOfMonth';
  }

  /// Mốc kế tiếp cần đạt, null nếu đã vượt mốc cao nhất.
  static int? nextMilestone(int streak) {
    for (final milestone in streakMilestones) {
      if (milestone > streak) return milestone;
    }
    return null;
  }

  /// Mốc vừa đạt nhưng chưa được chúc mừng, null nếu không có.
  static int? milestoneReached(int streak, Set<int> celebrated) {
    for (final milestone in streakMilestones) {
      if (streak >= milestone && !celebrated.contains(milestone)) {
        return milestone;
      }
    }
    return null;
  }

  /// Ghi nhận một lượt học tại thời điểm [now].
  ///
  /// - Cùng ngày với lần trước: không cộng thêm, không chúc mừng lại.
  /// - Cách đúng một ngày: chuỗi tăng 1.
  /// - Cách hơn một ngày hoặc ngày lưu ở tương lai (đổi giờ máy): bắt đầu lại
  ///   từ 1, nhưng vẫn giữ kỷ lục cũ.
  StreakUpdate record(StreakState previous, DateTime now) {
    final today = dayOf(now);
    final last = previous.lastStudyDay == null
        ? null
        : dayOf(previous.lastStudyDay!);

    if (last != null && last.isAtSameMomentAs(today)) {
      return StreakUpdate(state: previous, counted: false, extended: false);
    }

    final bool extended;
    final int next;
    if (last != null && today.difference(last).inDays == 1) {
      next = previous.current + 1;
      extended = true;
    } else {
      next = 1;
      extended = false;
    }

    final best = next > previous.best ? next : previous.best;
    final milestone = milestoneReached(next, previous.celebrated);
    final celebrated = milestone == null
        ? previous.celebrated
        : <int>{...previous.celebrated, milestone};

    return StreakUpdate(
      state: StreakState(
        current: next,
        best: best,
        lastStudyDay: today,
        celebrated: celebrated,
      ),
      counted: true,
      extended: extended,
      milestone: milestone,
    );
  }
}

/// Ghi nhận ngày học tuần tự.
///
/// Hai thao tác đồng thời (ví dụ vừa nộp bài vừa chấm thẻ) nếu cùng đọc một
/// trạng thái cũ rồi cùng ghi thì sẽ mất một lần cộng chuỗi; tracker xếp hàng
/// các lần ghi để tránh chuyện đó.
class StreakTracker {
  StreakTracker(this.storage, {this.service = const StreakService()});

  final StreakStorage storage;
  final StreakService service;

  Future<void> _queue = Future<void>.value();

  Future<StreakUpdate> recordStudy(DateTime now) {
    final result = Completer<StreakUpdate>();
    _queue = _queue.then((_) async {
      try {
        final previous = await storage.load();
        final update = service.record(previous, now);
        if (update.counted) {
          await storage.save(update.state);
        }
        result.complete(update);
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }
}

/// Nơi lưu trạng thái chuỗi; tách interface để test dùng bản trong RAM.
abstract class StreakStorage {
  Future<StreakState> load();
  Future<void> save(StreakState state);
}

/// Bản lưu thật bằng SharedPreferences, chịu được dữ liệu hỏng.
class SharedPrefsStreakStorage implements StreakStorage {
  const SharedPrefsStreakStorage({this.key = 'flutter_lab_streak_v1'});

  final String key;

  @override
  Future<StreakState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return const StreakState();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return StreakState.fromJson(Map<String, Object?>.from(decoded));
      }
      debugPrint('Dữ liệu chuỗi học không phải object JSON.');
    } catch (error) {
      debugPrint('Không đọc được dữ liệu chuỗi học: $error');
    }
    return const StreakState();
  }

  @override
  Future<void> save(StreakState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(state.toJson()));
  }
}

/// Bản trong RAM dùng cho test.
class MemoryStreakStorage implements StreakStorage {
  MemoryStreakStorage([this.state = const StreakState()]);

  StreakState state;

  @override
  Future<StreakState> load() async => state;

  @override
  Future<void> save(StreakState value) async {
    state = value;
  }
}
