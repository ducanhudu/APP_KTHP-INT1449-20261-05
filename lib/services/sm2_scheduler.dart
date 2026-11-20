// SM‑2 spaced‑repetition scheduler (project lib/services)
import 'package:intl/intl.dart';

class SM2Scheduler {
  /// Calculates next review date based on SM‑2 algorithm.
  /// * [rating] – 0..5 where >=3 means good recall.
  /// * [previousInterval] – prior interval in days.
  static DateTime nextReviewDate(int rating, int previousInterval) {
    int interval;
    if (rating >= 3) {
      interval = previousInterval == 0 ? 1 : previousInterval * 2;
    } else if (rating == 2) {
      interval = previousInterval == 0 ? 1 : previousInterval + 1;
    } else {
      interval = 1;
    }
    return DateTime.now().add(Duration(days: interval));
  }

  static String formatDate(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }
}
