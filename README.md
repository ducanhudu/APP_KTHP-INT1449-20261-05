# Flutter Lab Android

[![CI](https://github.com/ducanhudu/APP_KTHP-INT1449-20261-05/actions/workflows/ci.yml/badge.svg)](https://github.com/ducanhudu/APP_KTHP-INT1449-20261-05/actions/workflows/ci.yml)

Ứng dụng Flutter/Dart ôn thi **đề 32 + 33**: đọc 300 câu trắc nghiệm Việt–Anh từ
`assets/flutter_quiz_300.json`, chạy được khi ngoại tuyến.

## Yêu cầu môi trường

| Thành phần | Phiên bản |
| --- | --- |
| Flutter | **3.47.6 stable** để đồng bộ CI; đã chạy cục bộ bằng 3.47.8 |
| Dart | Dùng bản đi kèm Flutter; yêu cầu **^3.13.5** |
| JDK chạy Gradle | CI dùng **JDK 21**; máy phát triển có thể dùng JDK tương thích đi kèm Android Studio |
| Android SDK | API 36, Build-Tools 36.0.0, NDK 28.2.13676358, CMake 3.22.1 |
| Thiết bị chạy app | Android API 24 trở lên, thiết bị thật hoặc emulator |

Java 17 trong `android/app/build.gradle.kts` là mức biên dịch mã Java/Kotlin.
JDK dùng để chạy Gradle được Flutter/Android Studio chọn trên từng máy.
Xem JDK thực tế bằng `flutter doctor -v`.

Kiểm tra môi trường trước khi chạy:

```powershell
flutter --version    # cần Flutter 3.47.6, Dart 3.13.5 trở lên
flutter doctor -v
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

### Chạy sau khi pull trên máy thành viên

```text
git pull --ff-only origin main
flutter pub get
flutter devices
flutter run
```

Trong Android Studio, mở thư mục gốc chứa `pubspec.yaml`, cài plugin Flutter/Dart
và chọn Flutter SDK của máy. Cài các thành phần SDK ở bảng trên bằng SDK Manager.
Mỗi người tự đọc và chấp nhận Android SDK licenses qua
`flutter doctor --android-licenses` nếu máy chưa thiết lập.

Đường dẫn máy cá nhân nằm trong `android/local.properties`, được Flutter tạo
khi chuẩn bị/chạy bản Android và đã được loại khỏi Git. Mỗi máy dùng SDK của mình.

`android/gradle.properties` đã đặt `kotlin.incremental=false` và
`kotlin.compiler.execution.strategy=in-process` để xử lý lỗi Kotlin cache khi
Pub Cache và dự án nằm trên hai ổ đĩa khác nhau. Đây là cấu hình chung của repo,
có hiệu lực cả với nút Run trong Android Studio. Biên dịch Kotlin có thể chậm hơn.
Máy từng gặp lỗi cache nên chạy `flutter clean`, rồi `flutter pub get` một lần
trước khi chạy lại.

## Kiểm tra chất lượng mã

```powershell
flutter analyze      # kết quả mong đợi: No issues found!
flutter test         # kết quả mong đợi: All tests passed!
```

Kiểm tra ngân hàng câu hỏi (Python 3.9+, không cần thư viện ngoài):

```powershell
python tool/audit_question_bank.py assets/flutter_quiz_300.json
```

Kết quả kiểm tra ngày 18/11/2026 và các phát hiện về dữ liệu nằm trong
`docs/json-audit.md`.

### CI trên GitHub Actions

Mỗi lần đẩy mã lên `main`, `feat/**`, `feature/**`, `fix/**`, `docs/**`, `test/**`,
`chore/**` hoặc mở pull request vào `main`, workflow
`.github/workflows/ci.yml` kiểm tra mã, dữ liệu và build Android:

| Job | Nội dung |
| --- | --- |
| `Analyze + Test` | `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test` trên Flutter 3.47.6 |
| `Audit question bank` | `python tool/audit_question_bank.py assets/flutter_quiz_300.json` |
| `Build APK` | Build APK từ checkout mới trên Windows và Linux, sau khi Analyze + Test đạt |
| `AI proxy security tests` | Node.js 22 chạy test xác thực, phạm vi câu hỏi, quota và cache bằng upstream giả |

Job Linux cũng build release và lưu artifact `flutter-lab-release-<SHA>` kèm
checksum và commit source trong 14 ngày. APK hiện ký debug để demo; xem hướng
dẫn tải và giới hạn chữ ký trong `docs/release-handover.md`.

Đối chiếu kết quả từng job trong GitHub Actions. Job build kiểm tra khả năng
biên dịch APK; chạy thử giao diện trên thiết bị được kiểm tra riêng.

Một số ca kiểm thử tiêu biểu (danh sách đầy đủ trong thư mục `test/`):

| Test | Nội dung |
| --- | --- |
| `The real bank supports a unique 50-question exam and scoring by ID` | Nạp JSON thật, sinh đề 50 câu không trùng, chấm điểm và thống kê theo khối |
| `Practice submits answers by ID and preserves unanswered items` | Mở lượt luyện, chọn một đáp án, nộp bài, kiểm tra 4 câu còn lại là bỏ trống |

## Đã kiểm thử trên

| Môi trường | Kết quả |
| --- | --- |
| Android Emulator Pixel_8 · Android 17 (API 37) · 1080×2400 | Toàn bộ luồng luyện tập, thi thử, đổi ngôn ngữ, chấm điểm đạt; ảnh chụp trong `docs/screenshots/` |

Chi tiết kiểm thử lịch sử: `docs/device-notes.md`. Bản trước đợt sửa cuối đã
cài/mở trên OPPO CPH2599. Nghiệm thu APK mới và các ca còn chờ xem
`docs/release-handover.md`; chưa suy kết quả bản cũ cho bản mới.

## Dữ liệu lưu ở đâu

- **Ngân hàng câu hỏi**: tệp `assets/flutter_quiz_300.json` đóng gói trong APK,
  chỉ đọc, không sửa được lúc chạy.
- **Phiên làm bài, điểm, danh sách câu sai**: chỉ nằm trong bộ nhớ (RAM) của
  tiến trình. Đóng app là mất; **không có tệp nào được ghi ra**, không dùng cơ
  sở dữ liệu.
- **Bộ thẻ SM-2 và lịch ôn**: lưu trong `SharedPreferences` của Android
  (`FlutterSharedPreferences.xml`), gồm danh sách thẻ, số lần lặp, khoảng cách,
  hệ số dễ, ngày đến hạn và trạng thái bật/tắt nhắc ôn. Gỡ app là mất dữ liệu.
- **Quyền**:
  - `POST_NOTIFICATIONS` — hỏi **đúng lúc** người dùng bật công tắc "Nhắc ôn hằng
    ngày", không hỏi khi mở app. Từ chối thì app vẫn dùng bình thường, chỉ không
    có thông báo.
  - `INTERNET` — chỉ dùng cho nút **"Hỏi AI"**. Không bấm thì không có request nào
    rời khỏi máy: ngân hàng câu hỏi, bộ thẻ và điểm đều nằm trong app.
  - `RECEIVE_BOOT_COMPLETED` — khôi phục lịch thông báo sau reboot/cập nhật APK,
    không có hộp thoại runtime riêng.

## Hỏi AI (tuỳ chọn)

Nút "Hỏi AI về câu này" gọi `AiService` (`lib/ai_service.dart`):

- **Mặc định không gọi mạng.** URL đọc từ `--dart-define=AI_API_URL=...`; bỏ trống
  thì app trả về **lời giải gốc** trong JSON (`explanation_vi` / `explanation_en`)
  và hiện nhãn "Lời giải gốc". Nhờ vậy bản nộp chạy được khi không có backend.
- **Không có khoá API trong repo.** Repo không chứa key, token hay mật khẩu. Khoá
  nằm ở **server** (`server/server.js`); app chỉ biết URL của server đó, truyền vào
  lúc build bằng `--dart-define=AI_API_URL=https://.../explain`.
- **Proxy giữ khoá** có sẵn trong `server/`: không cần `npm install`, chạy bằng
  `node server/server.js`, đọc khoá từ biến môi trường `GEMINI_API_KEY`. Xem
  `server/README.md` để biết cách chạy thử bằng stub, chạy thật và đưa lên host.
- Server yêu cầu `AI_ACCESS_CODE`; nhập mã nhóm qua nút "Mã truy cập AI" trong
  panel. App chỉ gửi mã câu/ngôn ngữ, server tạo prompt từ dữ liệu tin cậy.
  Mã nhập chỉ ở RAM, không đóng gói trong APK. Xem giới hạn demo trong server/README.
- Gọi lỗi, quá 65 giây hoặc mất mạng đều rơi về lời giải gốc. Có thể đóng panel
  trong lúc chờ. Server giới hạn mỗi lần gọi nhà cung cấp trong 55 giây.
- Nút "Nghe lời giải" dùng `flutter_tts` để đọc phần giải thích; máy không có
  engine đọc tiếng thì nút báo lỗi và phần chữ vẫn dùng bình thường.

## Phạm vi

- Luyện theo khối, chọn số câu và xem lời giải sau khi trả lời.
- Thi thử 50 câu từ toàn bộ ngân hàng, xáo trộn đáp án, đếm ngược 50 phút và tự
  nộp khi hết giờ.
- Đổi ngôn ngữ Việt, Anh hoặc song ngữ trong khi làm bài; đáp án đã chọn được
  giữ nguyên.
- Xem điểm, thống kê theo khối, lời giải và làm lại các câu đã trả lời sai.
- Bộ thẻ ghi nhớ SM-2: lưu câu sai thành thẻ, ôn theo lịch đến hạn, đánh giá 1/3/4/5.
- Nhắc ôn hằng ngày bằng thông báo cục bộ, bật/tắt trong màn hình Hôm nay.
- Giao diện hai ngôn ngữ: đổi sang English thì **nhãn giao diện** cũng đổi, không
  chỉ nội dung câu hỏi.

## Tài liệu kèm theo

| Tệp | Nội dung |
| --- | --- |
| `docs/rubric-checklist.md` | Đối chiếu đề 32/33, bằng chứng và điều kiện chờ xác nhận |
| `docs/release-handover.md` | Branch bàn giao, kiểm tra và nghiệm thu APK còn chờ |
| `docs/final-report.md` | Nội dung báo cáo để nhóm đưa vào mẫu môn học |
| `docs/defense-script.md` | Kịch bản demo 5 phút và dàn ý slide |
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
