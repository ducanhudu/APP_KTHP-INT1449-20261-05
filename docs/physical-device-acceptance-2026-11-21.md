# Nghiệm thu APK release trên OPPO — 21/11/2026

## Phiên bản được thử

- Điện thoại OPPO CPH2599, Android 16 / API 36, màn hình 1080 × 2412.
- Source chức năng: `5aff6c3` trên main, build bằng `flutter build apk --release`.
- APK: `build/app/outputs/flutter-apk/app-release.apk`, 53,915,024 bytes.
- SHA256: `19ef0bb99f1ab7e4ed4155819226075168a9dc15eb24121d0c79dd41acadeae0`.
- Đã kéo base.apk từ điện thoại và đối chiếu SHA256 trùng APK vừa build.
- Cài cập nhật bằng adb install -r thành công, không gỡ app hay xóa dữ liệu.
- Đây là release mode, nhưng cấu hình signing hiện vẫn dùng chứng chỉ Android Debug.
- Không truyền AI_API_URL/AI_ACCESS_CODE vào bản APK này.

Thao tác trên UI của APK thật qua ADB/UIAutomator. Không dùng kết quả unit test
thay cho các bước trên máy. Ảnh trong `screenshots/acceptance-2026-11-21/`.
Kết quả này không xác nhận thay cho phần nghiệm thu cá nhân của từng thành viên.

## Kết quả

| Mã | Ca thử trên điện thoại | Kết quả | Bằng chứng / quan sát |
| --- | --- | --- | --- |
| A01 | Cài cập nhật, mở release | Đạt | Giao diện Hôm nay hiện, 300 câu / 20 khối; ảnh 01 |
| A02 | Luyện 5 câu: 1 đúng, 1 sai, 3 bỏ trống | Đạt | 20%, tổng theo khối khớp; ảnh 03 |
| A03 | Đổi Việt → English sau khi chọn đáp án | Đạt | Câu #213 vẫn được tính đúng, Answered 1; ảnh 02 |
| A04 | Chấm theo ID sau xáo lựa chọn | Đạt | #213 correctId A hiện ở vị trí B; #81 correctId A hiện ở vị trí C khi làm lại, vẫn chấm đúng |
| A05 | Làm lại câu sai | Đạt | Lượt 1/1 chỉ có #81, không gồm 3 câu bỏ trống; chọn đúng và nộp được 100%; ảnh 04 |
| A06 | Lưu câu sai, đóng hẳn tiến trình rồi mở lại | Đạt | #81 vẫn trong bộ thẻ, không mất dữ liệu; ảnh 06 |
| A07 | Lật thẻ, chọn 4: Nhớ tốt, mở lại tiến trình | Đạt | Lặp 0 → 1, khoảng 0 → 1 ngày, EF 2.5, hạn 21/11 → 22/11; dữ liệu mới giữ nguyên; ảnh 07 |
| A08 | Thi 50 câu, chọn đúng 1 câu rồi nộp | Đạt | #74 đúng; kết quả 2%, 1 đúng / 0 sai / 49 bỏ trống; ảnh 10 |
| A09 | Cộng các dòng thống kê của bài thi | Đạt | 15 topic có câu trong đề; tổng đúng/sai/bỏ trống = 1/0/49, đủ 50 |
| A10 | Đưa bài thi xuống nền rồi quay lại | Đạt | 49:28 → 49:11, giảm 17 giây trong 17.0 giây thực; bài còn nguyên |
| A11 | Mở giải thích từ kết quả và từ bộ thẻ | Đạt fallback | Hiện đúng #81 và lời giải JSON theo ngôn ngữ, nhãn Lời giải gốc; ảnh 05, 11; không phải kết quả AI thật |
| A12 | Nghe lời giải English | Đạt | Nút đổi sang Dừng đọc; người dùng xác nhận nghe được tiếng Anh |
| A13 | Nghe lời giải Việt | Chờ xác nhận nghe | Plugin chuyển sang trạng thái đang đọc, có nội dung Việt; ảnh 11; đang chờ người dùng xác nhận âm thanh |
| A14 | Dừng đọc / đóng panel đang đọc | Đạt thao tác | Dừng đưa nút về Nghe lời giải; đóng quay lại màn kết quả, app tiếp tục dùng được |
| A15 | Bật và tắt nhắc ôn khi có quyền | Đạt đặt/hủy lịch | Android nhận ScheduledNotificationReceiver với origWhen 21/11/2026 20:00; tắt xóa lịch; ảnh 08 |
| A16 | Từ chối quyền thông báo qua hộp thoại Android | Đạt | Công tắc vẫn tắt, có hướng dẫn bật trong Cài đặt, app không crash; ảnh 09 |
| A17 | Thông báo thực phát ra và khôi phục sau reboot | Chưa nghiệm thu | Lịch production cố định 20:00, lúc thử khoảng 01h; chưa chờ đến giờ, chưa reboot điện thoại |
| A18 | Hết đủ 50 phút tự nộp trên APK thật | Chưa nghiệm thu đầy đủ | Đã kiểm tra timer ở nền, chưa đợi hết bài 50 phút; tự nộp hiện có bằng chứng unit/widget test riêng |
| A19 | AI thật, hết quota/mất mạng trong request thật | Chưa nghiệm thu | Bản này không có URL backend; không tạo request AI và không coi fallback chưa cấu hình là mô phỏng mất mạng |

