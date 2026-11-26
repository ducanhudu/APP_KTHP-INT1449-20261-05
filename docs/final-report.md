# Flutter Lab — Báo cáo nội dung đề 32 và 33

Nhóm: Đức Anh, Huy, Trí, Phúc. Phiên bản nội dung cập nhật 26/11/2026, sau khi
merge ba nhánh `feat/camera-question-scanner`, `feat/quiz-history` và
`feat/adaptive-weakness-practice` vào main (`7d972a0`).
Đây là bản nội dung để nhóm đưa vào mẫu báo cáo môn học. Kết quả chưa nghiệm thu
được ghi riêng, không coi kiểm thử giả lập là chạy thực tế trên điện thoại.

## 1. Bài toán và phạm vi

Ứng dụng Android Flutter/Dart hỗ trợ ôn thi kiến thức Flutter/Dart bằng 300 câu
trắc nghiệm Việt–Anh. Song ngữ là ngôn ngữ nội dung câu hỏi và giao diện, còn
Flutter/Dart là công nghệ và chủ đề kiến thức. Dữ liệu thật được dùng từ đầu.

Đề 32 gồm nạp JSON, luyện tập, thi thử, chấm điểm theo khối và làm lại câu sai.
Đề 33 bổ sung thẻ ghi nhớ, SM-2, lịch ôn và nhắc ôn hằng ngày. Khối đang được
nhóm quy ước theo trường topic; cần xác nhận cách hiểu với giảng viên.
AI giải thích và TTS là mở rộng. Bản 26/11 có thêm camera học tập (OCR và QR),
lịch sử làm bài và luyện theo điểm yếu; phần mic nhập câu hỏi đã có mã và test tự
động nhưng **chưa nghiệm thu trên điện thoại thật** nên chưa tính là hoàn thành.
Blockchain không có trong bản này.

## 2. Dữ liệu và kiến trúc

Ngân hàng đóng gói trong assets/flutter_quiz_300.json: 300 ID liên tục, 20 topic,
mỗi câu có câu hỏi, bốn lựa chọn, đáp án và lời giải hai ngôn ngữ. Có 78 câu
chứa code snippet. Audit ghi nhận một cặp nội dung giống nhau nhưng mã và code
khác nhau; nhóm cần xem nội dung này khi thuyết trình về chất lượng dữ liệu.

Lớp Question giữ ID ổn định, lượt làm lưu mã lựa chọn, tránh chấm sai khi xáo
đáp án. CardStorage tách lưu trữ thật và MemoryCardStorage cho test. Thẻ và lịch
lưu SharedPreferences; gỡ app mất thẻ. Từ bản 26/11, mỗi lượt làm bài đã hoàn
thành được ghi thêm vào SharedPreferences (tối đa 100 lượt) để xem lại và phân
tích điểm yếu; lượt đang làm dở vẫn chỉ nằm trong RAM.
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

## 4. Lịch sử làm bài, luyện theo điểm yếu, camera và mic

### 4.1 Lịch sử làm bài

Mỗi lượt hoàn thành được ghi thành `QuizAttempt`: thời điểm, luyện hay thi, khối,
số câu, đúng/sai/bỏ trống, thời lượng, danh sách ID câu và đáp án đã chọn. Bản ghi
nằm trong SharedPreferences dưới khóa `flutter_lab_quiz_history_v1`, giữ tối đa 100
lượt, mới nhất trước. Nếu ghi lỗi, app vẫn hiển thị kết quả và báo chưa lưu được
lịch sử, không làm hỏng luồng làm bài.

Màn Lịch sử lọc theo Tất cả / Luyện tập / Thi thử, mở lại một lượt để xem chi tiết
(dựng lại từ ID câu và đáp án đã lưu), xoá từng lượt hoặc xoá toàn bộ có xác nhận.

### 4.2 Luyện theo điểm yếu

Từ lịch sử và bộ thẻ, `WeaknessAnalyzer` tính độ chính xác từng khối và xếp hạng
khối yếu: dưới 70% sau ít nhất hai câu, hoặc có từ hai thẻ cần ôn. Tab Hôm nay
hiện ba khối yếu nhất; nút "Luyện 10 câu điểm yếu" chọn câu theo thứ tự: câu từng
sai trong khối yếu, câu có trong bộ thẻ, câu khác cùng khối, rồi bổ sung từ toàn
ngân hàng. Đây là quy ước của nhóm, chưa phải thuật toán thích ứng đã kiểm chứng
sư phạm; ngưỡng 70% và cách xếp hạng có thể điều chỉnh sau khi có phản hồi người dùng.

