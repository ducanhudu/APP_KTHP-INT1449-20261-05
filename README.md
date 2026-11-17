# Flutter Lab Android

Base Flutter/Dart cho đề 32. Ứng dụng đọc 300 câu Việt–Anh từ
`assets/flutter_quiz_300.json` và chạy được khi ngoại tuyến.

## Chạy trên Android

```powershell
flutter pub get
flutter run
```

Chọn điện thoại Android đã bật USB debugging hoặc emulator đang chạy.
Để tạo APK debug, chạy `flutter build apk --debug`. APK nằm tại
`build/app/outputs/flutter-apk/app-debug.apk`.

## Phạm vi

- Luyện theo khối, chọn số câu và xem lời giải sau khi trả lời.
- Thi thử 50 câu từ toàn bộ ngân hàng, xáo trộn đáp án, đếm ngược 50 phút và tự nộp khi hết giờ.
- Đổi ngôn ngữ Việt, Anh hoặc song ngữ trong khi làm bài.
- Xem điểm, thống kê theo khối, lời giải và làm lại các câu đã trả lời sai.

Thống kê nhóm theo trường `topic` của JSON, tương ứng K01–K20.
Phiên làm bài nằm trong bộ nhớ trong lúc app chạy. Lịch sử và khôi phục
sau khi đóng app, bộ thẻ SM-2, nhắc ôn và gia sư AI thuộc phần triển khai tiếp.

## Kiểm tra

```powershell
flutter analyze
flutter test
```
