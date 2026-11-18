# Checklist nghiệm thu theo rubric

Bảng đối chiếu yêu cầu của đề 32 + 33 và 8 tiêu chí rubric với bằng chứng thật
trong repo. Cập nhật cuối mỗi ngày làm việc; mỗi dòng phải có bằng chứng mở được,
không ghi "đã làm" mà không kèm ảnh, lệnh hoặc tệp.

Quy ước: ✅ đạt · ⚠️ đạt một phần · ❌ chưa có · — không áp dụng.

## 1. Điều kiện được chấm

| Điều kiện | Trạng thái | Bằng chứng / việc cần làm |
| --- | --- | --- |
| Mã nguồn trên Git, giảng viên có quyền đọc | ⚠️ | Repo có, nhưng **chưa xác nhận** quyền truy cập. Kiểm tra Settings → Collaborators trước khi nộp. |
| Build và chạy được trên Android theo README | ✅ | `flutter build apk --debug` thành công; cài và chạy trên emulator Pixel_8, xem `docs/device-notes.md` |
| Không có khoá API, mật khẩu trong repo | ✅ | Quét toàn bộ lịch sử Git: 0 khoá thật. 2 dòng khớp mẫu là nội dung câu hỏi K19 minh hoạ `sk_live_...` (có dấu ba chấm), không phải khoá |
| Mỗi thành viên có commit của mình | ❌ | `git shortlog -sne` → **1 commit, 1 tác giả** (`Duc Anh`, 17/11). Thiếu điều kiện này bị trừ 10% và phải nộp lại trong 48 giờ |

## 2. Tám tiêu chí rubric

| # | Tiêu chí | Điểm | Hiện tại | Bằng chứng | Việc cần làm | Người |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Chức năng | 20 | ⚠️ ~12–15 | Đề 32 đủ tối thiểu + 2 mở rộng, chạy được: `docs/device-notes.md`, ảnh `01`–`07`. **Đề 33 chưa có** | Thêm bộ thẻ + SM-2 + nhắc ôn | Huy, Trí |
| 2 | Giao diện & trải nghiệm | 15 | ⚠️ ~8 | Có loading + lỗi; **thiếu trạng thái rỗng**; màn lỗi **không có nút thử lại**; vùng chạm 48 dp đạt (`docs/device-notes.md`) | Thêm empty state + nút "Thử lại" + giới hạn bề rộng cho màn lớn | Trí, Phúc |
| 3 | Kiến trúc & trạng thái | 15 | ❌ ~7 | Toàn bộ UI + logic trong `lib/main.dart` (475 dòng); dữ liệu đọc trực tiếp trong `State`, không thay được bằng đồ giả | Tách `screens/`, `models/`, `services/`; inject nguồn dữ liệu | Đức Anh, Huy |
| 4 | Dữ liệu & xử lý lỗi | 10 | ❌ ~5 | Không có lưu trữ; JSON hỏng có thông báo nhưng không có lối ra | Thêm SQLite/Hive cho thẻ; xử lý dữ liệu hỏng | Trí |
| 5 | Kiểm thử | 10 | ❌ 5 | **2/15 test** (`test/widget_test.dart`); `flutter test` pass 2/2 | Viết thêm 13 test: SM-2, chấm điểm biên, validate JSON, 2 widget test luồng chính | Phúc, Trí |
| 6 | Bảo mật & quyền | 10 | ✅ ~9 | Manifest **không xin quyền nào**, không có `INTERNET`; README có mục "Dữ liệu lưu ở đâu" | Khi thêm thông báo: xin quyền đúng lúc bật nhắc ôn | Trí |
| 7 | Tài liệu & quy trình | 10 | ⚠️ ~7 | `flutter analyze` → **No issues found**; README có phiên bản, cách chạy, cách test, dữ liệu lưu ở đâu; `docs/json-audit.md`, `docs/device-notes.md` | **Mỗi người phải commit**; bổ sung hướng dẫn cấu hình | Cả nhóm |
| 8 | Trình bày & vấn đáp | 10 | ⚠️ ~5 | Có kịch bản demo 5 phút trong `docs/device-notes.md`; mới demo trên **emulator** | Quay video 3–5 phút trên máy thật; mỗi người tự giải thích tệp mình làm | Cả nhóm |