### 4.3 Camera học tập

Người dùng chụp hoặc chọn ảnh trong màn Camera: chế độ Đọc chữ dùng ML Kit nhận
dạng chữ Latin (Việt/Anh) trên thiết bị, chế độ Mã QR đọc QR từ ảnh. Ảnh không gửi
lên backend AI. Chữ nhận được đưa vào ô nhập để sửa, sau đó tìm trong 300 câu với
chuẩn hoá bỏ dấu; kết quả là gợi ý tối đa 5 câu, người dùng tự chọn. QR chỉ chấp
nhận `flutterlab://question/<id>` hoặc mã câu `K##-###` có trong ngân hàng; URL
ngoài bị từ chối, không tự mở trình duyệt. Chi tiết câu cho phép lưu thẻ hoặc mở
panel AI. Giới hạn: ảnh tối đa 12 MB, chưa cắt/xoay ảnh, QR đọc từ ảnh chứ chưa
quét trực tiếp bằng preview, ảnh ngoài ngân hàng có thể không tìm thấy câu.

### 4.4 Nhập bằng giọng nói

Trong chế độ Đọc chữ có nút micro. Âm thanh do bộ nhận dạng của hệ điều hành xử
lý; app không gửi âm thanh hay bản chép lời tới backend. Chữ nhận được điền vào ô
nhập để người dùng **sửa trước khi tìm**; app không tự tìm và không tự gửi. Từ chối
quyền micro hoặc máy thiếu bộ nhận dạng thì hiện thông báo riêng và vẫn nhập tay,
tìm câu bình thường. Phần này mới có test tự động với service giả và test khởi tạo
recognizer trên emulator; chưa có kết quả nhận chữ thật trên điện thoại.

## 5. AI, TTS và bảo vệ hạn mức

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

## 6. Kiểm thử và giới hạn bằng chứng

Chạy format, flutter analyze, flutter test, node --test server/server.test.js và
audit JSON. Test bao phủ chấm theo ID, xáo đáp án, đổi ngôn ngữ giữ lựa chọn,
hết giờ, làm lại câu sai, lưu thẻ, SM-2, fallback AI, vòng đời TTS, lưu và đọc
lịch sử, phân tích điểm yếu, tìm câu từ chữ OCR, mã QR hợp lệ/bị từ chối, và luồng
mic với service giả. Bộ test trên main ngày 27/11 gồm 84 test.
Test server từ chối mã sai/prompt tùy ý/câu không tồn tại, kiểm quota và cache.

Kết quả cuối và bảng nghiệm thu có trong release-handover.md. Cài và mở bản cũ
trên OPPO không thay thế kiểm chứng bản sửa mới. Cần thử thông báo/reboot, nghe
giọng thực, API thật, luồng offline trên APK, micro thật và OCR với ảnh chụp thật
trước khi xác nhận đủ rubric.

## 7. Phân công và hướng phát triển

Kế hoạch 25% mỗi người, luân phiên triển khai, tích hợp, kiểm thử và nghiệm thu
qua bốn ngày. Thành viên tự xác nhận công việc thực tế, không suy % từ số commit.
Đức Anh tích hợp/build, Huy kiểm thử APK và kịch bản, Trí gom SM-2/nhắc ôn/báo cáo,
Phúc sửa lỗi bản tích hợp. Danh sách cụ thể nằm trong release-handover.md.

Ưu tiên tiếp theo là nghiệm thu thiết bị thật cho các phần mới: micro nhận dạng
giọng nói, OCR/QR với ảnh chụp thật ở nhiều điều kiện ánh sáng, và lịch sử sau khi
cài đè bản cũ. Sau đó có thể thêm quét QR trực tiếp bằng preview, cắt/xoay ảnh
trước OCR, sao lưu dữ liệu ra tệp và đồng bộ nhiều thiết bị. Những phần đó là
hướng phát triển, chưa đưa vào danh sách tính năng đã hoàn thành.
