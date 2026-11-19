import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Kết quả của thao tác bật nhắc ôn.
enum ReminderResult {
  /// Đã đặt lịch nhắc.
  scheduled,

  /// Người dùng chưa cấp quyền thông báo.
  permissionDenied,

  /// Lỗi khác (plugin không khả dụng, hệ điều hành từ chối...).
  failed,
}

/// Nhắc ôn hằng ngày cho bộ thẻ SM-2.
///
/// Tách thành interface để màn hình và test không phụ thuộc trực tiếp vào
/// plugin thông báo.
abstract class ReminderService {
  /// Nhắc ôn có đang bật hay không.
  Future<bool> isEnabled();

  /// Bật nhắc ôn vào [hour]:[minute] mỗi ngày.
  ///
  /// Quyền thông báo chỉ được hỏi tại đây — đúng lúc người dùng bật tính năng,
  /// không hỏi khi mở app.
  Future<ReminderResult> enable({int hour = 20, int minute = 0});

  /// Tắt nhắc ôn và huỷ lịch đã đặt.
  Future<void> disable();
}

/// Hiện thực dùng `flutter_local_notifications` + `timezone`.
class NotificationReminderService implements ReminderService {
  NotificationReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String enabledKey = 'flutter_quiz_reminder_daily';
  static const String timeKey = 'flutter_quiz_reminder_time';
  static const int notificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (error) {
      debugPrint('Không lấy được múi giờ thiết bị, dùng mặc định: $error');
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  Future<bool> _requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  @override
  Future<ReminderResult> enable({int hour = 20, int minute = 0}) async {
    try {
      await _ensureReady();
      if (!await _requestPermission()) return ReminderResult.permissionDenied;

      final prefs = await SharedPreferences.getInstance();
      await _plugin.cancel(notificationId);

      await _plugin.zonedSchedule(
        notificationId,
        'Ôn lại thẻ hôm nay',
        'Bạn có thẻ ghi nhớ đến hạn. Mở Flutter Lab để ôn nhé.',
        _nextInstance(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'flutter_quiz_daily_reminder',
            'Nhắc ôn hằng ngày',
            channelDescription: 'Nhắc ôn thẻ ghi nhớ SM-2 mỗi ngày',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await prefs.setBool(enabledKey, true);
      await prefs.setString(
        timeKey,
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
      return ReminderResult.scheduled;
    } catch (error) {
      debugPrint('Không đặt được lịch nhắc ôn: $error');
      return ReminderResult.failed;
    }
  }

  @override
  Future<void> disable() async {
    try {
      await _ensureReady();
      await _plugin.cancel(notificationId);
    } catch (error) {
      debugPrint('Không huỷ được lịch nhắc ôn: $error');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, false);
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
