import 'package:flutter/material.dart';

/// Thẻ lựa chọn đáp án trong bài luyện tập/thi thử.
///
/// Hiển thị nhãn chữ cái (`A`, `B`, `C`, `D`) cố định ở bên trái và nội dung
/// đáp án ở bên phải, tự động xuống dòng và mở rộng chiều cao theo nội dung
/// mà không bị cắt chữ hay tràn ngang trên màn hình hẹp.
class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  /// Nhãn chữ cái của lựa chọn (ví dụ: `A`, `B`, `C`, `D`).
  final String label;

  /// Nội dung đáp án theo ngôn ngữ đang chọn.
  final String text;

  /// Trạng thái lựa chọn hiện tại.
  final bool selected;

  /// Callback khi người dùng chạm vào thẻ lựa chọn.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final backgroundColor = selected ? colors.primaryContainer : colors.surface;
    final borderColor = selected ? colors.primary : colors.outlineVariant;
    final textColor = selected ? colors.onPrimaryContainer : colors.onSurface;
    final badgeBg = selected ? colors.primary : colors.surfaceContainerHighest;
    final badgeFg = selected ? colors.onPrimary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      text,
                      softWrap: true,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        height: 1.4,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
