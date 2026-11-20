# Khác biệt giữa bản dev và APK nộp

Ghi lại những lỗi **chỉ xuất hiện trên APK**, không thấy khi chạy `flutter run`.
Đây là phần việc "Triển khai" của Ngày 4.

## Vì sao phải kiểm riêng

`flutter run` dùng **bản debug**, khác bản nộp ở bốn điểm:

| Điểm khác | Bản debug | APK release |
|---|---|---|
| Quyền `INTERNET` | Flutter **tự chèn** vào manifest debug | Chỉ có nếu khai báo trong `AndroidManifest.xml` |
| R8 / thu gọn mã | Tắt | Bật, có thể xoá lớp mà plugin cần |
| `assert()` | Chạy | Bị bỏ |
| `debugPrint` | In ra logcat | Không in |

Hệ quả: một app "chạy ngon" trong `flutter run` vẫn có thể **chết phần mạng** trên
APK mà không có lỗi rõ ràng.

## Lỗi đã tìm và sửa (20/11)

**Triệu chứng:** nút "Hỏi AI" hoạt động khi chạy `flutter run` nhưng gọi mạng thất
bại trên APK.

**Nguyên nhân:** `android/app/src/main/AndroidManifest.xml` chỉ khai báo
`POST_NOTIFICATIONS`, thiếu `INTERNET`. Flutter chèn `INTERNET` cho riêng bản
debug nên lỗi bị che.

**Cách sửa:** thêm

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

kèm ghi chú rằng quyền này chỉ dùng cho nút "Hỏi AI".

**Cách kiểm chứng** (không cần mở app):

```powershell
# 1. Build bản nộp
flutter build apk --release

# 2. Đọc quyền trong APK
& $env:ANDROID_HOME\build-tools\<version>\aapt2.exe dump permissions build\app\outputs\flutter-apk\app-release.apk
```

Kết quả phải có **cả hai** dòng:

```
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.POST_NOTIFICATIONS'
```

## Bảng kiểm trước khi nộp

| Việc | Lệnh / cách làm | Kết quả mong đợi |
|---|---|---|
| Quyền trong APK | `aapt2 dump permissions app-release.apk` | có `INTERNET` + `POST_NOTIFICATIONS` |
| App cài được | `adb install -r app-release.apk` | `Success` |
| Mở được | bấm icon trên máy | vào màn hình Hôm nay, không crash |
| Không có khoá trong repo | `git grep -n -i "api[_-]key\|sk-"` | không kết quả |
| Dung lượng APK | xem thuộc tính tệp | dưới ~60 MB |

## Ghi chú

- `flutter_local_notifications` và `flutter_tts` đều chạy ở release; riêng TTS cần
  khai báo `<queries><intent><action android:name="android.intent.action.TTS_SERVICE"/></intent></queries>`
  để Android 11+ tìm thấy engine đọc tiếng.
- Nếu R8 làm hỏng plugin ở bản nộp, thêm luật giữ lớp vào
  `android/app/proguard-rules.pro` rồi build lại — **không** tắt R8.

## Kết quả kiểm trên bản release (20/11)

| Việc | Kết quả |
|---|---|
| lutter build apk --release | OK, **51.1 MB** |
| apt2 dump permissions | có **cả** INTERNET và POST_NOTIFICATIONS |
| Cài trên emulator Android 17 (gỡ bản debug trước) | Success, mở được |
| Luyện 5 câu → nộp bài | 20% · 1 đúng · 4 sai · 0 bỏ trống, thống kê 4 khối khớp |
| Mở "Hỏi AI" trên bản release | panel "Giải thích AI" hiện **Lời giải gốc** đúng nội dung JSON |
| Bấm "Nghe lời giải" (TTS) | đổi sang "Dừng đọc", app không crash, không có lỗi trong logcat |
| Log AndroidRuntime:E | rỗng |

**Lỗi phụ phát hiện khi chạy bản release:** nút trong màn kết quả vẫn ghi
"Hỏi AI về câu này · **Sắp có**" trong khi tính năng đã chạy. Đã sửa nhãn thành
"Hỏi AI về câu này" / "Ask AI about this question" (khoá AppStrings.aiAsk).