# Camera học tập — kế hoạch, tác dụng và nghiệm thu

## Mục tiêu

Giúp sinh viên đưa câu hỏi trên giấy hoặc ảnh chụp vào luồng ôn tập hiện có.
Ảnh được đọc thành chữ; người dùng sửa chữ, tìm câu gần khớp trong ngân hàng
300 câu, xem lời giải, lưu thẻ SM-2 hoặc chủ động bấm hỏi AI về câu đã chọn.
QR dẫn tới mã câu xác định, giảm bước nhập và tìm kiếm khi chia sẻ bài tập.

Tính năng này bổ sung phương thức nhập dữ liệu cho app, không biến ảnh bất kỳ
thành một đáp án chắc chắn. Nếu nội dung không thuộc ngân hàng, app có thể
không tìm thấy câu. Kết quả tìm kiếm là gợi ý, không phải độ tin cậy OCR.

## Phạm vi bản đầu

- Hai chế độ: Đọc chữ và Mã QR; mỗi chế độ có Chụp ảnh và Chọn ảnh.
- Chụp bằng ứng dụng camera hệ thống; chọn ảnh qua bộ chọn ảnh Android.
- OCR chữ Latin Việt/Anh và đọc QR trên thiết bị bằng ML Kit native.
- Cho sửa chữ hoặc nhập tay khi ảnh mờ, không có chữ, hủy chụp hoặc từ chối quyền.
- Tìm tối đa 5 câu gợi ý; hỗ trợ thiếu dấu, xuống dòng và nội dung tiếng Anh.
- QR hợp lệ: `flutterlab://question/81` hoặc mã thật như `K01-001`.
- Không mở URL bên ngoài, không thực hiện nội dung chỉ dẫn có trong QR.
- Chi tiết câu hiển thị dữ liệu gốc, lựa chọn, đáp án, lời giải; có Lưu thẻ và Hỏi AI.
- Ảnh không gửi tới backend AI. Hỏi AI chỉ gửi mã câu đã chọn theo cơ chế hiện có.
- Giới hạn ảnh xử lý 12 MB, ảnh chọn/chụp được giới hạn kích thước 2400 × 2400.
- Nếu Android thu hồi tiến trình lúc chụp: mở lại Camera để thử khôi phục ảnh bị mất.

QR bản này được đọc từ ảnh chụp/ảnh có sẵn, chưa có camera preview quét liên tục.
Chưa gồm cắt ảnh, chữ viết tay, tự giải câu ngoài JSON hoặc tự thêm câu mới vào ngân hàng.

## Luồng sử dụng

1. Hôm nay → Camera học tập, hoặc bấm biểu tượng camera trên thanh trên cùng.
2. Chọn Đọc chữ / Mã QR, sau đó Chụp ảnh hoặc Chọn ảnh.
3. Với OCR: xem ảnh, sửa chữ và bấm Tìm trong 300 câu.
4. Với QR: app chỉ gợi ý những mã câu hợp lệ có trong ngân hàng.
5. Chọn kết quả để xem lời giải; lưu thẻ hoặc chủ động hỏi AI.
6. Đóng camera, quay lại luồng học hiện tại.

## Kế hoạch 4 ngày và tiêu chí đầu ra

| Ngày | Việc trên bản chung | Đầu ra tối thiểu |
| --- | --- | --- |
| 1 | Thiết kế luồng, bộ chọn/chụp ảnh, giao diện Việt/Anh và xử lý hủy/lỗi | Mở camera, chọn được ảnh, hủy không mất nội dung đang sửa |
| 2 | OCR, chuẩn hóa tìm kiếm, sửa nội dung, ảnh không chữ | Ảnh mẫu Việt/Anh tìm đúng câu đầu tiên; có hướng xử lý khi không tìm thấy |
| 3 | QR, chi tiết câu, lưu thẻ và nối nút AI hiện có | QR đúng mở đúng câu; mã lạ bị từ chối; lưu không trùng thẻ |
| 4 | Kiểm thử unit/widget/native, release build, thử camera thật và bàn giao | Có APK, kết quả test, ảnh mẫu và danh sách giới hạn đã biết |

## Phân công luân phiên 25% mỗi người

