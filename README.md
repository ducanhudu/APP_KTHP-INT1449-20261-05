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
checksum và commit source trong 14 ngày. APK build trên máy có `android/key.properties`
được ký bằng keystore của nhóm; APK do CI tạo dùng debug signing vì runner không
có khoá. Xem hướng dẫn và cách kiểm chứng chữ ký trong `docs/release-handover.md`.

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

## Tài khoản & hồ sơ thành viên (demo)

App có luồng đăng nhập, đăng ký và trang **Thông tin thành viên** chạy ngay khi
chưa có backend, bằng bộ xác thực **mô phỏng** trên thiết bị (không dùng cho môi
trường thật). Mở từ nút avatar trên thanh tiêu đề.

- Tài khoản mẫu: `demo@example.com` / `Demo123!` (chỉ khi bật chế độ demo).
- Đăng nhập bằng email + mật khẩu, có nút hiện/ẩn mật khẩu và ghi nhớ đăng nhập.
- Nút "Tiếp tục với Google" hiện giao diện nhưng chưa tích hợp OAuth (không giả
  mạo đăng nhập thành công).
- Mật khẩu không lưu dạng văn bản: chỉ lưu muối (salt) + băm SHA-256.
- Cách bật/tắt demo và cấu hình Google OAuth: xem [docs/auth.md](docs/auth.md).

## Dữ liệu lưu ở đâu

- **Ngân hàng câu hỏi**: tệp `assets/flutter_quiz_300.json` đóng gói trong APK,
  chỉ đọc, không sửa được lúc chạy.
- **Phiên làm bài đang mở**: điểm và danh sách câu của lượt đang làm chỉ nằm trong
  bộ nhớ (RAM) của tiến trình; đóng app giữa lượt là mất lượt đó.
- **Lịch sử làm bài**: khi chưa đăng nhập, lưu trong `SharedPreferences`
  (tối đa 100 lượt). Khi đăng nhập backend, các lượt thuộc tài khoản được đồng bộ
  lên server và có bản cục bộ riêng theo tài khoản để dùng ngoại tuyến. Lịch sử
  khách vẫn ở thiết bị, không tự nhập vào tài khoản. Mở tài khoản từ biểu tượng
  người dùng trên thanh trên cùng.
- **Bộ thẻ SM-2 và lịch ôn**: lưu trong `SharedPreferences` của Android
  (`FlutterSharedPreferences.xml`), gồm danh sách thẻ, số lần lặp, khoảng cách,
  hệ số dễ, ngày đến hạn và trạng thái bật/tắt nhắc ôn. Gỡ app là mất dữ liệu.
- **Quyền**:
  - `POST_NOTIFICATIONS` — hỏi **đúng lúc** người dùng bật công tắc "Nhắc ôn hằng
    ngày", không hỏi khi mở app. Từ chối thì app vẫn dùng bình thường, chỉ không
    có thông báo.
  - `INTERNET` — dùng cho **Hỏi AI** và (chỉ sau khi người dùng chọn đăng ký/
    đăng nhập) xác thực, đồng bộ lịch sử với backend đã cấu hình. Chế độ khách vẫn
    lưu lịch sử cục bộ và không gửi dữ liệu học tập lên mạng.
  - `RECORD_AUDIO` — chỉ xin khi người dùng bấm **"Nhập bằng giọng nói"**; không
    hỏi lúc mở app. Từ chối thì vẫn nhập tay và tìm câu bình thường. Âm thanh do
    bộ nhận dạng của hệ điều hành xử lý; app không gửi âm thanh hay bản chép lời
    tới backend AI của nhóm.
  - `RECEIVE_BOOT_COMPLETED` — khôi phục lịch thông báo sau reboot/cập nhật APK,
    không có hộp thoại runtime riêng.

## Backend tài khoản và lịch sử (tuỳ chọn)

Server Node.js trong `server/` hỗ trợ đăng ký/đăng nhập, thu hồi phiên đăng xuất,
log auth events và lịch sử làm bài riêng theo tài khoản. Password dùng `scrypt`,
đáp án/điểm được xác thực lại theo ngân hàng câu hỏi. Server cần biến
`AUTH_JWT_SECRET` ngẫu nhiên (ít nhất 32 byte); dữ liệu mặc định ở
`server/data/store.json` và bị loại khỏi Git. Khởi chạy `node server/server.js`,
sau đó build app với `--dart-define=APP_API_URL=https://<server>` để hiện đăng
ký/đăng nhập. Android debug USB có thể dùng
`adb reverse tcp:8787 tcp:8787` và `APP_API_URL=http://127.0.0.1:8787`.

