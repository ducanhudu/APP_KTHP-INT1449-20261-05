# Nhập câu hỏi bằng giọng nói

## Mục tiêu

Bổ sung cách nhập câu hỏi thứ ba (sau ảnh và bàn phím) để sinh viên tìm được câu
trong ngân hàng 300 câu mà không phải gõ lại, đồng thời hoàn thiện mục **mic**
trong [rubric-checklist.md](rubric-checklist.md): *chép lời, sửa trước khi gửi,
từ chối quyền vẫn nhập tay được*.

Giọng nói ở đây chỉ là **công cụ nhập liệu**, không phải kênh hỏi AI: bản chép
lời nằm trong ô nhập để người dùng sửa, sau đó mới tìm câu. Không tự động tìm và
không tự động gửi nội dung đi đâu.

## Luồng sử dụng

1. Hôm nay → Camera học tập (hoặc biểu tượng camera trên thanh trên cùng).
2. Chọn **Đọc chữ** → bấm **Nhập bằng giọng nói**.
3. Nói câu hỏi; chữ hiện dần trong ô nhập.
4. Bấm **Dừng ghi âm** hoặc để micro tự dừng; kiểm tra và sửa chữ.
5. Bấm **Tìm trong 300 câu** rồi chọn câu gợi ý như luồng OCR.

## Phạm vi bản này

- Một lượt nghe tối đa 60 giây, tự dừng sau 3 giây im lặng.
- Chữ đã có trong ô được giữ và nối thêm, không bị xoá khi bắt đầu nói.
- Ngôn ngữ nhận dạng chọn theo ngôn ngữ giao diện: tiếng Việt → locale `vi*`,
  English → `en*`. Không có locale phù hợp thì để hệ thống quyết định.
- Quyền micro chỉ được hỏi ở lần bấm nút đầu tiên, không hỏi lúc mở app.
- Từ chối quyền, máy không có bộ nhận dạng, bộ nhận dạng bận hoặc không nghe rõ
  đều có thông báo riêng bằng ngôn ngữ đang chọn; ô nhập vẫn dùng được.
- Không lưu âm thanh, không gửi âm thanh hay bản chép lời tới backend AI của nhóm.

## Quyền và riêng tư

`RECORD_AUDIO` khai báo trong `android/app/src/main/AndroidManifest.xml`. App
không giữ bản ghi âm. Việc nhận dạng do bộ nhận dạng của hệ điều hành thực hiện;
tuỳ thiết bị và tuỳ bộ nhận dạng đã cài, âm thanh có thể được xử lý trên máy
hoặc qua dịch vụ nhận dạng của Google. Vì vậy **không** mô tả tính năng này là
"xử lý hoàn toàn trên thiết bị" như OCR/QR.

## Cấu trúc

| Tệp | Trách nhiệm |
| --- | --- |
| `lib/speech_input_service.dart` | Interface `SpeechInputService`, bản native dùng `speech_to_text`, ánh xạ lỗi sang `SpeechInputFailure` |
| `lib/camera_study_page.dart` | Nút micro, trạng thái đang nghe, chép lời vào ô nhập, không tự tìm |
| `test/speech_input_test.dart` | Fake service: chép lời, không tự tìm, từ chối quyền, dừng ghi âm, giải phóng micro, chọn ngôn ngữ |

Interface tách khỏi plugin đúng như `StudyImageService`, nên widget test không
cần micro thật và không phụ thuộc thiết bị.

## Kiểm thử đã chạy

| Kiểm tra | Kết quả |
| --- | --- |
| `dart format lib test` | Không đổi tệp nào |
| `flutter analyze` | No issues found |
| `flutter test` | 88 test đạt; 5 test mới cho giọng nói |
| Build APK debug | Xem kết quả ghi ở mục dưới khi chạy lại |

Các ca đã có test tự động:

- Nói xong chữ vào ô nhập nhưng **không** tự hiện kết quả tìm; chỉ khi bấm tìm.
- Từ chối quyền micro → thông báo rõ, vẫn nhập tay và tìm được câu.
- Bấm dừng ghi âm giữ nguyên chữ đã nhận, nút trở lại trạng thái ban đầu.
- Rời trang khi đang nghe → service được giải phóng, không lỗi widget đã hủy.
- Giao diện English yêu cầu bộ nhận dạng tiếng Anh.

## Còn phải nghiệm thu trên máy thật

Những điểm sau **chưa** được kiểm tra trong môi trường phát triển này:

- Micro thật trên Android: quyền, tiếng Việt có dấu, và việc máy có bộ nhận dạng
  tiếng Việt hay không.
- Hành vi khi có cuộc gọi đến hoặc ứng dụng khác chiếm micro.
- Tai nghe Bluetooth: plugin cần thêm quyền `BLUETOOTH_CONNECT` cho một số máy;
  bản này chưa khai báo, nên micro tai nghe có thể không dùng được.

Cách kiểm tra trên thiết bị:

```powershell
flutter run
# Mở Camera học tập → Đọc chữ → Nhập bằng giọng nói
```

Nên thử lần lượt: đồng ý quyền, từ chối quyền, nói câu tiếng Việt có dấu, nói
tiếng Anh sau khi đổi ngôn ngữ, bấm dừng giữa lúc nói, và thoát trang khi đang
nghe.

### Kết quả thử trên emulator (Android 37.2, Play Store, x86_64)

Đã chạy trên AVD `flutter_lab` để tách lỗi môi trường khỏi lỗi code:

| Hạng mục | Kết quả |
| --- | --- |
| Cài APK debug, mở app | Đạt; activity chạy bình thường |
| Xin quyền `RECORD_AUDIO` | Đạt; quyền cấp được, `initialize()` trả `true` |
| Phiên nghe | Đạt; trạng thái `listening → notListening → done` |
| Nhận chữ thật | **Không đạt trên emulator**: mọi locale trả `error_too_many_requests` |
| Gói ngôn ngữ on-device | Thiếu: `error_language_unavailable` |

Nguyên nhân là môi trường, không phải app: image này route nhận dạng qua dịch vụ
hệ thống (AiAi/`com.google.android.as`) và dịch vụ đó chưa có gói ngôn ngữ; khi
gọi bản qua mạng thì Google trả `error_too_many_requests` (emulator thường bị giới
hạn). Đặt `voice_recognition_service` sang `GoogleRecognitionService` của Google
app cũng không giải quyết: hệ thống báo `Bind to system recognition service failed
with error 10`.

Kết luận: emulator dùng để xem giao diện, luồng xin quyền và câu thông báo lỗi;
**phải dùng điện thoại thật để nghiệm thu nhận chữ**.

### Integration test cho phần native

`integration_test/speech_native_test.dart` kiểm tra quyền + khởi tạo + một phiên
nghe. Không thể "nói" bằng máy nên test này chỉ chặn hai lỗi hỏng thật là
`permissionDenied` và `unavailable`; `noMatch`/hết thời gian là bình thường khi
im lặng.

```powershell
# cần cấp quyền trước, nếu không hộp thoại quyền sẽ chặn test
adb shell pm grant vn.flutterlab.flutter_quiz_app android.permission.RECORD_AUDIO
flutter test integration_test/speech_native_test.dart -d DEVICE_ID --no-uninstall
```

`--no-uninstall` để giữ app và dữ liệu trên máy sau khi chạy.

## Hướng phát triển

- Thêm `BLUETOOTH_CONNECT` (và kiểm tra lại trên Android 12+) nếu cần micro tai
  nghe.
- Đọc to câu hỏi bằng TTS có sẵn để người dùng nghe lại trước khi tìm.
- Lưu lịch sử các câu đã tìm bằng giọng nói nếu nhóm muốn đo mức dùng tính năng.
