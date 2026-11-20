# Ghi nhận sử dụng trợ lý AI

Ngày 20/11/2026, chủ repo yêu cầu trợ lý kiểm tra mã, sửa các mục còn lại, tách
branch theo công việc, chạy kiểm tra và push bằng danh tính Git của chủ repo.

Các phần được trợ lý hỗ trợ trong đợt này:

- Đọc kế hoạch Notion và đối chiếu bằng chứng trong repo.
- Phát hiện/sửa cấu hình receiver thông báo Android.
- Sửa giao thức AI chỉ nhận mã câu, mã truy cập demo và giới hạn sử dụng.
- Viết test server và thêm job CI tương ứng.
- Sửa ngôn ngữ/vòng đời TTS, bổ sung test channel.
- Chạy format, analyze, test, audit và build; chuẩn bị tài liệu bàn giao/demo.

Commit được tạo với danh tính Duc Anh theo yêu cầu, không có nghĩa toàn bộ mã
được chủ repo tự gõ. Nhóm cần đọc hiểu, review và xác nhận trước khi nộp.
Không ghi nhận các phần này là commit do Huy, Trí hay Phúc tự thực hiện.
Những phần test chưa chạy thực tế (API thật, thiết bị, video) được ghi là chờ.

Test mạng dùng khóa giả và server giả, không đưa khóa thật, mã truy cập thật
hay nội dung bí mật vào tài liệu. Tài liệu này ghi phạm vi hỗ trợ, không phải
lịch sử đầy đủ các lần dùng AI từ khi bắt đầu dự án.