Backend hiện dùng tệp JSON và chỉ dành cho một process/instance; cần volume bền
vững, backup và HTTPS khi triển khai. Không chạy nhiều replicas cùng file. Môi
trường sản phẩm nên chuyển sang database giao dịch (PostgreSQL/SQLite) và lưu
JWT bằng kho bảo mật của hệ điều hành. Hướng dẫn API, biến môi trường và test ở
[`server/README.md`](server/README.md).

## Hỏi AI (tuỳ chọn)

Nút "Hỏi AI về câu này" gọi `AiService` (`lib/ai_service.dart`):

- **Giải thích câu trong đề:** mặc định không gọi mạng; URL đọc từ `--dart-define=AI_API_URL=...`. Bỏ trống thì app dùng lời giải gốc trong JSON (`explanation_vi` / `explanation_en`).
- **Hỏi AI tự do:** mặc định dùng proxy `https://flutterlab-ai-proxy.onrender.com/ask`; có thể thay bằng `AI_ASK_API_URL` hoặc `AI_API_URL`. Trang sẽ yêu cầu mã `AI_ACCESS_CODE` của nhóm.
- **Không có khoá API trong repo.** Repo không chứa key, token hay mật khẩu. Khoá
  nằm ở **server** (`server/server.js`); app chỉ biết URL của server đó, truyền vào
  lúc build bằng `--dart-define=AI_API_URL=https://.../explain`.
- **Proxy giữ khoá** có sẵn trong `server/`: không cần `npm install`, chạy bằng
  `node server/server.js`, đọc khoá từ biến môi trường `GEMINI_API_KEY`. Xem
  `server/README.md` để biết cách chạy thử bằng stub, chạy thật và đưa lên host.
- **Deploy lên mạng**: `Dockerfile` ở gốc repo chạy được trên Render, Railway,
  Cloud Run hoặc VPS có TLS; hướng dẫn từng bước và cách kiểm tra trong
  `docs/deploy-ai.md`.
- Server yêu cầu `AI_ACCESS_CODE`; nhập mã nhóm qua nút "Mã truy cập AI" trong
  panel. App chỉ gửi mã câu/ngôn ngữ, server tạo prompt từ dữ liệu tin cậy.
  Mã nhập chỉ ở RAM, không đóng gói trong APK. Xem giới hạn demo trong server/README.
- Gọi lỗi, quá 65 giây hoặc mất mạng đều rơi về lời giải gốc. Có thể đóng panel
  trong lúc chờ. Server giới hạn mỗi lần gọi nhà cung cấp trong 55 giây.
- Nút "Nghe lời giải" dùng `flutter_tts` để đọc phần giải thích; máy không có
  engine đọc tiếng thì nút báo lỗi và phần chữ vẫn dùng bình thường.

## Phạm vi

### Camera học tập

Mở biểu tượng camera hoặc Hôm nay → Camera học tập. Chọn **Đọc chữ** hoặc
**Mã QR**, sau đó **Chụp ảnh / Chọn ảnh**. Với OCR, sửa chữ rồi bấm **Tìm trong
300 câu**, chọn một gợi ý để xem lời giải, lưu thẻ hoặc chủ động hỏi AI.

Ảnh được xử lý trên thiết bị, không gửi tới backend AI. QR được đọc từ ảnh,
chỉ hỗ trợ `flutterlab://question/81` hoặc mã câu có trong JSON như `K01-001`.
Không tự mở website từ QR. Camera hệ thống và bộ chọn ảnh Android xử lý phần
chụp/chọn; app không xin quyền đọc toàn bộ thư viện ảnh.

Ảnh ngoài ngân hàng có thể không tìm thấy kết quả. Chữ viết tay, ảnh quá mờ,
cắt/xoay ảnh và QR preview trực tiếp chưa thuộc bản đầu. Nếu Android thu hồi
tiến trình lúc chụp, mở lại Camera để khôi phục ảnh có thể còn trong picker.

Kế hoạch và tác dụng: [docs/camera-development-plan.md](docs/camera-development-plan.md).
Kết quả kiểm tra: [docs/camera-validation.md](docs/camera-validation.md).

### Nhập bằng giọng nói

Trong Camera học tập → **Đọc chữ**, bấm **Nhập bằng giọng nói** rồi nói câu hỏi.
Chữ nhận được điền vào ô nhập để bạn **kiểm tra và sửa trước khi** bấm *Tìm trong
300 câu*: app không tự tìm, không tự gửi gì lên AI. Nội dung đã có trong ô được
giữ lại và nối thêm, không bị xoá.

Lần đầu dùng, Android hỏi quyền micro. **Từ chối thì vẫn nhập tay và tìm câu bình
thường.** Ngôn ngữ nhận dạng đi theo ngôn ngữ giao diện (Việt/Anh); máy không có
bộ nhận dạng tương ứng thì app báo rõ và vẫn cho nhập tay. Âm thanh do bộ nhận
dạng của hệ điều hành xử lý (tuỳ thiết bị có thể là nhận dạng trên máy hoặc dịch
vụ của Google); app không gửi âm thanh hay bản chép lời tới backend AI của nhóm.

