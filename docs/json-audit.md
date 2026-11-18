# Đối chiếu ngân hàng câu hỏi — `assets/flutter_quiz_300.json`

Tài liệu nghiệm thu Ngày 1 (vai trò Rà soát và nghiệm thu). Ghi lại kết quả kiểm
tra dữ liệu thật của ứng dụng đề 32, kèm cách tái lập để người khác kiểm lại sau
mỗi lần sửa JSON.

## Cách tái lập

Không cần thư viện ngoài, chỉ cần Python 3.9 trở lên:

```powershell
python tool/audit_question_bank.py assets/flutter_quiz_300.json
```

Mã thoát `0` khi mọi kiểm tra đạt, `1` khi có lỗi. Chạy lại lệnh này sau mỗi lần
sửa JSON trước khi commit.

## Kết quả ngày 18/11/2026

```
Tệp            : assets/flutter_quiz_300.json
Kích thước     : 639.3 KB
Số câu         : 300
id             : liên tục 1..300, không trùng
mã câu         : 300 mã duy nhất, đúng dạng K##-###
Khối           : 20 khối (K01–K20)
  K01=20 · K02=22 · K03=25 · K04=15 · K05=18 · K06=15 · K07=18 · K08=9
  K09=20 · K10=9 · K11=9 · K12=20 · K13=23 · K14=12 · K15=9 · K16=20
  K17=8 · K18=8 · K19=12 · K20=8
Mức độ         : Nhớ=103 · Hiểu=120 · Vận dụng=77
Đáp án đúng    : A=76 · B=75 · C=75 · D=74
Có code snippet: 78 câu (dài nhất 461 ký tự)
Lời giải tiếng Việt: ngắn nhất 170, trung bình 310, dài nhất 521 ký tự
Nguồn          : docs.flutter.dev=246 · dart.dev=27 · api.flutter.dev=26 · pub.dev=1

GHI NHẬN:
  - Khối dưới 10 câu: K08=9, K10=9, K11=9, K15=9, K17=8, K18=8, K20=8
  - 1 nội dung câu hỏi bị lặp lại (khác mã, khác đoạn mã)

KẾT LUẬN: ĐẠT — ngân hàng câu hỏi hợp lệ với mô hình của ứng dụng.
```

## Bảng đối chiếu theo yêu cầu

| Hạng mục | Yêu cầu của ứng dụng | Kết quả thật | Đạt |
| --- | --- | --- | --- |
| Số câu | đúng 300 (`decodeQuestions`) | 300 | ✅ |
| `id` | số nguyên, không trùng | 1–300 liên tục | ✅ |
| `code` | duy nhất, dạng `K##-###` | 300 mã duy nhất, khớp khối | ✅ |
| `topic` | 1..20 | đủ 20 khối | ✅ |
| `level` | Nhớ / Hiểu / Vận dụng | 103 / 120 / 77 | ✅ |
| `question_vi`, `question_en` | chuỗi không rỗng, khác nhau | 300/300 | ✅ |
| `options` | đúng 4, mã A–D duy nhất | 300/300 | ✅ |
| `correct_answer` | nằm trong 4 lựa chọn | 300/300 | ✅ |
| Lời giải Việt + Anh | không rỗng | 300/300 | ✅ |
| `source_url` | https hợp lệ | 300/300, 4 tên miền | ✅ |
| UTF-8 / NFC | không lỗi mã hoá | hợp lệ | ✅ |

## Phát hiện và khuyến nghị

**1. Bảy khối chỉ có 8–9 câu → màn hình luyện tập bị giới hạn ở 5 câu.**
Bộ chọn số câu trong `lib/main.dart` chỉ hiện các mức 5/10/15/20/30 không vượt quá
số câu của khối. Với K08, K10, K11, K15 (9 câu) và K17, K18, K20 (8 câu), người
học **chỉ chọn được 5 câu**. Đây là hành vi đúng theo thiết kế nhưng nên ghi vào
báo cáo phần "hạn chế", hoặc bổ sung câu cho 7 khối này.

**2. Hai câu trùng phần dẫn, không phải lỗi dữ liệu.**
`id=5` (K01-005) và `id=10` (K01-010) cùng mở đầu "Đoạn mã sau in ra gì?" nhưng
khác `code_snippet` và khác đáp án. Không cần sửa.

**3. Hai trường dữ liệu ứng dụng chưa dùng: `code` và `source_url`.**
Cả 300 câu đều có, `code` duy nhất và `source_url` trỏ về tài liệu chính thức,
nhưng `Question.fromJson` không đọc hai trường này. Đề xuất dùng `code` làm khoá
ổn định cho thẻ ghi nhớ của đề 33, và `source_url` cho nút "Xem nguồn".

**4. `decodeQuestions` chốt cứng đúng 300 câu.**
Thêm hoặc bớt một câu là ứng dụng ném `FormatException` ngay khi khởi động và chỉ
hiện "Không đọc được ngân hàng câu hỏi". Nếu nhóm bổ sung câu cho 7 khối thiếu
(mục 1), **phải nới kiểm tra này trước**, nếu không app sẽ không mở được.

**5. Phân bố đáp án đúng cân bằng** (A76 / B75 / C75 / D74) nên không đoán được
theo vị trí; ứng dụng còn xáo trộn lựa chọn khi tạo đề.

## Liên hệ rubric

- **Khối 8 — Tài nguyên:** dữ liệu là asset đóng gói trong APK, đọc bằng
  `rootBundle`, không cần mạng. Đạt.
- **Tiêu chí 1 — Chức năng:** "Nạp 300 câu từ JSON" có bằng chứng định lượng.
- **Tiêu chí 4 — Dữ liệu:** dữ liệu tĩnh, chỉ đọc; phần lưu trữ động thuộc đề 33.
