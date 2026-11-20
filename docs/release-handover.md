# Bàn giao bản sửa cuối — 20/11/2026

## Các nhánh công việc

Các nhánh nối tiếp nhau; nhánh sau chứa cả commit trước để kiểm tra bản tích hợp.
Chưa merge main. Merge theo thứ tự hoặc review toàn bộ nhánh cuối so với main.
Tác giả các commit mới: Duc Anh <ducanh.ptit.udu@gmail.com> theo yêu cầu chủ repo.

| Thứ tự | Branch | Nội dung |
| --- | --- | --- |
| 1 | fix/android-study-reminders | Receiver phát lịch và khôi phục lịch khi reboot/cập nhật APK |
| 2 | fix/ai-proxy-access-control | Chỉ nhận mã câu/ngôn ngữ, mã truy cập demo, quota, giới hạn đồng thời, test server trong CI |
| 3 | fix/tts-language-and-lifecycle | Giọng en-US/vi-VN và ngăn tiếp tục đọc khi panel đóng |
| 4 | docs/release-acceptance-handover | Bằng chứng, bảng nghiệm thu, hướng dẫn APK và tài liệu bảo vệ |

## Kết quả kiểm tra

| Kiểm tra | Kết quả |
| --- | --- |
| Build debug sau sửa manifest | Đạt; manifest merge có hai receiver và RECEIVE_BOOT_COMPLETED |
| Dart format | Đạt |
| Flutter analyze | Đạt, không có issue |
| Flutter test | 56 test đạt trên bản tích hợp |
| Node proxy tests | 6 test đạt; không gọi nhà cung cấp thật |
| Ngân hàng JSON | Đủ 300 câu, 20 topic; có 1 cặp nội dung lặp đã ghi nhận trong audit |
| API thật | Chưa chạy trong đợt này; cần khóa/server nhóm tự cấu hình |
| Thiết bị thật với APK mới | Chưa xác nhận; ADB không có thiết bị khi bắt đầu đợt sửa |
| Release APK | Build đạt, 53,915,024 bytes; apksigner verify đạt (Android Debug certificate) |

APK cục bộ: `build/app/outputs/flutter-apk/app-release.apk`.
Source chức năng: `4e44ab537931540b0f9a6f54e7d97744aca4c69a`.
SHA256: `5A9A7DD338761101EE523721323F04A384863003369A6988EBFA79345B3C9EC2`.
Chữ ký debug chỉ dùng cài/demo, chưa đáp ứng ký bằng khóa riêng để phát hành.

Build release và flutter test phải chạy tuần tự. Trong lần kiểm tra này, chạy
song song làm file GeneratedPluginRegistrant chứa integration_test lúc release
biên dịch và gây lỗi. Chạy lại riêng bằng `flutter build apk --release` đã đạt;
không sửa file sinh tự động để chữa lỗi này.

Không có AI_API_URL trong APK mặc định: core dùng offline, AI dùng lời giải JSON.
APK để demo AI thật cần build lại với URL HTTPS của backend cùng phiên bản.
Server mới yêu cầu AI_ACCESS_CODE; xem `server/README.md`.

## Cách chạy lại và cài APK

Từ thư mục chứa pubspec.yaml:

```powershell
git fetch origin
git switch docs/release-acceptance-handover
git pull --ff-only
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
node --test server/server.test.js
python tool/audit_question_bank.py assets/flutter_quiz_300.json
flutter build apk --release
adb devices -l
# Nếu có nhiều máy, thêm -s <serial> ngay sau adb
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am start -n vn.flutterlab.flutter_quiz_app/.MainActivity
```

Không tự gỡ app để cài mới vì gỡ sẽ mất thẻ. Cài sạch chỉ thực hiện sau khi
nhóm xác nhận có thể bỏ dữ liệu trên thiết bị thử riêng.

## Nghiệm thu thủ công APK mới

| Ca | Bước và kết quả mong đợi | Trạng thái |
| --- | --- | --- |
| M01 | Luyện 5 câu: 1 đúng, 1 sai, 3 bỏ trống; tổng và từng khối khớp | Chờ điện thoại |
| M02 | Đổi Việt/Anh giữa bài; đáp án giữ nguyên; làm lại chỉ chứa câu sai | Chờ điện thoại |
| M03 | Lưu câu sai thành thẻ, đóng/mở lại; thẻ và lịch còn; ôn cập nhật ngày | Chờ điện thoại |
| M04 | Bật nhắc: cấp quyền thì lưu lịch, từ chối không làm hỏng luồng ôn | Chờ điện thoại |
| M05 | Thử lịch gần và kiểm tra thông báo thực xuất hiện, sau reboot vẫn còn lịch | Chờ điện thoại |
| M06 | Thi đến hạn tự nộp; ở nền quá hạn rồi quay lại không làm thêm được | Chờ điện thoại; đã có test đồng hồ giả |
| M07 | Không mạng/AI 401/429/502: xem được lời giải JSON và thoát panel | Chờ điện thoại; đã có mock |
| M08 | AI thật giải thích đúng mã câu; đổi English, nghe/dừng, đóng panel hết tiếng | Chờ backend thật + điện thoại |

Thông báo đang dùng inexactAllowWhileIdle nên thời điểm phát có thể bị Android
trì hoãn, đặc biệt khi tiết kiệm pin. Không cam kết đúng từng giây. Để thử lịch
gần mà không đổi cấu hình bản nộp: trên nhánh thử cục bộ, đặt hour/minute khi
gọi ReminderService.enable theo giờ thiết bị, sau đó bỏ thay đổi thử nghiệm.
Không gửi broadcast boot giả rồi coi là đã kiểm chứng reboot thật.

## Phân công nghiệm thu còn lại theo Notion

| Thành viên | Việc cần xác nhận trực tiếp | Đầu ra |
| --- | --- | --- |
| Đức Anh | Chọn SHA cuối, cài APK mới, cấu hình backend nếu có AI | APK + SHA256 + cách chạy |
| Huy | Chạy M01–M08, ghi đạt/chưa đạt, đối chiếu đề 32/33 | Bảng có thiết bị, giờ, ảnh và người thử |
| Trí | Xác nhận nhắc ôn/reboot, kiểm SM-2, gom báo cáo và tổng duyệt | Bằng chứng thông báo + gói nộp |
| Phúc | Sửa lỗi phát hiện khi thử APK, so sánh debug/release | Bước tái hiện và kết quả sau sửa |

Đây là phân công nghiệm thu, không xác nhận thay cho thành viên. Tỷ lệ kế hoạch
là 25% mỗi người; không tự quy các commit do trợ lý viết thành đóng góp người khác.

## Gói nộp

- APK release và SHA256, source theo commit cuối.
- README, server/README, rubric-checklist và nhật ký kiểm tra.
- Báo cáo nội dung tại final-report.md; nhóm rà lại biểu mẫu của trường.
- Kịch bản và dàn ý slide tại defense-script.md.
- Bổ sung video 3–5 phút trên điện thoại, xác nhận quyền đọc repo, tổng duyệt.