Phạm vi và cách nghiệm thu: [docs/speech-input.md](docs/speech-input.md).

### Ôn tập

- Luyện theo khối, chọn số câu và xem lời giải sau khi trả lời.
- Thi thử 50 câu từ toàn bộ ngân hàng, xáo trộn đáp án, đếm ngược 50 phút và tự
  nộp khi hết giờ.
- Đổi ngôn ngữ Việt, Anh hoặc song ngữ trong khi làm bài; đáp án đã chọn được
  giữ nguyên.
- Xem điểm, thống kê theo khối, lời giải và làm lại các câu đã trả lời sai.
- Bộ thẻ ghi nhớ SM-2: lưu câu sai thành thẻ, ôn theo lịch đến hạn, đánh giá 1/3/4/5.
- Lịch sử làm bài: mỗi lượt hoàn thành được lưu lại (tối đa 100 lượt), lọc theo
  luyện tập/thi thử, xem lại điểm và xoá từng lượt hoặc xoá tất cả.
- Luyện theo điểm yếu: tab Hôm nay gợi ý ba khối yếu nhất từ lịch sử và bộ thẻ,
  nút "Luyện 10 câu điểm yếu" ưu tiên câu từng sai trong khối yếu.
- Nhắc ôn hằng ngày bằng thông báo cục bộ, bật/tắt trong màn hình Hôm nay.
- Giao diện hai ngôn ngữ: đổi sang English thì **nhãn giao diện** cũng đổi, không
  chỉ nội dung câu hỏi.

## Tài liệu kèm theo

| Tệp | Nội dung |
| --- | --- |
| `docs/rubric-checklist.md` | Đối chiếu đề 32/33, bằng chứng và điều kiện chờ xác nhận |
| `docs/release-handover.md` | Branch bàn giao, kiểm tra và nghiệm thu APK còn chờ |
| `docs/physical-device-acceptance-2026-11-21.md` | Kết quả thử APK release trên OPPO Android 16, ảnh và các mục chưa nghiệm thu |
| `docs/final-report.md` | Nội dung báo cáo để nhóm đưa vào mẫu môn học |
| `docs/defense-script.md` | Kịch bản demo 5 phút và dàn ý slide |
| `docs/device-notes.md` | Thiết bị kiểm thử, 10 kịch bản đã chạy, phát hiện, kịch bản demo 5 phút |
| `docs/day-2-test-log.md` | Nhật ký kiểm thử Ngày 2: 31 test, kịch bản thẻ trên máy, 5 lỗi kèm bước tái hiện |
| `docs/json-audit.md` | Kết quả kiểm tra 300 câu và các phát hiện về dữ liệu |
| `docs/auth.md` | Hướng dẫn đăng nhập/đăng ký, bật/tắt chế độ demo và cấu hình Google OAuth |
| `docs/screenshots/` | Ảnh chụp các màn hình trên emulator |

## Cấu trúc thư mục

```
lib/main.dart                 giao diện, luồng luyện/thi, kết quả và xem lại
lib/question.dart             mô hình câu hỏi, chấm điểm, thống kê, tên khối
lib/camera_study_page.dart    màn camera: ảnh, OCR, QR, gợi ý câu
lib/question_search.dart      chuẩn hoá chữ Việt/Anh, xếp hạng câu, kiểm mã QR
lib/study_image_service.dart  chụp/chọn ảnh và gọi ML Kit (có bản giả cho test)
lib/history_page.dart         màn lịch sử làm bài
lib/history_storage.dart      lưu lượt làm bài (SharedPreferences + bản giả)
lib/quiz_attempt.dart         bản ghi một lượt làm bài và JSON
lib/weakness_analyzer.dart    phân tích khối yếu, chọn câu luyện thích ứng
lib/app_strings.dart          nhãn giao diện Việt/Anh
lib/auth_user.dart            mô hình hồ sơ thành viên (không chứa mật khẩu)
lib/auth_service.dart         xác thực demo mô phỏng (tài khoản mẫu, Google stub)
lib/auth_controller.dart      trạng thái đăng nhập cho giao diện
lib/auth_pages.dart           trang đăng nhập, đăng ký, nút Google
lib/profile_page.dart         trang thông tin thành viên (ảnh đại diện, đăng xuất)
assets/flutter_quiz_300.json  300 câu song ngữ (20 khối K01–K20)
test/                         kiểm thử unit và widget
integration_test/             kiểm thử native trên thiết bị (camera OCR/QR)
android/                      cấu hình Android (Kotlin DSL, Java 17)
```
