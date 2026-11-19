/// Thuật toán lặp lại ngắt quãng SuperMemo-2 (SM-2) và mô hình Flashcard.
/// Phục vụ Đề 33: Lưu câu sai thành thẻ, ôn tập theo lịch lặp lại ngắt quãng.
library;

/// Đại diện cho một thẻ ghi nhớ ôn tập theo thuật toán SM-2.
class Sm2Item {
  const Sm2Item({
    required this.questionId,
    this.repetitions = 0,
    this.interval = 0,
    this.easeFactor = 2.5,
    required this.nextReviewDate,
    this.lastReviewedAt,
  });

  /// Tạo thẻ mới chưa qua lượt ôn tập nào.
  factory Sm2Item.initial({required int questionId, DateTime? now}) {
    final current = now ?? DateTime.now();
    return Sm2Item(
      questionId: questionId,
      repetitions: 0,
      interval: 0,
      easeFactor: 2.5,
      nextReviewDate: DateTime(current.year, current.month, current.day),
    );
  }

  /// Khởi tạo thẻ từ dữ liệu JSON (dùng khi nạp từ Local Storage / SQLite / Hive).
  factory Sm2Item.fromJson(Map<String, Object?> json) {
    return Sm2Item(
      questionId: json['questionId'] as int,
      repetitions: json['repetitions'] as int? ?? 0,
      interval: json['interval'] as int? ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
    );
  }

  /// ID câu hỏi gốc trong ngân hàng 300 câu.
  final int questionId;

  /// Số lần nhớ liên tiếp thành công (grade >= 3).
  final int repetitions;

  /// Khoảng cách đến lần ôn tiếp theo (đơn vị: ngày).
  final int interval;

  /// Hệ số độ dễ (Ease Factor), mặc định 2.5, tối thiểu 1.3.
  final double easeFactor;

  /// Ngày đến hạn ôn tập tiếp theo.
  final DateTime nextReviewDate;

  /// Lần ôn tập gần nhất (null nếu chưa ôn lần nào).
  final DateTime? lastReviewedAt;

  /// Xuất dữ liệu ra JSON để lưu vào bộ nhớ cục bộ.
  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'repetitions': repetitions,
    'interval': interval,
    'easeFactor': easeFactor,
    'nextReviewDate': nextReviewDate.toIso8601String(),
    if (lastReviewedAt != null)
      'lastReviewedAt': lastReviewedAt!.toIso8601String(),
  };

  /// Kiểm tra thẻ đã đến hạn ôn tập chưa so với thời điểm [now].
  bool isDue([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final dueDate = DateTime(
      nextReviewDate.year,
      nextReviewDate.month,
      nextReviewDate.day,
    );
    return today.isAtSameMomentAs(dueDate) || today.isAfter(dueDate);
  }
}

/// Bộ tính toán thuật toán SuperMemo-2 (SM-2).
class Sm2 {
  const Sm2();

  /// Hệ số dễ tối thiểu theo chuẩn SM-2 để tránh khoảng cách bị thu hẹp vô hạn.
  static const double minEaseFactor = 1.3;

  /// Tính toán trạng thái thẻ tiếp theo dựa trên đánh giá nhớ [grade] (0 đến 5).
  ///
  /// Ý nghĩa mức điểm [grade]:
  /// - 5: Nhớ hoàn hảo, không do dự
  /// - 4: Nhớ đúng sau một chút đắn đo
  /// - 3: Nhớ đúng nhưng rất khó khăn
  /// - 2: Trả lời sai; đáp án đúng có vẻ dễ nhớ lại
  /// - 1: Trả lời sai; khi xem đáp án mới nhớ ra
  /// - 0: Quên hoàn toàn
  ///
  /// Quy tắc SM-2:
  /// 1. Nếu [grade] >= 3 (Nhớ thành công):
  ///    - Lần 1: interval = 1 ngày
  ///    - Lần 2: interval = 6 ngày
  ///    - Lần >= 3: interval = (interval_trước * EF).round()
  ///    - repetitions tăng 1
  /// 2. Nếu [grade] < 3 (Quên / Sai):
  ///    - repetitions = 0 (reset lại chuỗi)
  ///    - interval = 1 ngày
  /// 3. Tính lại Ease Factor (EF'):
  ///    EF' = EF + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02))
  ///    Nếu EF' < 1.3 thì EF' = 1.3
  Sm2Item review({
    required Sm2Item item,
    required int grade,
    DateTime? reviewDate,
  }) {
    RangeError.checkValueInInterval(grade, 0, 5, 'grade');
    final now = reviewDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Tính toán Ease Factor mới
    final double rawEf =
        item.easeFactor + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02));
    final double newEf = (rawEf < minEaseFactor ? minEaseFactor : rawEf);
    // Làm tròn 2 chữ số thập phân cho gọn và tránh sai số dấu phẩy động
    final double roundedEf = (newEf * 100).roundToDouble() / 100.0;

    int newRepetitions;
    int newInterval;

    // 2. Tính số lần lặp và khoảng cách ngày ôn
    if (grade >= 3) {
      if (item.repetitions == 0) {
        newInterval = 1;
      } else if (item.repetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (item.interval * roundedEf).round();
      }
      newRepetitions = item.repetitions + 1;
    } else {
      newRepetitions = 0;
      newInterval = 1;
    }

    final nextDate = today.add(Duration(days: newInterval));

    return Sm2Item(
      questionId: item.questionId,
      repetitions: newRepetitions,
      interval: newInterval,
      easeFactor: roundedEf,
      nextReviewDate: nextDate,
      lastReviewedAt: now,
    );
  }
}
