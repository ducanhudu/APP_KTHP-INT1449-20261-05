import 'package:flutter/material.dart';

import 'reminder_service.dart';

/// Công tắc "Nhắc ôn hằng ngày" trong màn hình Hôm nay.
///
/// Quyền thông báo chỉ được xin khi người dùng bật công tắc, không xin lúc mở app.
class ReminderTile extends StatefulWidget {
  const ReminderTile({super.key, required this.service, this.hour = 20});

  final ReminderService service;
  final int hour;

  @override
  State<ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<ReminderTile> {
  bool? _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await widget.service.isEnabled();
    if (!mounted) return;
    setState(() => _enabled = value);
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    if (!value) {
      await widget.service.disable();
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _busy = false;
      });
      _notify('Đã tắt nhắc ôn hằng ngày.');
      return;
    }

    final result = await widget.service.enable(hour: widget.hour);
    if (!mounted) return;
    setState(() {
      _enabled = result == ReminderResult.scheduled;
      _busy = false;
    });
    _notify(switch (result) {
      ReminderResult.scheduled =>
        'Đã bật nhắc ôn lúc ${widget.hour.toString().padLeft(2, '0')}:00 mỗi ngày.',
      ReminderResult.permissionDenied =>
        'Chưa có quyền thông báo. Hãy bật quyền trong Cài đặt để nhận nhắc ôn.',
      ReminderResult.failed => 'Không đặt được lịch nhắc. Thử lại sau.',
    });
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return SwitchListTile.adaptive(
      value: enabled ?? false,
      onChanged: enabled == null || _busy ? null : _toggle,
      secondary: const Icon(Icons.notifications_active_outlined),
      title: const Text('Nhắc ôn hằng ngày'),
      subtitle: Text(
        enabled == true
            ? 'Nhắc lúc ${widget.hour.toString().padLeft(2, '0')}:00 mỗi ngày'
            : 'Nhận thông báo khi có thẻ đến hạn',
      ),
    );
  }
}
