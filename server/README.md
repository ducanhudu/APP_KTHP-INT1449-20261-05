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

## Số đo thật ngày 20/11 (máy trong nhóm, mạng Việt Nam)

| Lần gọi | Model | Kết quả | Thời gian |
|---|---|---|---|
| 1 | gemini-3.8-flash | 200 | 60,6 s |
| 2 | gemini-3.8-flash | 200 | 6,3 s |
| 3 | gemini-3.8-flash | 200 | 58,8 s |
| 4 | gemini-flash-latest | 503 → thử lại → 200 | 14,9 s |
| nhiều lần sau | gemini-3.8-flash | **429** (hết hạn mức) | 0,3 s |

### Đã tối ưu (cùng ngày)

Nguyên nhân chậm không phải mạng: đo được DNS 33 ms, TCP 57 ms, TLS 112 ms — tổng
chưa tới 0,2 giây. Thời gian nằm ở **token suy luận ẩn**: một câu trả lời 35 token
nhưng usageMetadata.totalTokenCount = 321, tức 274 token là "thinking".

Cách xử lý, đã áp dụng trong server.js:

| Thay đổi | Kết quả đo |
|---|---|
| Chuyển sang gemini-3.1-flash-lite | nhanh nhất trong 25 model khả dụng |
| Chèn generationConfig.thinkingConfig.thinkingBudget = 0 | bỏ 200–300 token suy luận |
| **Tổng: câu hỏi thật của app** | **1,0–2,1 giây** (trước đó 6–90 giây) |

Đặt AI_THINKING=1 nếu muốn giữ thinking mặc định; model không hỗ trợ
	hinkingConfig (ví dụ gemini-flash-lite-latest) trả 400 và proxy tự gọi lại
không kèm cấu hình đó.

## Chuẩn bị cho buổi bảo vệ

Proxy có **cache theo nội dung câu hỏi** (mặc định 30 phút, đổi bằng AI_CACHE_MS):

1. Trước giờ bảo vệ, mở đúng những câu sẽ demo và bấm "Hỏi AI" một lần. Lần đầu
   có thể chậm 30–90 giây; app cho chờ tối đa 65 giây.
2. Khi đã có kết quả, nội dung được lưu ở proxy. Bấm "Hỏi lại" sẽ trả về **ngay**
   (log proxy ghi cache hit).
3. Nếu lúc bảo vệ mạng hỏng hoặc hết hạn mức, app tự hiện **"Lời giải gốc"** —
   đúng yêu cầu "vẫn xem lời giải JSON khi API lỗi".

Muốn chắc chắn hơn thì quay video một lần AI trả lời thật, và khi bảo vệ trình bày
cả video lẫn bản chạy trực tiếp.

## Biến môi trường

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| GEMINI_API_KEY | (trống) | Khoá API, **không commit** |
| PORT | 8787 | Cổng lắng nghe |
| AI_UPSTREAM | Gemini 2.0 Flash | URL model; đổi model tại đây |
| AI_TIMEOUT_MS | 60000 | Thời gian chờ mỗi lần gọi upstream |
| AI_CACHE_MS | 1800000 | Thời gian giữ cache;  để tắt |