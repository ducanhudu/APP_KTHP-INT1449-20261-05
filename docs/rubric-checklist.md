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
| 1 | Chức năng | 20 | ⚠️ ~16–18 | Đề 32 đủ tối thiểu + 2 mở rộng (`01`–`07`); đề 33 đã có bộ thẻ, SM-2, lưu cục bộ (`08`–`17`). **Thiếu nhắc ôn hằng ngày** | Thêm `flutter_local_notifications` | Huy, Trí |
| 2 | Giao diện & trải nghiệm | 15 | ⚠️ ~10–11 | Có loading, lỗi, **có trạng thái rỗng** cho bộ thẻ; vùng chạm 48 dp đạt. Màn lỗi vẫn **không có nút thử lại**; nhãn UI chưa song ngữ | Thêm nút "Thử lại" + bề rộng tối đa cho màn lớn | Trí, Phúc |
| 3 | Kiến trúc & trạng thái | 15 | ⚠️ ~11 | Đã tách `sm2.dart`, `card_storage.dart`, `flashcard_page.dart`, `question_prompt.dart`; **`CardStorage` là interface, thay được bằng `MemoryCardStorage`** khi test | Tách tiếp phần còn lại của `main.dart`; bỏ đọc đĩa trong `build()` | Đức Anh, Huy |
| 4 | Dữ liệu & xử lý lỗi | 10 | ✅ ~9 | `shared_preferences` lưu thẻ; JSON hỏng trả `[]` không crash (`card_storage_prefs_test.dart`); xử lý lỗi ngân hàng câu hỏi có thông báo | Thêm nút thử lại ở màn lỗi | Trí |
| 5 | Kiểm thử | 10 | ✅ 10 | **31 test / 6 tệp**, `flutter test` pass 31/31, `flutter analyze` sạch; có unit cho SM-2, chấm điểm, lưu trữ thật và **3 widget test** (`docs/day-2-test-log.md`) | Giữ xanh khi thêm tính năng | Phúc, Trí |
| 6 | Bảo mật & quyền | 10 | ✅ ~9 | Manifest **không xin quyền nào**, không có `INTERNET`; README có mục "Dữ liệu lưu ở đâu" | Khi thêm thông báo: xin quyền đúng lúc bật nhắc ôn | Trí |
| 7 | Tài liệu & quy trình | 10 | ⚠️ ~7 | `flutter analyze` → **No issues found**; README có phiên bản, cách chạy, cách test, dữ liệu lưu ở đâu; `docs/json-audit.md`, `docs/device-notes.md` | **Mỗi người phải commit**; bổ sung hướng dẫn cấu hình | Cả nhóm |
| 8 | Trình bày & vấn đáp | 10 | ⚠️ ~5 | Có kịch bản demo 5 phút trong `docs/device-notes.md`; mới demo trên **emulator** | Quay video 3–5 phút trên máy thật; mỗi người tự giải thích tệp mình làm | Cả nhóm |

Ước lượng tổng hiện tại: **~78–84/100** (đã có đề 33 phần thẻ + lưu trữ, 31 test,
CI xanh). Khi thêm nhắc ôn + sửa 2 lỗi giao diện + commit đủ người: **~92–100**.

## 3. Điểm cộng (tối đa +10)

| Nội dung | Điểm | Trạng thái | Việc cần làm |
| --- | --- | --- | --- |
| CI chạy `flutter analyze` + `flutter test` mỗi lần đẩy mã | +2 | ✅ | `.github/workflows/ci.yml`: format + analyze + test + audit JSON. Lần chạy đầu trên nhánh `chore/ci-analyze-test` **passing** (badge trong README) |
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
flutter test                          # All tests passed! (31 test)
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
| 19/11/2026 | Phúc | 31 test (thêm 3 test luồng quiz, 7 test lưu trữ thật, 1 widget test bộ đếm thẻ); CI nhận `feat/**`; sửa lỗi bộ đếm thẻ không làm mới; nhật ký kiểm thử `docs/day-2-test-log.md` |
