import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'streak_service.dart';

/// Thẻ hiển thị chuỗi học theo ngày ở trang Hôm nay.
///
/// Dữ liệu đọc qua [future] để trang chính không phải chờ sẵn; trong lúc chờ
/// hoặc khi lỗi thì thẻ không chiếm chỗ để bố cục bên dưới không bị nhảy.
class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.future,
    required this.strings,
    this.now,
  });

  final Future<StreakState> future;
  final AppStrings strings;

  /// Thời điểm dùng để xác định "hôm nay"; test truyền ngày cố định.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StreakState>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final state = snapshot.data;
        if (state == null) return const _StreakCardSkeleton();
        return _StreakCardBody(
          state: state,
          strings: strings,
          now: now ?? DateTime.now(),
        );
      },
    );
  }
}

class _StreakCardBody extends StatelessWidget {
  const _StreakCardBody({
    required this.state,
    required this.strings,
    required this.now,
  });

  final StreakState state;
  final AppStrings strings;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = StreakService.nextMilestone(state.current);
    final progress = next == null
        ? (state.current > 0 ? 1.0 : 0.0)
        : (state.current / next).clamp(0.0, 1.0);
    final studiedToday = state.studiedOn(now);

    final String status;
    if (state.current == 0) {
      status = strings.streakStart;
    } else if (studiedToday) {
      status = strings.streakStudiedToday;
    } else {
      status = strings.streakKeepToday;
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: state.current > 0
                      ? const Color(0xffe25822)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.streakTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (state.best > 0)
                  Text(
                    strings.streakBest(state.best),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${state.current}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    strings.streakDays(state.current),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surface,
                color: state.current > 0
                    ? const Color(0xffe25822)
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(status, style: theme.textTheme.bodyMedium),
            if (next != null) ...[
              const SizedBox(height: 2),
              Text(
                strings.streakNext(next, next - state.current),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StreakCardSkeleton extends StatelessWidget {
  const _StreakCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Khung chờ tĩnh: không dùng vòng xoay để `pumpAndSettle` trong test vẫn
    // kết thúc được khi bản đọc chuỗi chưa trả về.
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      child: SizedBox(
        height: 148,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