Lượt bổ sung trước A02 cũng chấm được 1 đúng / 0 sai / 4 bỏ trống. Bộ dữ liệu
lượt A02: #207 chọn correctId D; #81 cố ý chọn B trong khi correctId A.
Đã kiểm tra giao diện và log flutter:E / AndroidRuntime:E của tiến trình đang
chạy khi kết thúc: không có dòng lỗi tương ứng. Không kết luận rằng mọi ca
chưa chạy đều không có lỗi.

## Giới hạn và ghi nhận UI

- Chưa thấy lỗi chặn trong các luồng đã chạy ở bảng trên.
- English vẫn có một số nhãn Việt: tên topic, dòng tóm tắt 300 câu, bộ thẻ,
  panel AI. Bản song ngữ chưa dịch toàn bộ UI.
- Nút AI ở bộ thẻ vẫn ghi “Sắp có” dù đã mở được panel. Đây là nhãn cũ cần
  chỉnh, không phải nút bị vô hiệu hóa. Đợt nghiệm thu này không sửa code app.
- Android ghi cửa sổ lịch inexact là 1 giờ; không hứa thông báo phát chính xác
  từng giây hoặc khẳng định đã kiểm tra phát thật chỉ vì alarm đã đăng ký.
- OPPO từ chối pm grant/revoke qua shell; ca từ chối đã được làm bằng trang
  Cài đặt thông báo Flutter Lab và hộp thoại Android, không thay đổi bảo vệ USB.
- Không thay đổi giờ hệ thống, không bật/tắt mạng toàn điện thoại, không reboot.
  Vì vậy chưa ghi nhận thử offline bằng ngắt kết nối thực.

## Trạng thái bàn giao điện thoại

- Giữ nguyên APK release đã thử, đưa app về màn Hôm nay.
- Còn 1 thẻ thử #81, hạn 22/11; không xóa thẻ để giữ mẫu demo.
- Nhắc ôn trong app tắt như ban đầu; quyền thông báo được khôi phục bật sau ca từ chối.
- Không gỡ app, không xóa dữ liệu app khác, không thay đổi dữ liệu ngoài ca thử.

## Việc cần làm để chốt đủ nghiệm thu

1. Build bản có URL HTTPS backend thực, thử AI thành công và fallback khi request lỗi.
2. Thử lịch ngắn trên bản kiểm thử riêng hoặc chờ lịch 20:00; xác nhận thông báo
   thực xuất hiện. Sau đó kiểm tra lại lịch qua reboot thật với sự phối hợp của người dùng.
3. Kiểm thử hết hạn bằng bài ngắn trong harness riêng, ghi rõ khác APK production,
   hoặc chờ đủ 50 phút ở bản này. Không sửa giờ điện thoại để giả hết giờ.
4. Hoàn thiện nhãn UI còn Việt/“Sắp có” nếu nhóm cần demo English toàn bộ.
