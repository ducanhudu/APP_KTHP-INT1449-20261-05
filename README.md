# Flutter Lab Android

[![CI](https://github.com/ducanhudu/APP_KTHP-INT1449-20261-05/actions/workflows/ci.yml/badge.svg)](https://github.com/ducanhudu/APP_KTHP-INT1449-20261-05/actions/workflows/ci.yml)

Ứng dụng Flutter/Dart ôn thi **đề 32**: đọc 300 câu trắc nghiệm Việt–Anh từ
`assets/flutter_quiz_300.json`, chạy được khi ngoại tuyến.

## Yêu cầu môi trường

| Thành phần | Phiên bản |
| --- | --- |
| Flutter | **3.47.6** (stable) trở lên |
| Dart | **3.13.5** trở lên (đi kèm Flutter 3.47.6) |
| JDK | 17 — đã khai báo trong `android/app/build.gradle.kts` |
| Android | thiết bị thật hoặc emulator, dùng `flutter.minSdkVersion` của SDK |

Kiểm tra môi trường trước khi chạy:

```powershell
flutter --version    # cần Flutter 3.47.6, Dart 3.13.5 trở lên
flutter doctor
```

Nếu `flutter pub get` báo `requires SDK version ^3.13.5`, Flutter trên máy cũ
hơn bản đã dùng để phát triển: chạy `flutter upgrade` rồi làm lại.

## Cài đặt và chạy

```powershell
flutter pub get
flutter devices        # xác nhận đã thấy điện thoại/emulator
flutter run
```

Chọn điện thoại Android đã bật USB debugging hoặc emulator đang chạy. Để tạo
APK debug, chạy `flutter build apk --debug`; APK nằm tại
`build/app/outputs/flutter-apk/app-debug.apk`.

## Kiểm tra chất lượng mã

```powershell
flutter analyze      # kết quả mong đợi: No issues found!
flutter test         # kết quả mong đợi: All tests passed! (2 test)
```

Kiểm tra ngân hàng câu hỏi (Python 3.9+, không cần thư viện ngoài):

```powershell
python tool/audit_question_bank.py assets/flutter_quiz_300.json
```

Kết quả kiểm tra ngày 18/11/2026 và các phát hiện về dữ liệu nằm trong
`docs/json-audit.md`.

### CI trên GitHub Actions

Mỗi lần đẩy mã lên `main`, `feature/**`, `fix/**`, `docs/**`, `test/**`,
`chore/**` hoặc mở pull request vào `main`, workflow
`.github/workflows/ci.yml` chạy hai việc song song:

| Job | Nội dung |
| --- | --- |
| `Analyze + Test` | `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test` trên Flutter 3.47.6 |
| `Audit question bank` | `python tool/audit_question_bank.py assets/flutter_quiz_300.json` |

Mã chỉ được coi là đạt khi cả hai job xanh.

Hai test hiện có:

| Test | Nội dung |
| --- | --- |
| `The real bank supports a unique 50-question exam and scoring by ID` | Nạp JSON thật, sinh đề 50 câu không trùng, chấm điểm và thống kê theo khối |
| `Practice submits answers by ID and preserves unanswered items` | Mở lượt luyện, chọn một đáp án, nộp bài, kiểm tra 4 câu còn lại là bỏ trống |

## Đã kiểm thử trên

| Môi trường | Kết quả |
| --- | --- |
| Android Emulator Pixel_8 · Android 17 (API 37) · 1080×2400 | Toàn bộ luồng luyện tập, thi thử, đổi ngôn ngữ, chấm điểm đạt; ảnh chụp trong `docs/screenshots/` |

Chi tiết thiết bị, kịch bản và phát hiện: `docs/device-notes.md`. Chưa kiểm thử
trên điện thoại Android thật.

## Dữ liệu lưu ở đâu

- **Ngân hàng câu hỏi**: tệp `assets/flutter_quiz_300.json` đóng gói trong APK,
  chỉ đọc, không sửa được lúc chạy.
- **Phiên làm bài, điểm, danh sách câu sai**: chỉ nằm trong bộ nhớ (RAM) của
  tiến trình. Đóng app là mất; **không có tệp nào được ghi ra**, không dùng cơ
  sở dữ liệu.
- **Quyền**: `AndroidManifest.xml` không khai báo `INTERNET` và không xin quyền
  nào, nên app không gửi dữ liệu ra ngoài. Bộ thẻ và lịch ôn của đề 33 sẽ bổ
  sung phần lưu trữ cục bộ sau.

## Phạm vi

- Luyện theo khối, chọn số câu và xem lời giải sau khi trả lời.
- Thi thử 50 câu từ toàn bộ ngân hàng, xáo trộn đáp án, đếm ngược 50 phút và tự
  nộp khi hết giờ.
- Đổi ngôn ngữ Việt, Anh hoặc song ngữ trong khi làm bài; đáp án đã chọn được
  giữ nguyên.
- Xem điểm, thống kê theo khối, lời giải và làm lại các câu đã trả lời sai.

Thống kê nhóm theo trường `topic` của JSON, tương ứng K01–K20. Bộ thẻ SM-2,
nhắc ôn hằng ngày và lưu trữ cục bộ thuộc phần triển khai tiếp theo (đề 33).

## Tài liệu kèm theo

| Tệp | Nội dung |
| --- | --- |
| `docs/rubric-checklist.md` | Bảng đối chiếu 8 tiêu chí rubric, điều kiện chấm, điểm cộng/trừ, checklist nộp bài |
| `docs/device-notes.md` | Thiết bị kiểm thử, 10 kịch bản đã chạy, phát hiện, kịch bản demo 5 phút |
| `docs/day-2-test-log.md` | Nhật ký kiểm thử Ngày 2: 31 test, kịch bản thẻ trên máy, 5 lỗi kèm bước tái hiện |
| `docs/json-audit.md` | Kết quả kiểm tra 300 câu và các phát hiện về dữ liệu |
| `docs/screenshots/` | Ảnh chụp các màn hình trên emulator |

## Cấu trúc thư mục

```
lib/main.dart              giao diện và luồng làm bài
lib/question.dart          mô hình câu hỏi, chấm điểm, thống kê
assets/flutter_quiz_300.json   300 câu song ngữ (20 khối K01–K20)
test/widget_test.dart      kiểm thử chấm điểm và luồng luyện tập
android/                   cấu hình Android (Kotlin DSL, Java 17)
```
