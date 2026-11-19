import 'package:flutter_quiz_app/reminder_service.dart';

/// Bản giả của [ReminderService] để test không cần plugin thông báo.
class FakeReminderService implements ReminderService {
  FakeReminderService({
    this.enabled = false,
    this.result = ReminderResult.scheduled,
  });

  bool enabled;
  ReminderResult result;
  int enableCalls = 0;
  int disableCalls = 0;
  int? lastHour;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<ReminderResult> enable({int hour = 20, int minute = 0}) async {
    enableCalls++;
    lastHour = hour;
    enabled = result == ReminderResult.scheduled;
    return result;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
    enabled = false;
  }
}
