# Triển khai AI proxy lên mạng

App chỉ cần **một URL HTTPS** trỏ tới `POST /explain`; khoá Gemini ở lại server.
Tài liệu này dùng cho bản demo/nộp bài, không phải hạ tầng sản phẩm.

> **Đã deploy (28/11/2026):** `https://flutterlab-ai-proxy.onrender.com` — Render
> gói Free, repo riêng `4lanP/flutterlab-ai-proxy`, bí mật đặt trong Environment.
> Bằng chứng gọi thật và các ca kiểm tra nằm trong `docs/release-handover.md`.
> Gói free ngủ sau 15 phút; mở `/health` trước demo khoảng 2 phút.

## Cần deploy cái gì

| Thành phần | Ghi chú |
| --- | --- |
| `server/server.js` + `server/core.js` | HTTP server thuần Node, **không có dependency npm** |
| `assets/flutter_quiz_300.json` | Server tạo prompt từ chính ngân hàng câu hỏi |
| Biến môi trường `GEMINI_API_KEY`, `AI_ACCESS_CODE` | Đặt trên PaaS, **không** commit |
| Cổng | Đọc `PORT` do PaaS cấp (mặc định 8787 khi chạy máy) |

`Dockerfile` ở gốc repo đã gói đúng hai thứ trên; `.dockerignore` loại phần Flutter
để image nhẹ.

## Cách 1 — Render (miễn phí, dễ nhất)

1. Đăng nhập [render.com](https://render.com) bằng GitHub.
2. **New → Web Service** → chọn repo `APP_KTHP-INT1449-20261-05`.
3. Cấu hình:
   - **Language / Runtime**: `Docker` (Render tự thấy `Dockerfile` ở gốc).
   - **Instance type**: Free.
   - **Health Check Path**: `/health`.
4. **Environment → Add Environment Variable**:
   - `GEMINI_API_KEY` = khoá Gemini của nhóm.
   - `AI_ACCESS_CODE` = mã demo tự đặt (dài, ngẫu nhiên).
5. **Create Web Service**, đợi build xong, nhận URL dạng
   `https://<tên-dịch-vụ>.onrender.com`.
6. Kiểm tra:

```powershell
Invoke-RestMethod https://<tên>.onrender.com/health
# {"ok":true,"configured":true}
```

**Hạn chế của gói free:** dịch vụ ngủ sau ~15 phút không dùng, request đầu tiên
sau khi ngủ mất 30–60 giây. App chờ tối đa 65 giây nên có thể kịp, nhưng trước buổi
demo nên gọi `/health` để đánh thức trước.

## Cách 2 — Railway / Fly.io / Cloud Run / VPS

Dùng chung `Dockerfile`:

```powershell
docker build -t flutterlab-ai-proxy .
docker run --rm -p 8080:8080 `
  -e GEMINI_API_KEY="..." -e AI_ACCESS_CODE="..." flutterlab-ai-proxy
# kiểm tra: http://127.0.0.1:8080/health
```

- **Railway**: New Project → Deploy from GitHub repo → tự nhận Dockerfile → thêm
  hai biến môi trường → tạo domain HTTPS.
- **Cloud Run**: `gcloud run deploy flutterlab-ai --source . --allow-unauthenticated`.
- **VPS riêng**: chạy container ở cổng nội bộ, đặt Caddy/Nginx phía trước để có
  HTTPS. Không mở HTTP công khai vì app release chặn cleartext.

## Nối app vào server đã deploy

```powershell
# APK release: bắt buộc HTTPS
flutter build apk --release --dart-define=AI_API_URL=https://<tên>.onrender.com/explain
```

- **Không** đưa `GEMINI_API_KEY` hay `AI_ACCESS_CODE` vào `--dart-define`; mã truy
  cập nhập trong panel AI và chỉ nằm trong RAM.
- Build debug có thể dùng HTTP cục bộ (`adb reverse tcp:8787 tcp:8787` +
  `AI_API_URL=http://127.0.0.1:8787/explain`), nhưng release phải HTTPS.

## Kiểm tra server đã deploy

```powershell
# 1. Cấu hình đúng
Invoke-RestMethod https://<tên>.onrender.com/health

# 2. Sai mã truy cập phải bị từ chối
try {
  Invoke-WebRequest -Method Post -Uri https://<tên>.onrender.com/explain `
    -Headers @{ Authorization = 'Bearer sai' } -ContentType 'application/json' `
    -Body '{"questionId":1,"language":"vi"}' -UseBasicParsing
} catch { $_.Exception.Response.StatusCode.value__ }   # phải là 401

# 3. Câu trả lời thật (10–20 giây)
Invoke-WebRequest -Method Post -Uri https://<tên>.onrender.com/explain `
  -Headers @{ Authorization = 'Bearer <AI_ACCESS_CODE>' } -ContentType 'application/json' `
  -Body '{"questionId":1,"language":"vi"}' -UseBasicParsing
```

Có thể kiểm tra từ trong app bằng probe có sẵn:

```powershell
flutter test integration_test/ai_real_provider_probe_test.dart -d <DEVICE> `
  --dart-define=AI_PROBE_ENDPOINT=https://<tên>.onrender.com/explain `
  --dart-define=AI_PROBE_ACCESS_CODE=<AI_ACCESS_CODE> --no-uninstall
```

## Bảo mật và hạn mức

- Khoá Gemini chỉ nằm trong biến môi trường của PaaS; đổi khoá bằng dashboard nếu lộ.
- `AI_ACCESS_CODE` là mã dùng chung cho demo, **không** phải xác thực người dùng;
  lộ mã thì đổi mã và restart dịch vụ.
- Server đã giới hạn 6 request/phút/IP, 2 yêu cầu đồng thời, 100 lần gọi nhà cung
  cấp/ngày UTC, cache 30 phút. Hạn mức nằm trong RAM nên reset khi restart và
  không chia sẻ giữa nhiều instance.
- Gói free của PaaS thường có giới hạn giờ chạy/tháng và ngủ khi rảnh; đủ cho demo
  nhưng không dùng cho lớp học thật.

## Sau khi deploy

Ghi URL và mã truy cập vào `docs/release-handover.md` (không ghi khoá Gemini), rồi
cập nhật dòng rubric "chưa nghiệm thu với API thật" khi đã chạy được một câu thật.
