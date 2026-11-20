# Đưa AI lên Internet (Vercel) — để gửi APK cho người khác dùng

Mục tiêu: có một URL **HTTPS cố định** cho proxy, build vào APK, rồi ai cài APK
cũng dùng được AI mà không phải cấu hình gì.

Vì sao không dùng tunnel tạm: `cloudflared` quick tunnel đổi URL mỗi lần chạy và
đứt khi mất mạng — chỉ hợp để demo tại chỗ.

## Điều kiện

- Tài khoản GitHub (đã có, vì repo đang ở GitHub).
- Tài khoản Vercel (miễn phí, đăng nhập bằng GitHub, **không cần thẻ**).
- Khoá Gemini (đã có) và một mã truy cập tự đặt, ví dụ `flutterlab-demo-2026`.

## Các bước (khoảng 10 phút)

1. Vào https://vercel.com → **Continue with GitHub**.
2. **Add New… → Project** → chọn repo `APP_KTHP-INT1449-20261-05`.
3. Ở phần **Configure Project**:
   - Framework Preset: **Other**
   - Build Command / Output Directory: **để trống**
   - Root Directory: **để trống** (repo root)
4. Mở **Environment Variables**, thêm hai biến cho **Production + Preview**:

   | Name | Value |
   | --- | --- |
   | `GEMINI_API_KEY` | khoá Gemini của nhóm (dán trực tiếp, không commit) |
   | `AI_ACCESS_CODE` | `flutterlab-demo-2026` (hoặc mã khác do nhóm đặt) |

5. Bấm **Deploy**. Đợi ~1 phút.
6. Kiểm tra: mở `https://<tên-project>.vercel.app/health` → phải thấy
   `{"ok":true,"configured":true}`.
7. Thử gọi AI (thay `<host>` và mã):

   ```powershell
   curl.exe -s -X POST "https://<host>/explain" `
     -H "Content-Type: application/json" `
     -H "Authorization: Bearer flutterlab-demo-2026" `
     -d '{\"questionId\":7,\"language\":\"vi\"}'
   ```

   Kết quả mong đợi: `{"text":"..."}` trong 1–5 giây.

8. Gửi lại tôi URL đó. Tôi build APK release với:

   ```powershell
   flutter build apk --release `
     --dart-define=AI_API_URL=https://<host>/explain `
     --dart-define=AI_ACCESS_CODE=flutterlab-demo-2026
   ```

   Từ đây **ai cài APK cũng dùng được AI**, không phải nhập mã.

## Ghi chú vận hành

- Vercel gói miễn phí: function tự "ngủ" khi không dùng; request đầu tiên có thể
  chậm thêm 0,5–1 giây.
- Cache và hạn mức nằm trong bộ nhớ **của từng instance**, nên có thể mỗi
  instance đếm riêng. Hạn mức mặc định: 30 request/phút/IP, 1000 request/ngày,
  tối đa 2 request đồng thời (đổi bằng biến môi trường `AI_MINUTE_LIMIT`,
  `AI_DAILY_LIMIT`).
- Đổi mã truy cập hoặc đổi khoá: sửa Environment Variables trên Vercel → **Redeploy**.
  App phải build lại nếu đổi mã (vì mã được nhúng lúc build).
- Thu hồi khoá: xoá biến trên Vercel, tạo khoá mới ở Google AI Studio, cập nhật lại.

## Bảo mật

- Khoá **chỉ** nằm trong Environment Variables của Vercel; không có trong repo,
  không có trong APK.
- Mã truy cập nằm trong APK là chấp nhận được: nó chỉ là cổng chặn lạm dụng, không
  phải khoá nhà cung cấp. Ai có APK đều dùng được — đúng ý "gửi cho người khác".
- Proxy chỉ nhận `questionId` của 300 câu trong ngân hàng, không nhận prompt tự do.
