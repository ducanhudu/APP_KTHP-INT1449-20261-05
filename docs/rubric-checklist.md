# Nghiệm thu đề 32 và 33 — cập nhật 20/11/2026

> Cập nhật thiết bị thật 21/11: đã cài release từ main 5aff6c3 trên OPPO Android 16,
> thử luồng luyện/thi/làm lại/thẻ, lưu qua restart, timer ở nền, TTS English và
> đặt/hủy lịch, từ chối thông báo. Xem [bảng ca thử đầy đủ](physical-device-acceptance-2026-11-21.md).
> Thông báo phát thực/reboot, hết đủ 50 phút và API thật vẫn chưa được nghiệm thu.

Trạng thái phân biệt bằng chứng tự động với nghiệm thu trên điện thoại.
Không suy từ test pass thành mọi chức năng Android đều hoạt động.

| Yêu cầu | Bằng chứng | Kết luận |
| --- | --- | --- |
| 300 câu Việt–Anh, ID và đáp án hợp lệ | `tool/audit_question_bank.py`, `test/scoring_test.dart` | Đạt kiểm tra dữ liệu |
| Luyện tập, thi thử, chấm đúng/sai/bỏ trống | `test/widget_test.dart`, `test/quiz_flow_test.dart`, `test/scoring_test.dart` | Đạt tự động |
| Thống kê theo khối, làm lại chỉ câu sai | `test/quiz_flow_test.dart`, `test/scoring_test.dart` | Đạt tự động; khối đang quy ước là topic |
| Hết giờ tự nộp, đổi ngôn ngữ giữ đáp án | `test/exam_and_language_test.dart` | Đạt tự động |
| Bộ thẻ, lịch SM-2, lưu sau mở lại | `test/sm2_test.dart`, `test/card_storage_prefs_test.dart` | Đạt tự động |
| Nhắc ôn hằng ngày | `lib/reminder_service.dart`, receiver/boot permission trong manifest | Đã sửa cấu hình, build debug đạt; chờ thử phát thông báo và khởi động lại trên điện thoại |
| Màn lỗi có thử lại | `test/error_state_test.dart` | Đạt tự động |
| Nhãn Việt/Anh ở luồng chính | `test/quiz_flow_test.dart` | Đạt các màn có test; màn camera đã song ngữ, panel AI còn nhãn Việt |
| AI giữ khóa ở server, chỉ giải thích câu trong ngân hàng | `server/server.test.js`, `test/ai_service_test.dart` | Đạt mock/stub; chưa nghiệm thu với API thật |
| AI lỗi/mất mạng vẫn xem lời giải JSON | `test/ai_service_test.dart`, `test/learning_tools_test.dart` | Đạt tự động; chờ thử APK mất mạng |
| Đọc tiếng Việt/Anh, đóng panel dừng đọc | `test/tts_service_test.dart` | Đạt kiểm thử channel; chờ nghe trên điện thoại có engine phù hợp |
| Mic: chép lời, sửa trước gửi, từ chối vẫn nhập tay | `lib/speech_input_service.dart`, `test/speech_input_test.dart`, `docs/speech-input.md` | Đạt kiểm thử tự động bằng service giả; **chờ thử micro thật trên điện thoại** |
| Camera/QR, đề 36, Blockchain | Ngoài phạm vi kế hoạch 4 ngày | Không công bố đã có |

## Điều kiện và gói nộp

- Lịch sử Git hiện có tác giả Đức Anh, Huy, Trí, Phúc (`git shortlog -sne HEAD`).
  Số commit không đại diện phần trăm đóng góp; mỗi người tự xác nhận phần làm.
- Quyền truy cập repo của giảng viên: nhóm cần xác nhận với giảng viên.
- APK debug đã build; bản cũ đã cài/mở trên OPPO CPH2599 trước đợt sửa này.
  Không dùng kết quả đó để nghiệm thu APK mới.
- APK release: xem kết quả cuối cùng tại `docs/release-handover.md`.
- APK release hiện dùng debug signing theo cấu hình có sẵn. Không đủ bằng chứng
  cho tiêu chí ký khóa riêng. Không đưa keystore hoặc mật khẩu vào Git.
- Tài liệu báo cáo, kịch bản và phân công: `docs/release-handover.md`,
  `docs/final-report.md`, `docs/defense-script.md`.
- Video thật, phản hồi người dùng ngoài nhóm, tổng duyệt cả bốn: chờ nhóm thực hiện.
- CI phải được kiểm tra trên đúng commit/branch đã chọn để nộp.

Không quy đổi các kết quả trên thành điểm số chắc chắn. Giảng viên quyết định
cách tính đề 32 + 33, định nghĩa khối và điểm phần nâng cao.
