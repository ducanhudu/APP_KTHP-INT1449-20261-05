import 'package:flutter/material.dart';

/// Trạng thái lỗi có lối ra: luôn kèm một hành động để người dùng thử lại.
///
/// Dùng chung cho các `FutureBuilder` trong ứng dụng để mọi màn hình lỗi đều
/// có nút "Thử lại" thay vì chỉ hiện một dòng chữ.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Thử lại',
    this.icon = Icons.error_outline,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(retryLabel),
          ),
        ],
      ),
    ),
  );
}
