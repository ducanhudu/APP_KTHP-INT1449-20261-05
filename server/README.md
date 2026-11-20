# AI proxy — giữ khoá ở server

App **không** giữ khoá API. Nó gọi tới server này; server giữ khoá và gọi nhà
cung cấp AI. Nhờ vậy:

- Repo không chứa khoá → không bị trừ 10 điểm theo rubric.
- APK phát cho người khác cũng không chứa khoá.
- Đổi nhà cung cấp AI chỉ cần sửa `AI_UPSTREAM`, không phải build lại app.

## Chạy thử bằng stub (không cần khoá)

```powershell
# cửa sổ 1 – giả lập nhà cung cấp AI
node server/stub-upstream.js

# cửa sổ 2 – proxy trỏ vào stub
$env:AI_UPSTREAM = 'http://127.0.0.1:9999/explain'
$env:GEMINI_API_KEY = 'demo'
node server/server.js
```

Kiểm tra:

```powershell
curl http://127.0.0.1:8787/health
```

Kết quả mong đợi: `{"ok":true,"keyConfigured":true,...}`

## Chạy thật với Gemini

1. Lấy khoá ở https://aistudio.google.com/apikey (không dán vào chat, không commit).
2. Đặt biến môi trường **chỉ trong phiên terminal**:

```powershell
$env:GEMINI_API_KEY = '<khoá của bạn>'
node server/server.js
```

3. Trỏ app vào proxy:

```powershell
# emulator Android: 10.0.2.2 là IP của máy tính
flutter run --dart-define=AI_API_URL=http://10.0.2.2:8787/explain

# điện thoại thật cùng Wi-Fi: dùng IP LAN của máy tính
flutter run --dart-define=AI_API_URL=http://192.168.1.10:8787/explain
```

## Đưa lên host công khai (khuyến nghị khi demo)

Render / Fly / Vercel đều chạy được file `server.js` này vì nó không cần
`package.json`:

1. Tạo Web Service, chọn repo, **Start command**: `node server/server.js`
2. Khai báo biến môi trường `GEMINI_API_KEY` trong dashboard của host — **không**
   đưa vào file trong repo.
3. Build app với `--dart-define=AI_API_URL=https://<tên-host>/explain`

Host có HTTPS sẵn nên không phải lo chặn `http://` của Android.

## Bảo mật

- `.env` và `server/.env` đã nằm trong `.gitignore`.
- Không commit `GEMINI_API_KEY` vào `pubspec.yaml`, `build.gradle.kts`, CI hay tài liệu.
- Nếu nghi khoá bị lộ: thu hồi ở trang quản lý khoá rồi tạo khoá mới.
- Proxy giới hạn body 64 KB và thời gian chờ 15 giây để tránh bị lạm dụng.

## Kiểm thử tự động

`test/ai_service_test.dart` chạy với `MockClient`, không gọi mạng thật:

- server trả định dạng Gemini → app dùng nội dung AI trả về
- server trả `{"text": "..."}` (backend tự viết) → app vẫn đọc được
- server trả 500 → app rơi về lời giải gốc trong JSON
