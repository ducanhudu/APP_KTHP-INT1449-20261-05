# AI proxy cho bản demo

Yêu cầu Node.js 22. Không cần npm install. Khóa Gemini chỉ tồn tại ở server.
App chỉ gửi `{ "questionId": 1, "language": "vi" }` tới `POST /explain`.
Server tự lấy câu hỏi, code, lựa chọn và lời giải từ JSON trong repo để tạo prompt.
Ngôn ngữ hợp lệ: `vi`, `en`, `bilingual`. Payload có prompt hay trường khác bị từ chối.

## Chạy thử không dùng hạn mức AI

Terminal thứ nhất:

```powershell
node server/stub-upstream.js
```

Terminal thứ hai:

```powershell
$env:AI_UPSTREAM = 'http://127.0.0.1:9999/explain'
$env:GEMINI_API_KEY = 'demo-not-a-real-key'
$env:AI_ACCESS_CODE = Read-Host 'Tạo mã truy cập demo riêng cho nhóm'
node server/server.js
```

`GET /health` trả `configured: true` khi đã đặt cả hai biến. Thiếu cấu hình,
server trả 503 và app vẫn dùng lời giải JSON. Đóng terminal để xóa biến của phiên.

## Chạy AI thật

Trên server, đặt `GEMINI_API_KEY` từ nhà cung cấp và `AI_ACCESS_CODE` là mã ngẫu
nhiên riêng cho nhóm. Bỏ `AI_UPSTREAM` để dùng model mặc định. Không commit hai
giá trị này và không đưa chúng vào `--dart-define`.

```powershell
# Chỉ URL được đưa vào app
flutter run --dart-define=AI_API_URL=https://your-server.example/explain
```

Mở lời giải AI → **Mã truy cập AI** → nhập mã nhóm đã tạo. Mã chỉ giữ trong RAM,
không lưu SharedPreferences. Khi mở lại tiến trình app, nhập lại mã. Mã này cấp
quyền dùng proxy, không phải khóa của Gemini. Mất/hết mã, hết hạn mức hoặc mất
mạng đều chuyển sang lời giải JSON. Nếu lộ mã truy cập, đổi mã trên server và
khởi động lại server.

Để thử bằng điện thoại Android qua cáp USB:

```powershell
adb reverse tcp:8787 tcp:8787
flutter run --dart-define=AI_API_URL=http://127.0.0.1:8787/explain
```

HTTP chỉ dành cho debug cục bộ. APK release dùng HTTPS. Cần triển khai app và
server cùng phiên bản vì giao thức prompt cũ đã bị loại bỏ.

## Giới hạn bảo vệ

- Không có mã hoặc mã sai: 401; câu không hợp lệ: 400; body trên 1 KB: 413.
- Tối đa 6 request/phút/IP, kể cả cache; không tin header X-Forwarded-For.
- Tối đa 2 yêu cầu AI đồng thời, 100 lần gọi nhà cung cấp/ngày UTC.
- Giới hạn đầu ra 600 token, timeout nhà cung cấp 55 giây; lỗi trả thông báo chung.
- Cache 30 phút theo mã câu và ngôn ngữ; không cache lỗi. Không tự retry gây tốn lượt.
- Test chỉ dùng fetch giả và khóa giả: `node --test server/server.test.js`.

Đây là cơ chế cho demo một tiến trình server. Mã dùng chung không xác định từng
người dùng. Hạn mức/cache nằm trong RAM, reset khi server khởi động lại và không
chia sẻ giữa nhiều instance. Khi mở cho nhiều người dùng, cần tài khoản/token
được xác thực, bộ đếm dùng chung và giới hạn ngân sách phía nhà cung cấp. Với
reverse proxy, các người dùng có thể cùng chịu giới hạn IP của proxy. Không xem
mã dùng chung là phương án xác thực người dùng cho sản phẩm công khai.

## Triển khai lên mạng (PaaS/VPS)

`Dockerfile` ở gốc repo đã gói server + ngân hàng câu hỏi; hướng dẫn Render,
Railway, Cloud Run, VPS và cách kiểm tra nằm trong
[`docs/deploy-ai.md`](../docs/deploy-ai.md). APK release phải trỏ tới URL HTTPS.