Ước lượng tổng hiện tại: **~50–57/100** (chưa có đề 33, chưa có lưu trữ, 2/15 test,
1 commit). Khi hoàn thành đề 33 + tách tầng + 15 test + commit đều: **~90–100**.

## 3. Điểm cộng (tối đa +10)

| Nội dung | Điểm | Trạng thái | Việc cần làm |
| --- | --- | --- | --- |
| CI chạy `flutter analyze` + `flutter test` mỗi lần đẩy mã | +2 | ⚠️ | Đã có `.github/workflows/ci.yml` (format + analyze + test + audit JSON), **chờ lần chạy đầu tiên** trên GitHub để xác nhận xanh |
| Test trợ năng `meetsGuideline` hoặc giao diện hai ngôn ngữ | +2 | ❌ | Đang chỉ song ngữ nội dung, nhãn vẫn tiếng Việt (`05-english.png`). Hoặc thêm test `androidTapTargetGuideline` + `labeledTapTargetGuideline` |
| APK release ký bằng khoá riêng | +2 | ❌ | Release hiện ký bằng debug key; tạo keystore + `key.properties` (không commit) |
| Mở rộng AI đúng mẫu máy chủ giữ khoá, có chế độ demo | +3 | ❌ | Chỉ làm nếu Ngày 2 xong sớm; khoá **không** được nằm trong APK |
| Có người dùng thật dùng thử, phản hồi được ghi lại | +1 | ❌ | Nhờ 2 bạn ngoài nhóm dùng thử 10 phút, ghi lại nhận xét |

## 4. Điểm trừ cần phòng

| Rủi ro | Mức trừ | Cách phòng |
| --- | --- | --- |
| Khoá API trong mã hoặc lịch sử Git | −10 | Không hard-code; dùng biến môi trường phía máy chủ. Nếu lỡ push: thu hồi khoá + xoá lịch sử |
| Nộp muộn | −5/ngày | Chốt mốc nộp sớm hơn 1 ngày |
| Dùng mã/tài nguyên người khác không ghi nguồn | Mất điểm phần đó | Ghi nguồn trong README và báo cáo |
| Thành viên không giải thích được mã mình nộp | Giảm hệ số cá nhân | Mỗi người chỉ nhận phần mình viết; review chéo trước khi nộp |

## 5. Checklist nộp bài

| Mục | Trạng thái | Ghi chú |
| --- | --- | --- |
| Link repo, giảng viên có quyền đọc | ⚠️ | Cần xác nhận quyền truy cập |
| README đủ mục | ✅ | Mục đích, yêu cầu môi trường, cài đặt, cách chạy, cách test, dữ liệu lưu ở đâu, đã kiểm thử trên |
| Tệp APK cài được | ⚠️ | Có `app-debug.apk`; cần bản **release** |
| Video demo 3–5 phút trên máy thật | ❌ | Có kịch bản trong `docs/device-notes.md`, chưa quay |
| Báo cáo tối đa 10 trang | ❌ | Có sẵn số liệu trong `docs/json-audit.md`, `docs/device-notes.md` |
| Slide tối đa 10 trang | ❌ | — |
| Bảng phân công và % đóng góp | ⚠️ | Có bảng trong kế hoạch 4 ngày, cần đưa vào repo |
| `docs/ai/` nếu có dùng trợ lý AI | — | Chỉ cần nếu nhóm dùng trợ lý AI để viết mã/tài liệu |

## 6. Cách tái lập bằng chứng

```powershell
flutter --version                     # Flutter 3.47.6 · Dart 3.13.5
flutter analyze                       # No issues found!
flutter test                          # All tests passed! (2 test)
python tool/audit_question_bank.py assets/flutter_quiz_300.json
git shortlog -sne                     # kiểm tra commit từng thành viên
git log -p --all | Select-String 'sk_live|AIza'   # quét khoá trong lịch sử
flutter build apk --debug
```

## 7. Nhật ký cập nhật

| Ngày | Người | Nội dung |
| --- | --- | --- |
| 18/11/2026 | Phúc | Tạo checklist; gỡ chặn SDK; bổ sung README; kiểm JSON; chạy thử trên emulator Pixel_8 |
| 18/11/2026 | Phúc | Thêm CI GitHub Actions (format + analyze + test + audit JSON) trên nhánh `chore/ci-analyze-test` |
