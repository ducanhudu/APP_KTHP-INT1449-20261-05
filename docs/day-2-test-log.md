# Nhật ký kiểm thử Ngày 2

Tài liệu nghiệm thu Ngày 2 (vai trò Kiểm thử và sửa lỗi). Ghi lại kết quả kiểm thử
tự động và kiểm thử tay cho luồng luyện tập, chấm điểm, lưu thẻ và tính lịch SM-2.

## Môi trường

| Hạng mục | Giá trị |
| --- | --- |
| Flutter / Dart | 3.47.6 stable / 3.13.5 |
| Thiết bị kiểm thử tay | Android Emulator Pixel_8, Android 17 (API 37), 1080×2400 |
| Nhánh | `test/day-2-extra-tests` (commit `af48410`) |
| Thời điểm | 19/11/2026 |

## 1. Kiểm thử tự động

```
flutter test  →  30/30 All tests passed
flutter analyze →  No issues found!
dart format --set-exit-if-changed lib test →  0 changed
```

| Tệp | Số test | Phủ nội dung | Kết quả |
| --- | --- | --- | --- |
| `test/widget_test.dart` | 4 | Nạp JSON thật, chặn dữ liệu song ngữ rỗng, sinh đề 50 câu, nộp bài theo ID, lưu câu sai vào bộ thẻ | ✅ |
| `test/scoring_test.dart` | 3 | Chấm 1 đúng + 1 sai + 1 bỏ trống, nộp bài trắng, nộp đúng 100% | ✅ |
| `test/sm2_test.dart` | 6 | Trạng thái thẻ mới, chuỗi 1 → 6 → `interval × EF`, reset khi grade < 3, sàn EF 1.3, `isDue`, JSON round-trip | ✅ |
| `test/card_storage_test.dart` | 7 | Tầng lưu trữ giả (`MemoryCardStorage`): thêm, chống trùng, cập nhật, xoá, xoá sạch, JSON | ✅ |
| `test/card_storage_prefs_test.dart` | 7 | **Tầng lưu trữ thật** (`SharedPrefsCardStorage`): ghi rồi đọc lại bằng instance mới, mở lại app vẫn còn thẻ và lịch SM-2, xoá, JSON hỏng | ✅ |
| `test/quiz_flow_test.dart` | 3 | Xáo trộn lựa chọn, làm lại câu sai, widget nộp bài trắng | ✅ |

### Ba test bổ sung trong Ngày 2

| Test | Vì sao cần |
| --- | --- |
| Xáo trộn lựa chọn (12 seed phải ra ≥ 2 thứ tự, vẫn đủ A–D, đáp án đúng không đổi, mảng gốc không bị xáo) | Trước đó không có test nào khoá hành vi `QuizItem` shuffle |
| `wrongQuestions` chỉ gồm câu chọn sai, bỏ qua câu bỏ trống | Khoá logic của nút "Làm lại N câu sai" |
| Widget: nộp bài trắng hiện `0%`, không hiện nút "Làm lại" | Widget test thứ hai cho luồng chính |

### Một lỗi test bắt được khi viết

`find.text('0%')` khớp **4 widget** vì màn kết quả hiện `0%` ở điểm tổng **và** ở
từng dòng thống kê theo khối. Đã đổi sang `findsWidgets` và giữ assertion mạnh ở
dòng `'0 đúng · 0 sai · 3 bỏ trống'` (duy nhất). Đây là ví dụ cho câu vấn đáp
*"test nào bắt được lỗi thật trong quá trình làm"*.

## 2. Kiểm thử tay trên máy

Kịch bản đầu-cuối cho đề 33, chạy trên emulator Pixel_8 (Android 17, API 37),
bản build `app-debug.apk` từ nhánh `test/day-2-extra-tests`.

