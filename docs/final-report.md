# Flutter Lab — Báo cáo nội dung đề 32 và 33

Nhóm: Đức Anh, Huy, Trí, Phúc. Phiên bản nội dung ngày 20/11/2026.
Đây là bản nội dung để nhóm đưa vào mẫu báo cáo môn học. Kết quả chưa nghiệm thu
được ghi riêng, không coi kiểm thử giả lập là chạy thực tế trên điện thoại.

## 1. Bài toán và phạm vi

Ứng dụng Android Flutter/Dart hỗ trợ ôn thi kiến thức Flutter/Dart bằng 300 câu
trắc nghiệm Việt–Anh. Song ngữ là ngôn ngữ nội dung câu hỏi và giao diện, còn
Flutter/Dart là công nghệ và chủ đề kiến thức. Dữ liệu thật được dùng từ đầu.

Đề 32 gồm nạp JSON, luyện tập, thi thử, chấm điểm theo khối và làm lại câu sai.
Đề 33 bổ sung thẻ ghi nhớ, SM-2, lịch ôn và nhắc ôn hằng ngày. Khối đang được
nhóm quy ước theo trường topic; cần xác nhận cách hiểu với giảng viên.
AI giải thích và TTS là mở rộng. Mic, camera, QR, Blockchain không có trong bản này.

## 2. Dữ liệu và kiến trúc

Ngân hàng đóng gói trong assets/flutter_quiz_300.json: 300 ID liên tục, 20 topic,
mỗi câu có câu hỏi, bốn lựa chọn, đáp án và lời giải hai ngôn ngữ. Có 78 câu
chứa code snippet. Audit ghi nhận một cặp nội dung giống nhau nhưng mã và code
khác nhau; nhóm cần xem nội dung này khi thuyết trình về chất lượng dữ liệu.

Lớp Question giữ ID ổn định, lượt làm lưu mã lựa chọn, tránh chấm sai khi xáo
đáp án. CardStorage tách lưu trữ thật và MemoryCardStorage cho test. Thẻ và lịch
lưu SharedPreferences; dữ liệu bài làm chỉ có trong RAM. Gỡ app mất thẻ.
SM-2 được tách khỏi UI để test với ngày cố định. ReminderService tách plugin
khỏi widget. AiService và TtsService bao bọc mạng và giọng đọc.

## 3. Luồng chức năng

Người dùng chọn ngôn ngữ, topic và số câu để luyện. Chế độ thi tạo 50 câu,
50 phút, xáo lựa chọn. Hạn nộp dựa trên đồng hồ, không chỉ trừ biến mỗi giây.
Kết quả gồm đúng/sai/bỏ trống, tỷ lệ và tổng theo topic. Làm lại lấy các câu sai.

Từ kết quả, câu sai được thêm vào bộ thẻ theo ID, tránh nhân đôi. Người dùng
xem mặt trước, lật để xem lời giải và đánh giá mức nhớ. Thuật toán cập nhật
số lần lặp, khoảng ngày, hệ số dễ tối thiểu 1.3 và ngày đến hạn. Bộ thẻ được
đọc lại khi mở app; test lưu trữ có cả ca JSON hỏng.

Nhắc ôn dùng thông báo cục bộ, xin quyền khi bật. Android manifest đã bổ sung
receiver phát lịch và boot receiver khôi phục sau reboot/cập nhật app. Đây là
lịch không chính xác từng giây; thời điểm phát phụ thuộc chính sách Android.

## 4. AI, TTS và bảo vệ hạn mức

App chỉ gửi ID câu/ngôn ngữ, server tạo prompt từ bản JSON tin cậy có kèm lựa
chọn, code và đáp án. Khóa nhà cung cấp nằm trong biến môi trường server.
Mã truy cập demo nhập khi dùng AI, chỉ giữ trong RAM app. Giới hạn 6 request/phút/IP,
100 lần gọi nhà cung cấp/ngày UTC, 2 yêu cầu đồng thời, 600 token đầu ra.
Cache 30 phút; lỗi/timeout/quota trả về lời giải gốc trong app.

Mã dùng chung và bộ đếm RAM phù hợp demo một server. Sản phẩm nhiều người dùng
cần tài khoản được xác thực, quota dùng chung bền vững và giới hạn ngân sách
nhà cung cấp. Không tuyên bố bảo mật sản phẩm công khai chỉ nhờ giấu API key.

TTS chọn en-US cho English, vi-VN cho Việt và chế độ song ngữ. Song ngữ hiện dùng
một giọng Việt cho toàn bộ văn bản; chưa tự chuyển giọng theo từng đoạn. Đóng
panel ngăn khởi động phát tiếp từ thao tác async đang chờ và bỏ callback muộn.

## 5. Kiểm thử và giới hạn bằng chứng

Chạy format, flutter analyze, flutter test, node --test server/server.test.js và
audit JSON. Test bao phủ chấm theo ID, xáo đáp án, đổi ngôn ngữ giữ lựa chọn,
hết giờ, làm lại câu sai, lưu thẻ, SM-2, fallback AI và vòng đời TTS.
Test server từ chối mã sai/prompt tùy ý/câu không tồn tại, kiểm quota và cache.

Kết quả cuối và bảng nghiệm thu có trong release-handover.md. Cài và mở bản cũ
trên OPPO không thay thế kiểm chứng bản sửa mới. Cần thử thông báo/reboot, nghe
giọng thực, API thật và luồng offline trên APK trước khi xác nhận đủ rubric.

## 6. Phân công và hướng phát triển

Kế hoạch 25% mỗi người, luân phiên triển khai, tích hợp, kiểm thử và nghiệm thu
qua bốn ngày. Thành viên tự xác nhận công việc thực tế, không suy % từ số commit.
Đức Anh tích hợp/build, Huy kiểm thử APK và kịch bản, Trí gom SM-2/nhắc ôn/báo cáo,
Phúc sửa lỗi bản tích hợp. Danh sách cụ thể nằm trong release-handover.md.

Ưu tiên tiếp theo là nghiệm thu thiết bị thật. Sau đó có thể thêm mic với bản
chép lời sửa được trước gửi, camera/QR, tài khoản và đồng bộ. Những phần đó là
hướng phát triển, chưa đưa vào danh sách tính năng đã hoàn thành.
