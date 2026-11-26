# Kịch bản bảo vệ và dàn ý trình chiếu

## Demo 5 phút

| Thời gian | Người | Thao tác và nội dung |
| --- | --- | --- |
| 0:00–0:40 | Đức Anh | Giới thiệu Android Flutter, đề 32+33, 300 câu Việt–Anh; mở app, chỉ tab Hôm nay có gợi ý khối yếu |
| 0:40–1:40 | Huy | Luyện ngắn, đổi ngôn ngữ giữ đáp án, nộp và xem tổng/khối; mở **Lịch sử**, lọc Luyện tập/Thi thử, mở lại một lượt |
| 1:40–2:40 | Trí | Làm lại câu sai, lưu thẻ, lật và đánh giá nhớ; giải thích ngày đến hạn SM-2; bấm **Luyện 10 câu điểm yếu** và nói rõ thứ tự chọn câu |
| 2:40–3:50 | Phúc | **Camera học tập**: chọn ảnh mẫu, sửa chữ, tìm ra câu; thử QR; nêu giới hạn. Sau đó mở giải thích AI đúng câu, nghe/dừng, fallback |
| 3:50–5:00 | Cả nhóm | Bằng chứng test; các ca còn chờ thiết bị thật (mic, thông báo, API thật); giới hạn và phần việc từng người |

Không chờ thi đủ 50 phút hoặc nhắc ôn đến 20h trong buổi bảo vệ. Dùng bằng
chứng kiểm thử tương ứng, nói rõ test đồng hồ giả và test thiết bị là hai loại.
Chỉ demo AI thật sau khi nhóm đã cấu hình và thử trước; stub phải ghi rõ là stub.
Camera đã có kết quả trên OPPO ([camera-validation.md](camera-validation.md)) nên
được demo, nhưng phải nói rõ ảnh mẫu dựng từ JSON chứ không phải ảnh chụp thật.
Chưa demo **micro** như tính năng đã nghiệm thu: nếu chưa thử trên điện thoại, chỉ
nêu đã có mã và test tự động, hoặc chuyển sang nhập tay.
Không chiếu khóa hay mã truy cập.

## Dàn ý 10 slide để nhóm đưa vào mẫu môn học

1. Bài toán, nhóm và phạm vi đề 32 + 33.
2. Ngân hàng 300 câu, hai ngôn ngữ, topic và ID đáp án ổn định.
3. Luồng luyện/thi → kết quả → làm lại sai → bộ thẻ.
4. SM-2: trạng thái thẻ trước/sau đánh giá, lưu trữ và ngày đến hạn.
5. Lịch sử làm bài: bản ghi lưu gì, lưu ở đâu, xem lại và xoá.
6. Luyện theo điểm yếu: cách tính khối yếu, thứ tự chọn câu, giới hạn của quy ước.
7. Camera học tập: OCR/QR xử lý trên thiết bị, tìm câu, giới hạn đã biết.
8. Kiến trúc Flutter, storage, reminder, AI server, TTS và mic.
9. AI: prompt từ câu tin cậy, khóa server, mã truy cập demo, quota, fallback.
10. Bằng chứng format/analyze/test/audit/build, các ca chờ thiết bị thật, phân công
    thực tế, giới hạn và hướng phát triển.

Đây là dàn ý, chưa phải file slide đã xuất. Nhóm chọn ảnh thật trong
docs/screenshots và ghi đúng phiên bản ảnh. Không dùng ảnh bản cũ làm bằng
chứng cho lỗi vừa sửa. Video và xác nhận phần nói của từng người cần nhóm bổ sung.
