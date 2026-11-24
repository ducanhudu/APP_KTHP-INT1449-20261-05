# Kiểm tra camera học tập — 22–23/11/2026

Branch: `feat/camera-question-scanner`, dựa trên main `20207cd`.
Phạm vi: chụp/chọn ảnh, OCR, tìm câu trong JSON, QR trên ảnh, xem lời giải và lưu thẻ.

## Kiểm tra đã thực hiện

| Kiểm tra | Kết quả / bằng chứng |
| --- | --- |
| Static analysis | No issues found |
| Format lib/test/integration_test | Đạt |
| Unit/widget suite | 67 test đạt; gồm 9 test mới về tìm kiếm, QR, hủy/từ chối, lưu trùng và đóng khi picker đang chờ |
| Native OCR English trên OPPO CPH2599 | Đạt; ML Kit đọc ảnh vẽ từ câu K01-001, tìm ID 1 ở vị trí đầu |
| Native OCR Việt trên OPPO CPH2599 | Đạt; nhận chữ và tìm ID 1 ở vị trí đầu |
| Native QR hợp lệ | Đạt; nhận flutterlab://question/81, tra đúng ID 81 |
| Native QR bên ngoài | Đạt; đọc được QR nhưng không chấp nhận URL ngoài ngân hàng |
| APK release | Đạt build và cài trên OPPO; source chức năng ab73039 |
| Chọn ảnh và OCR trên release | Đạt: người dùng chọn ảnh mẫu English; nhận chữ và tìm K01-001 / ID 1 đầu tiên |
| Lời giải và lưu thẻ từ OCR | Đạt: đáp án C; lưu hai lần không trùng, báo Thẻ đã có trong bộ ôn |
| QR trên release | Đạt: người dùng chọn ảnh QR, tra đúng K04-014 / ID 81 |
| Nối giải thích AI theo câu | Đạt fallback: từ QR mở panel đúng #81, không phải câu trả lời API thật |
| Làm mới bộ thẻ sau camera | Đạt: thêm câu #81 khi đang ở tab Thẻ ôn, quay lại hiển thị Thẻ 1/2 ngay |
| Camera hệ thống và hủy chụp | Đạt mở com.oplus.camera/.component.CapturePhotoActivity; hủy trở về app, không chụp ảnh cá nhân |

Native tests chạy thật bằng `flutter test integration_test/camera_native_test.dart
-d XOQC79MJCYRSDMV4`. Lần này chưa dùng cờ --no-uninstall; lưu ý hậu quả bên dưới.
Ảnh chữ được Flutter vẽ trong harness; QR có fixture cố định.
Đây là kiểm tra recognizer native bằng ảnh tổng hợp, không phải bằng ảnh chụp quang học.
Không suy ra rằng ảnh mờ, ánh sáng xấu hoặc chữ viết tay đều nhận đúng.

## Cấu hình release cần lưu ý

Plugin OCR tham chiếu các bộ chữ ngoài Latin ở nhánh tùy chọn. App chỉ chọn Latin.
`android/app/proguard-rules.pro` giới hạn dontwarn đúng tám class tùy chọn đó để
R8 build được; không tắt toàn bộ minify hoặc che mọi cảnh báo thư viện.
Muốn hỗ trợ các script khác phải bổ sung dependency native tương ứng và test lại.

Bản release đầu build được nhưng OCR gặp NullPointerException lúc khởi tạo ML Kit.
Đã bổ sung keep rule cho ComponentRegistrar và constructor không tham số được
gọi qua reflection. Sau khi build/cài cập nhật, OCR và QR trên release đều đạt.
Giữ đúng hợp đồng khởi tạo, không giữ toàn bộ SDK một cách đại trà.
Tham khảo lỗi cùng nhóm: https://github.com/googlesamples/mlkit/issues/1018 .

Không chạy flutter test và build đồng thời trong một checkout. Phiên native test
cài bản harness debug tạm. Flutter mặc định tự gỡ app sau test; trong phiên này
điều đó đã xảy ra và có thể làm mất thẻ cục bộ trước đó. Đã thông báo cho người
dùng và cài lại release thành công. Không có bản sao thẻ cũ để khẳng định khôi phục.
Hướng dẫn đã đổi sang --no-uninstall và ưu tiên thiết bị thử riêng. Không chạy
lại test có gỡ app trên điện thoại đang giữ dữ liệu cần bảo toàn.

## APK bàn giao và dữ liệu kiểm thử

- APK release 101,195,789 bytes, đã cài lại trên điện thoại.
- SHA256: `f4a673f2eb9231c903f4c8cfc1fb79bf7466cc0272abad2c2936090b3df021dc`.
- Đã kéo base.apk từ điện thoại và kiểm tra hash trùng bản vừa build.
- Kết thúc: đưa app về Hôm nay, có hai thẻ mẫu #1 và #81 được tạo trong ca thử.
- Hai ảnh mẫu được giữ tại Pictures/FlutterLabCameraTest để người dùng thử lại.
- [Số liệu đối chiếu](screenshots/camera-2026-11-22/measurements.json).
- Không đưa ảnh chụp màn hình lên Git vì có bong bóng chat cá nhân nằm đè trên app.

## Giới hạn bản đầu

- QR đọc từ ảnh; chưa có live scanner hoặc tự mở URL.
- OCR tìm trong 300 câu, không giải mọi câu ngoài dữ liệu.
- Kết quả tìm là gợi ý, cần người dùng chọn và kiểm tra; không hiển thị điểm
  tương đồng như xác suất chắc chắn.
- Chưa có cắt/xoay ảnh; người dùng có thể chỉnh chữ nhận diện.
- Chưa nghiệm thu ảnh chụp thực trong nhiều điều kiện ánh sáng hoặc việc Android
  thu hồi tiến trình giữa lúc mở camera. Có cơ chế retrieveLostData khi mở lại trang.

Kế hoạch và phân công tiếp tục tại [camera-development-plan.md](camera-development-plan.md).
