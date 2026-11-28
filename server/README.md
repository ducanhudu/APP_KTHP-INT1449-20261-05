# Backend Flutter Lab

Yêu cầu Node.js 22. Không cần npm install. Server cung cấp đăng ký/đăng nhập,
đồng bộ lịch sử làm bài theo tài khoản và giữ nguyên proxy AI `POST /explain`.

## Tài khoản và lịch sử

Đặt JWT secret mạnh (ít nhất 32 byte) và khởi động server từ thư mục repo:

```powershell
$env:AUTH_JWT_SECRET = (& node -e "process.stdout.write(require('node:crypto').randomBytes(48).toString('base64url'))")
# Giữ nguyên giá trị này khi restart; mất secret sẽ làm token hiện tại hết hiệu lực.
$env:DATA_FILE = 'server/data/store.json' # mặc định; dữ liệu người dùng không commit
node server/server.js
```

Tệp JSON lưu user, hash mật khẩu `scrypt`, phiên đăng nhập, log đăng ký/đăng nhập
và tối đa 100 lượt làm bài mỗi tài khoản. Mật khẩu gốc không được lưu. API:

| Method | Endpoint | Nội dung |
| --- | --- | --- |
| `POST` | `/api/auth/register` | Tạo tài khoản (email, mật khẩu từ 8 ký tự, tên hiển thị tuỳ chọn) |
| `POST` | `/api/auth/login` | Đăng nhập, trả bearer token 30 ngày |
| `GET/PATCH` | `/api/auth/me` | Xem/cập nhật tên hiển thị và avatar của tài khoản |
| `GET` | `/api/auth/events` | Xem 100 sự kiện đăng ký/đăng nhập/đăng xuất gần nhất của chính mình |
| `POST` | `/api/auth/logout` | Thu hồi phiên token hiện tại |
| `GET/POST` | `/api/history` | Đọc/lưu lịch sử của tài khoản hiện tại |
| `DELETE` | `/api/history/{id}` hoặc `/api/history` | Xoá một lượt / toàn bộ lịch sử |

Mọi endpoint history yêu cầu `Authorization: Bearer <token>`. Server chỉ lấy user
ID từ token đã ký; kiểm tra lại đáp án với ngân hàng câu hỏi và tính điểm phía
server. `GET /api/health` báo `accounts: true` khi đã cấu hình secret.

Kết nối app bằng build define (chỉ URL, không đưa secret vào APK):

```powershell
flutter run --dart-define=APP_API_URL=https://your-server.example
```

Với Android debug qua USB, dùng `adb reverse tcp:8787 tcp:8787` và
`--dart-define=APP_API_URL=http://127.0.0.1:8787`. APK phát hành cần HTTPS.

**Lưu ý triển khai:** backend file JSON hỗ trợ một tiến trình/một instance; không
chạy nhiều replicas cùng dùng một file. Docker đặt data tại `/data/store.json`,
cần persistent volume tại `/data`. Nếu mở rộng nhiều instance hoặc dùng dữ liệu
sản phẩm, chuyển sang PostgreSQL/SQLite có giao dịch, backup và quản lý migration.
Token session lưu trên thiết bị để duy trì đăng nhập; không lưu mật khẩu.

## Proxy AI (tuỳ chọn)

Server giữ khoá Gemini. `POST /explain` nhận `{ "questionId": 1, "language": "vi" }`
và yêu cầu `AI_ACCESS_CODE`; `POST /ask` nhận `{ "question": "Flutter là gì?", "language": "vi" }`
và không yêu cầu mã truy cập. `/ask` giới hạn 500 ký tự, theo IP và ngân sách/ngày.
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

`GET /health` trả `configured: true` khi có `GEMINI_API_KEY` và báo riêng
`accessCodeRequired`. Câu hỏi mở cần khóa Gemini; `/explain` cần thêm mã truy cập.

## Chạy AI thật

Trên server, đặt `GEMINI_API_KEY` từ nhà cung cấp. `AI_ACCESS_CODE` chỉ cần nếu
muốn bảo vệ `/explain`; `/ask` công khai nhưng có hạn mức chặt. Bỏ `AI_UPSTREAM`
để dùng model mặc định. Không commit bí mật hay đưa khóa Gemini vào `--dart-define`.

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

- `/explain` không có mã hoặc mã sai: 401; câu không hợp lệ: 400; body trên 4 KB: 413; `/ask` giới hạn 500 ký tự.
- `/ask` tối đa 3 request/phút/IP và 100 lần gọi nhà cung cấp/ngày UTC; `/explain` tối đa 30 request/phút/IP và 1.000 lần gọi/ngày.
- Cả hai route dùng chung giới hạn 2 yêu cầu AI đồng thời; không tin header X-Forwarded-For.
- Giới hạn đầu ra 600 token, timeout nhà cung cấp 55 giây; lỗi trả thông báo chung.
- Cache 30 phút theo mã câu hoặc nội dung hỏi và ngôn ngữ; không cache lỗi. Không tự retry gây tốn lượt.
- Test auth, quyền sở hữu và độ bền dữ liệu: `node --test server/accounts.test.js server/server.test.js`.

Giới hạn AI theo IP/cache/ngân sách vẫn là bộ đếm trong RAM, reset khi restart và
không chia sẻ giữa nhiều instance. Reverse proxy khiến nhiều client có thể dùng
chung một IP quota; server cố ý không tin `X-Forwarded-For`. Tài khoản và lịch sử
lưu bền trên JSON, nhưng chỉ an toàn với một server process. Không chạy nhiều
replicas cùng file; môi trường production nhiều người dùng nên dùng database giao
dịch và rate limit dùng chung. Không dùng HTTP công khai.

## Triển khai lên mạng (PaaS/VPS)

`Dockerfile` ở gốc repo đã gói server + ngân hàng câu hỏi; hướng dẫn Render,
Railway, Cloud Run, VPS và cách kiểm tra nằm trong
[`docs/deploy-ai.md`](../docs/deploy-ai.md). APK release phải trỏ tới URL HTTPS.