| # | Bước | Kết quả | Ảnh |
| --- | --- | --- | --- |
| 1 | Luyện 5 câu, chọn A cho cả 5 câu | "Câu 1/5", 4 lựa chọn A–D, nút trước/sau/nộp | `08-flashcard-practice.png` |
| 2 | Nộp bài | **0% · 0 đúng · 5 sai · 0 bỏ trống**; có nút **"Lưu 5 câu sai vào thẻ"** và từng câu có "Lưu câu này vào bộ thẻ" | `09-flashcard-result.png` |
| 3 | Bấm "Lưu 5 câu sai vào thẻ" | Ghi vào `shared_prefs/FlutterSharedPreferences.xml`: 5 thẻ (id 271, 64, 235, 51, 123), `nextReviewDate = 19/11` | `10-save-cards.png` |
| 4 | Quay về màn hình chính | ❌ **Vẫn hiện "0 thẻ đã lưu"** — bộ đếm không tự cập nhật (lỗi 5 bên dưới) | `11-home-stale-count.png` |
| 5 | Tắt hẳn app, mở lại | ✅ **"5 thẻ đã lưu · 5 thẻ cần ôn hôm nay"** — dữ liệu bền vững | `12-home-after-reopen.png` |
| 6 | Vào "Ôn tập Flashcard (SM-2)" | "Thẻ 1/5", thanh lọc Đến hạn / Tất cả, hiện `Lặp: 0 lần · Cách: 0 ngày · Hạn: 19/11 (EF: 2.5)` | `13-flashcard-study.png` |
| 7 | Bấm "Xem đáp án & giải thích" | Hiện **"Đáp án đúng: C"** kèm lời giải thích đầy đủ | — |
| 8 | Đánh giá "5: Rất dễ" | Lưu đúng theo SM-2: `repetitions 1`, `interval 1`, `easeFactor 2.6`, `nextReviewDate 20/11`, có `lastReviewedAt` | `14-flashcard-graded.png` |
| 9 | Tắt app, mở lại lần nữa | ✅ **"5 thẻ đã lưu · 4 thẻ cần ôn hôm nay"**; vào bộ thẻ hiện **"Thẻ 1/4"** — thẻ vừa ôn đã dời sang 20/11 | `15-home-due-decreased.png`, `16-flashcard-after-reopen.png` |

Dữ liệu cuối cùng trong `SharedPreferences` sau khi chạy:

| questionId | repetitions | interval | easeFactor | nextReviewDate |
| --- | --- | --- | --- | --- |
| 271 | 1 | 1 | 2.6 | 20/11/2026 |
| 64 | 0 | 0 | 2.5 | 19/11/2026 |
| 235 | 0 | 0 | 2.5 | 19/11/2026 |
| 51 | 0 | 0 | 2.5 | 19/11/2026 |
| 123 | 0 | 0 | 2.5 | 19/11/2026 |

Khớp đúng công thức SM-2 và khớp với `test/sm2_test.dart`.

## 2b. Sự cố môi trường gặp trong ngày

| Sự cố | Nguyên nhân | Cách xử lý |
| --- | --- | --- |
| Emulator không chịu khởi động | Ổ C: chỉ còn 0,9 GB; emulator báo *"Your device does not have enough disk space"* | Xoá snapshot AVD, `build/`, Temp; tạo lại AVD trên **D:\AndroidAvd** (`ANDROID_AVD_HOME`) |
| `flutter build apk` lỗi `Gradle task assembleDebug failed` | `JAVA_HOME` trỏ tới `jdk-17` đã bị xoá | Đặt `JAVA_HOME` về JDK đi kèm Android Studio: `C:\Program Files\Android\Android Studio\jbr` |

Hai lỗi này không phải lỗi mã nguồn, nhưng nếu không ghi lại thì người khác build
sẽ gặp y hệt — nên đã bổ sung vào `docs/device-notes.md`.

## 3. Lỗi phát hiện và bước tái hiện

| # | Lỗi | Bước tái hiện | Mức | Trạng thái |
| --- | --- | --- | --- | --- |
| 1 | Nhãn giao diện chưa song ngữ: chọn English chỉ đổi nội dung câu hỏi, còn "Câu 2/5", "Nộp bài", "Kết quả" vẫn tiếng Việt | Luyện tập → nút dịch → English | Trung bình (mất điểm cộng +2) | Chưa sửa |
| 2 | Màn hình lỗi không có nút thử lại | Đổi tên `assets/flutter_quiz_300.json` rồi build lại | Trung bình (rubric yêu cầu mỗi trạng thái có lối ra) | Chưa sửa |
| 3 | ~~Tầng lưu trữ thật không có test~~ | — | Cao | **Đã sửa**: thêm `card_storage_prefs_test.dart` |
| 4 | Cảnh báo `totalDue` không dùng làm `flutter analyze` báo lỗi | `flutter analyze` trên nhánh `feat/flashcard-sm2-storage` | Cao (chặn CI) | **Đã sửa**: nhánh `fix/flashcard-unused-totaldue` |
| 5 | **Bộ đếm thẻ trên màn hình chính không cập nhật sau khi lưu thẻ** | Luyện 5 câu → nộp → "Lưu 5 câu sai vào thẻ" → bấm Back về màn hình chính: vẫn hiện "0 thẻ đã lưu"; phải tắt hẳn app mở lại mới thấy "5 thẻ đã lưu" | Cao (ảnh hưởng kịch bản demo) | Chưa sửa |

## 4. Việc tiếp theo

- Nhắc ôn hằng ngày (`flutter_local_notifications`) — tính năng cuối cùng còn
  thiếu của đề 33.
- Xin quyền thông báo đúng lúc bật nhắc ôn, không xin lúc mở app.
- Sửa lỗi 1 và 2 ở bảng trên.
