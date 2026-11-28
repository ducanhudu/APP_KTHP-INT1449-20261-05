# Đăng nhập, đăng ký và hồ sơ thành viên (chế độ demo)

Ứng dụng thêm luồng **đăng nhập / đăng ký / hồ sơ thành viên** hoạt động ngay
khi **chưa có backend**, bằng bộ xác thực **mô phỏng** chạy hoàn toàn trên thiết
bị. Bộ xác thực này **không dùng được cho môi trường thật**: dữ liệu nằm trong
`SharedPreferences` của máy, không có xác minh email hay khôi phục mật khẩu.

## Các tệp chính

| Tệp | Vai trò |
| --- | --- |
| `lib/auth_user.dart` | Mô hình `AuthUser` (họ tên, email, ảnh đại diện, ngày tham gia) — không chứa mật khẩu |
| `lib/auth_service.dart` | `AuthService` (giao diện), `DemoAuthService` (bản demo), kho lưu tài khoản/phiên |
| `lib/auth_controller.dart` | `AuthController` quản lý trạng thái đăng nhập cho giao diện |
| `lib/auth_pages.dart` | Trang đăng nhập, đăng ký và nút "Tiếp tục với Google" |
| `lib/profile_page.dart` | Trang "Thông tin thành viên" (ảnh đại diện, sửa tên/ảnh, đăng xuất) |

## Tài khoản mẫu (chỉ chạy khi bật chế độ demo)

| Trường | Giá trị |
| --- | --- |
| Email | `demo@example.com` |
| Mật khẩu | `Demo123!` |

Tài khoản mẫu được đánh dấu rõ trong trang đăng nhập và trang hồ sơ. Mật khẩu
**không được lưu dạng văn bản**: tài khoản thật lưu `muối (salt)` + giá trị băm
SHA-256; tài khoản mẫu chỉ so khớp giá trị băm cố định trong mã.

## Bật / tắt chế độ demo

Chế độ demo đọc từ `--dart-define` lúc build, mặc định **bật**:

```powershell
flutter run --dart-define=AUTH_DEMO_ENABLED=true
```

Khi đã có backend thật, tắt demo và (nếu muốn) cung cấp Client ID Google OAuth:

```powershell
flutter run `
  --dart-define=AUTH_DEMO_ENABLED=false `
  --dart-define=GOOGLE_OAUTH_ENABLED=true `
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=<client-id>.apps.googleusercontent.com
```

| Biến build | Ý nghĩa | Mặc định |
| --- | --- | --- |
| `AUTH_DEMO_ENABLED` | Bật/tắt tài khoản mẫu và đăng nhập mô phỏng | `true` |
| `GOOGLE_OAUTH_ENABLED` | Hiện/ẩn nút "Tiếp tục với Google" | `true` |
| `GOOGLE_OAUTH_CLIENT_ID` | Client ID Google OAuth (chưa có → nút chỉ báo chưa cấu hình) | rỗng |

## Nơi cấu hình Google OAuth

Hiện tại nút "Tiếp tục với Google" **chỉ hiện giao diện** và báo "chưa cấu hình"
thay vì giả mạo đăng nhập thành công. Để bật thật:

1. Tạo OAuth Client ID cho Android trong Google Cloud Console.
2. Truyền `GOOGLE_OAUTH_CLIENT_ID` lúc build (xem bảng trên).
3. Thay `DemoAuthService.signInWithGoogle()` bằng luồng OAuth thật (Firebase
   Auth, `google_sign_in` hoặc Supabase). Giao diện không cần đổi vì chỉ phụ
   thuộc vào giao diện `AuthService`.

## Đổi bộ xác thực demo bằng API thật

Toàn bộ giao diện (`auth_pages.dart`, `profile_page.dart`) chỉ phụ thuộc vào
`AuthService` và `AuthController`, không phụ thuộc `DemoAuthService`. Để nối
backend thật:

1. Viết lớp mới hiện thực `AuthService` (ví dụ `FirebaseAuthService`,
   `SupabaseAuthService`…).
2. Thay đúng một chỗ khởi tạo trong `lib/main.dart` (truyền vào `FlutterLab`
   hoặc đổi `DemoAuthService()` thành lớp mới).

Không cần viết lại trang đăng nhập, đăng ký hay hồ sơ.

## Lưu ý bảo mật

- Đây là xác thực **mô phỏng**, chỉ để chạy thử. Không dùng cho sản phẩm thật.
- Thông báo lỗi đăng nhập dùng chung "Email hoặc mật khẩu không đúng" để không
  lộ email nào đã tồn tại trong hệ thống.
- Phiên đăng nhập chỉ được lưu lại khi người dùng chọn "Ghi nhớ đăng nhập".
