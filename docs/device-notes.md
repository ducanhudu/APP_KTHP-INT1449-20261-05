# Ghi chú thiết bị và kết quả kiểm thử trên máy

Tài liệu nghiệm thu Ngày 1 (vai trò Rà soát và nghiệm thu). Ghi lại cấu hình
thiết bị, cách chạy và kết quả kiểm thử thực tế của bản chung, làm bằng chứng cho
rubric tiêu chí 7 (Tài liệu) và tiêu chí 8 (Trình bày, demo).

## Thiết bị kiểm thử

| Hạng mục | Giá trị |
| --- | --- |
| Thiết bị | Android Emulator — AVD **Pixel_8** |
| Model (theo `ro.product.model`) | `sdk_gphone16k_x86_64` |
| Phiên bản Android | **17** (API **37**) |
| Độ phân giải | 1080 × 2400 px, mật độ 420 dpi (~411 × 914 dp) |
| Kiến trúc | x86_64 (image 16 KB page size) |
| Flutter | 3.47.6 stable · Dart 3.13.5 |
| Render backend | Impeller (OpenGLES) |
| JDK | 17 · AGP 9.1.0 · Gradle 9.3.1 |

Ghi chú: đây là **emulator**, chưa phải máy thật. Rubric tiêu chí 8 yêu cầu demo
trên máy thật, nên vẫn phải chạy lại kịch bản bên dưới trên điện thoại của nhóm
trước buổi bảo vệ.

## Cách chạy

```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
flutter emulators --launch Pixel_8
flutter devices                       # cần thấy emulator-5554
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n vn.flutterlab.flutter_quiz_app/.MainActivity
```

Lần build đầu mất **411,7 giây** vì Gradle tự cài thêm Android SDK Platform 36.
Các lần sau nhanh hơn nhiều.

## Kết quả kiểm thử

| # | Kịch bản | Cách thực hiện | Kết quả | Ảnh |
| --- | --- | --- | --- | --- |
| 1 | Mở app, nạp ngân hàng | Khởi động app | Hiện "300 câu song ngữ · 20 khối kiến thức", đủ 2 nút, 5 mức số câu | `01-home.png` |
| 2 | Luyện tập 5 câu | Chọn "5 câu" → "Bắt đầu luyện tập" | Sang màn Luyện tập, "Câu 1/5", 4 lựa chọn A–D, có nút trước/sau/nộp | `02-quiz.png` |
| 3 | Chọn đáp án sai | Chọn A ở câu K17-005 (đáp án đúng là D) | Hiện "Cần xem lại" kèm lời giải đúng | — |
| 4 | Chọn đáp án đúng | Chọn D ở câu K18-007 | Hiện "Chính xác" kèm lời giải | — |
| 5 | Nộp bài toàn sai | Chọn A cho cả 5 câu → "Nộp bài" | **0% · 0 đúng · 5 sai · 0 bỏ trống**; thống kê theo khối đủ 4 khối | `03-result.png` |
| 6 | Nộp bài có câu bỏ trống | Trả lời 1 câu đúng, 4 câu bỏ trống | **20% · 1 đúng · 0 sai · 4 bỏ trống**; K17 = 50% | `04-result-partial.png` |
| 7 | Đổi ngôn ngữ giữa bài | Nút dịch → English | Câu hỏi và đáp án đổi sang tiếng Anh ngay | `05-english.png` |
| 8 | Thi thử 50 câu | "Thi thử · 50 câu · 50 phút" | "Câu 1/50", đồng hồ **49:55** rồi giảm còn **49:46** sau ~9 giây | `06-exam.png` |
| 9 | Nộp bài thi | Chọn 1 đáp án đúng rồi "Nộp bài" | **2% · 1 đúng · 0 sai · 49 bỏ trống**; bảng thống kê đủ 20 khối | `07-exam-result.png` |
| 10 | Nhật ký lỗi | `adb logcat -s flutter:* AndroidRuntime:E` | Không có exception; chỉ có dòng Impeller và Dart VM service | — |

Kiểm tra chấm điểm theo mã đáp án: câu K17-005 có `correct_answer = D`, chọn A thì
báo sai; câu K18-007 có `correct_answer = D`, chọn D thì báo đúng. Khớp với
`assets/flutter_quiz_300.json`.

Vùng chạm: mọi nút và chip đo được **126 px = 48 dp** ở mật độ 420 dpi, đạt mức
tối thiểu 48 dp của tiêu chí 2.

## Phát hiện trong lúc kiểm thử

**Đạt:**

- Luồng chính chạy trọn: mở app → luyện → chấm → kết quả → thống kê theo khối.
- Chấm điểm, đếm đúng/sai/bỏ trống và tổng theo khối khớp với dữ liệu JSON.
- Đồng hồ thi đếm ngược thật, đúng theo thời gian thực.
- Đổi ngôn ngữ giữa bài hoạt động ngay, không cần nộp lại.
- Không có lỗi runtime trong logcat.

**Chưa đạt / cần bổ sung:**

1. **Giao diện chưa song ngữ.** Chọn English chỉ đổi nội dung câu hỏi; nhãn vẫn
   tiếng Việt: "Câu 2/5", "Nộp bài", "Kết quả", "Thống kê theo khối". Đề 32 gắn
   khối 11 (Trợ năng và đa ngôn ngữ), nên đây là điểm cần sửa để lấy điểm cộng.
2. **Không có trạng thái "chưa có dữ liệu".** Màn hình chính chỉ có trạng thái
   đang tải và trạng thái lỗi.
3. **Màn hình lỗi không có lối ra.** Khi không đọc được JSON, app chỉ hiện dòng
   chữ, không có nút thử lại; tiêu chí 2 yêu cầu mỗi trạng thái có lối ra.
4. **Không lưu lịch sử.** Đóng app là mất toàn bộ điểm và danh sách câu sai
   (đúng như README ghi), thuộc phần đề 33.
5. **Chưa kiểm được bố cục màn hình lớn** (tablet) vì chỉ có emulator điện thoại.

## Kịch bản demo 5 phút (dùng cho buổi bảo vệ)

1. Mở app, chỉ vào "300 câu song ngữ · 20 khối kiến thức" (0:00–0:30).
2. Chọn khối, chọn 5 câu, bắt đầu luyện, chọn đáp án để thấy lời giải ngay (0:30–1:30).
3. Nộp bài, xem % và bảng theo khối (1:30–2:30).
4. Bấm "Làm lại N câu sai" để chứng minh luồng làm lại (2:30–3:00).
5. Vào "Thi thử", chỉ vào đồng hồ đang chạy, nộp sớm để thấy kết quả (3:00–4:00).
6. Đổi ngôn ngữ sang English giữa bài (4:00–4:30).
7. Trạng thái lỗi: mở màn hình lỗi bằng cách tạm thời đổi tên asset trong bản
   debug, nêu rõ đây là hạn chế chưa có nút thử lại (4:30–5:00).

## Việc tiếp theo

- Chạy lại toàn bộ kịch bản trên **điện thoại Android thật** của nhóm.
- Khi có tính năng nhắc ôn (đề 33), bổ sung mục kiểm tra quyền thông báo: máy
  Android 13+ phải hỏi quyền **lúc bật nhắc ôn**, không hỏi lúc mở app.
- Cập nhật lại tài liệu này sau mỗi lần thêm tính năng, kèm ảnh mới.
