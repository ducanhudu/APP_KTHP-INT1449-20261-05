import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'reminder_service.dart';

/// Công tắc "Nhắc ôn hằng ngày" trong màn hình Hôm nay.
///
/// Quyền thông báo chỉ được xin khi người dùng bật công tắc, không xin lúc mở app.
class ReminderTile extends StatefulWidget {
  const ReminderTile({
    super.key,
    required this.service,
    this.hour = 20,
    this.strings = AppStrings.vietnamese,
  });

  final ReminderService service;
  final int hour;
  final AppStrings strings;

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
      _notify(widget.strings.reminderDisabled);
      return;
    }

    final result = await widget.service.enable(hour: widget.hour);
    if (!mounted) return;
    setState(() {
      _enabled = result == ReminderResult.scheduled;
      _busy = false;
    });
    _notify(switch (result) {
      ReminderResult.scheduled => widget.strings.reminderEnabled,
      ReminderResult.permissionDenied => widget.strings.reminderDenied,
      ReminderResult.failed => widget.strings.reminderFailed,
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
    final s = widget.strings;
    return SwitchListTile.adaptive(
      value: enabled ?? false,
      onChanged: enabled == null || _busy ? null : _toggle,
      secondary: const Icon(Icons.notifications_active_outlined),
      title: Text(s.reminderTitle),
      subtitle: Text(enabled == true ? s.reminderOn : s.reminderOff),
    );
  }
}
