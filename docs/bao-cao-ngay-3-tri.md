# Báo cáo Ngày 3 – Trí (Triển khai · 3)

## Phân tích: Cái gì đã có / còn thiếu

### ✅ Đã có trước ngày 3 (từ ngày 1–2)

| Hạng mục | File | Ghi chú |
|----------|------|---------|
| Thuật toán SM-2 đầy đủ | `lib/sm2.dart` | interval, repetitions, easeFactor, isDue() |
| Unit test SM-2 | `test/sm2_test.dart` | 5 ca, đủ để trình bày khi bảo vệ |
| Lưu thẻ persistent | `lib/card_storage.dart` | SharedPrefs + MemoryCardStorage cho test |
| Nhắc ôn hằng ngày | `lib/reminder_service.dart` | flutter_local_notifications, timezone |
| UI nhắc ôn | `lib/reminder_tile.dart` | Switch + xin quyền đúng lúc người dùng bật |
| Flashcard UI | `lib/flashcard_page.dart` | Hiển thị, đánh giá SM-2, xóa thẻ |
| Đồng hồ thi auto-submit | `lib/main.dart` (QuizPage) | Timer 50 phút, expired=true khi hết giờ |
| Đổi ngôn ngữ giữ đáp án | `lib/main.dart` (QuizPage) | answers map giữ nguyên khi đổi locale |
| Kết quả theo khối | `lib/question.dart` (byTopic) | Score per topic |

### 🔴 Còn thiếu / cần hoàn thiện ngày 3

| Hạng mục | Vấn đề cũ | Giải pháp đã thực hiện |
|----------|-----------|------------------------|
| **AI giải thích** | `learning_tools.dart` chỉ là placeholder "Sắp có" | Thay toàn bộ bằng `AiService` thật + fallback JSON |
| **TTS đọc lời giải** | Nút "Nghe lời giải" bị `disabled: null` | `TtsService` với `flutter_tts`, play/stop/error |
| **Fallback khi mất mạng** | Không có | `AiService` timeout 5s → trả về `explanationVi/En` |
| **Fallback khi từ chối quyền mic** | Không có | `TtsService.permissionDenied` → hiển thị cảnh báo |
| **pubspec.yaml lỗi** | `http`, `flutter_tts` ở dev_dependencies + duplicate key | Chuyển sang dependencies runtime, dọn duplicate |
| **Unit test AI** | Không có | `test/ai_service_test.dart` |

---

## Các file tạo / sửa trong ngày 3

| File | Hành động | Mô tả |
|------|-----------|-------|
| `lib/ai_service.dart` | **Tạo mới** | Gọi Gemini API (cấu hình qua `AI_API_URL`), fallback lời giải gốc |
| `lib/tts_service.dart` | **Tạo mới** | Phát giọng nói `flutter_tts`, play/stop/error/permissionDenied |
| `lib/learning_tools.dart` | **Thay thế hoàn toàn** | AI panel thật: auto-fetch, hiển thị kết quả, nút TTS, fallback chip |
| `pubspec.yaml` | **Sửa** | `http`, `flutter_tts` → dependencies; xóa duplicate |
| `test/ai_service_test.dart` | **Tạo mới** | 2 ca: fallback vi, fallback en khi URL chưa cấu hình |

---

## Công nghệ sử dụng ngày 3

| Package | Phiên bản | Vai trò |
|---------|-----------|--------|
| `http` | ^1.2.0 | Gọi REST API Gemini (hoặc bất kỳ AI backend) |
| `flutter_tts` | ^4.2.0 | Text-to-Speech đa nền tảng Android/iOS |
| `flutter_local_notifications` | ^19.0.0 | Nhắc ôn hằng ngày (đã có từ ngày 2) |
| `shared_preferences` | ^2.2.2 | Lưu thẻ SM-2 bền vững (đã có) |

---

## Cách cấu hình AI (khi có backend thực)

```bash
# Chạy với Gemini API thật
flutter run --dart-define=AI_API_URL=https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_KEY

# Build APK với AI thật
flutter build apk --dart-define=AI_API_URL=https://...
```

Nếu `AI_API_URL` không được set → app vẫn chạy bình thường với lời giải gốc từ JSON.

---

## Chạy kiểm thử

```bash
# Unit test SM-2 (đã có từ ngày 1)
flutter test test/sm2_test.dart

# Unit test AI fallback (ngày 3)
flutter test test/ai_service_test.dart

# Chạy tất cả test
flutter test
```

---

## Checklist nghiệm thu ngày 3 (Trí)

- [x] Lịch nhắc ôn hằng ngày – `reminder_service.dart` + `reminder_tile.dart`
- [x] Đồng hồ thi auto-submit khi hết giờ – `QuizPage` (`_submit(expired: true)`)
- [x] Đổi ngôn ngữ giữ nguyên đáp án đã chọn – state `answers` không reset khi đổi locale
- [x] AI giải thích câu sai – `AiService.explain()`, hiển thị trong `LearningToolPreview`
- [x] Fallback lời giải gốc khi API lỗi/timeout – `fromFallback: true`
- [x] TTS đọc lời giải – `TtsService`, nút play/stop
- [x] Từ chối quyền mic → hiển thị cảnh báo thay nút TTS
- [x] Unit test SM-2 đủ 5 ca – `test/sm2_test.dart`
- [x] Unit test AI fallback – `test/ai_service_test.dart`
- [ ] Chạy `flutter pub get` để cài `http`, `flutter_tts`
- [ ] Chạy `flutter test` xác nhận tất cả PASS
- [ ] Test trên thiết bị thật: nhắc ôn, TTS, hết giờ
- [ ] Chụp screenshot bằng chứng → `docs/evidence/day3/`

---

*Cập nhật: 2026-11-20 (Ngày 3)*