| Ngày | Triển khai · 3 | Tích hợp · 3 | Kiểm thử/sửa lỗi · 2 | Review/nghiệm thu · 2 |
| --- | --- | --- | --- | --- |
| 1 | Đức Anh | Huy | Trí | Phúc |
| 2 | Huy | Trí | Phúc | Đức Anh |
| 3 | Trí | Phúc | Đức Anh | Huy |
| 4 | Phúc | Đức Anh | Huy | Trí |

Đây là kế hoạch phân công để nhóm nghiệm thu và tiếp tục phát triển, không xác
nhận mỗi người đã hoàn thành các việc trên. Mỗi người đủ bốn vai, tổng 10/40
điểm công sức dự kiến. Cuối ngày cân lại theo thời gian thực tế.

## Cấu trúc triển khai

| Tệp | Trách nhiệm |
| --- | --- |
| lib/study_image_service.dart | Chụp/chọn ảnh, khôi phục ảnh, gọi OCR/QR native và đóng tài nguyên |
| lib/question_search.dart | Chuẩn hóa chữ Việt/Anh, xếp hạng câu, kiểm mã QR |
| lib/camera_study_page.dart | Ảnh xem trước, sửa chữ, kết quả, chi tiết và lưu thẻ |
| lib/learning_tools.dart | Mở route camera và nối sang giải thích AI |
| test/question_search_test.dart | Tìm kiếm, mã hợp lệ và dữ liệu QR không được hỗ trợ |
| test/camera_study_page_test.dart | Hủy, từ chối quyền, tìm tay, lưu trùng và đóng khi đang chờ |
| integration_test/camera_native_test.dart | OCR/QR thật trên Android, tách biệt test giả |

## Checklist nghiệm thu

- Chụp ảnh thật trên Android và quay lại được ảnh xem trước.
- Chọn ảnh mẫu tiếng Việt và tiếng Anh, sửa chữ rồi tìm đúng K01-001.
- Ảnh mờ/không chữ không làm app crash; vẫn nhập tay được.
- Hủy camera giữ nguyên nội dung cũ; bấm nhiều lần không mở nhiều picker.
- Từ chối quyền vẫn vào được các phần ôn tập khác.
- QR câu #81 mở đúng câu, QR URL ngoài ngân hàng không mở website.
- Lưu thẻ đúng ID, lần hai không nhân đôi; quay lại màn học có thể thấy thẻ mới.
- Đổi English trước khi mở camera thì nhãn camera theo English.
- Build APK release, kiểm tra không ảnh hưởng luyện/thi/SM-2 hiện có.

## Ảnh mẫu và cách test

`test/fixtures/camera/` có ảnh chữ Việt/Anh và QR hỗ trợ/không hỗ trợ.
Ảnh mẫu được dựng từ JSON, không phải ảnh camera thực; phải thử thêm ảnh chụp
để đánh giá ánh sáng, nghiêng và độ nét trên thiết bị của nhóm.

```powershell
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter build apk --release
```

Không chạy flutter test và build đồng thời trong cùng checkout. Native test tự
vẽ ảnh chữ bằng Flutter, dùng QR fixture chỉ trong test; không đóng gói ảnh mẫu
trong APK production. Chạy trên thiết bị thử riêng:
`flutter test integration_test/camera_native_test.dart -d DEVICE_ID --no-uninstall`.
Flutter mặc định gỡ app sau integration test; không bỏ cờ giữ app trên máy có
dữ liệu cần giữ. Nếu chữ ký không tương thích, dừng và không tự gỡ app để cài.
Kết quả đã thực hiện sẽ được ghi ở `camera-validation.md`.

## Hướng phát triển sau bản đầu

Ưu tiên cắt/xoay ảnh và sửa trải nghiệm nhận diện, sau đó mới cân nhắc quét QR
liên tục. Gửi nội dung ngoài ngân hàng sang AI cần một endpoint trợ lý riêng,
xác nhận của người dùng và cơ chế bảo vệ hạn mức tương ứng.

## Tài liệu kỹ thuật

- Image picker: https://pub.dev/packages/image_picker
- OCR native: https://pub.dev/packages/google_mlkit_text_recognition
- Barcode native: https://pub.dev/packages/google_mlkit_barcode_scanning

Hai plugin ML Kit Flutter do cộng đồng duy trì. Android SDK ML Kit xử lý native;
không mô tả chúng là thư viện Flutter chính thức do Google phát hành.
