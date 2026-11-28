import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'auth_user.dart';

/// Quản lý trạng thái đăng nhập cho toàn ứng dụng.
///
/// Giao diện lắng nghe controller này để cập nhật nút tài khoản, hồ sơ thành
/// viên và điều hướng đăng nhập/đăng xuất mà không phụ thuộc vào hiện thực
/// [AuthService] cụ thể.
class AuthController extends ChangeNotifier {
  AuthController(this.service);

  final AuthService service;

  AuthUser? _user;

  /// Người dùng đang đăng nhập; `null` khi chưa đăng nhập.
  AuthUser? get user => _user;

  bool get isAuthenticated => _user != null;

  bool get demoEnabled => service.demoEnabled;
  bool get googleEnabled => service.googleEnabled;
  bool get googleConfigured => service.googleConfigured;
  String? get demoEmail => service.demoEmail;
  String? get demoPassword => service.demoPassword;

  /// Người dùng hiện tại có phải tài khoản mẫu (demo) hay không.
  bool get isDemoAccount =>
      _user != null && service.isDemoAccount(_user!.email);

  /// Khôi phục phiên đã lưu (nếu có). Không ném lỗi ra ngoài để app vẫn mở
  /// được bình thường kể cả khi chưa có backend/bộ nhớ.
  Future<void> restore() async {
    try {
      _user = await service.restoreSession();
    } catch (_) {
      _user = null;
    }
    notifyListeners();
  }

  Future<AuthUser> signIn({
    required String email,
    required String password,
    bool remember = false,
  }) async {
    final user = await service.signIn(
      email: email,
      password: password,
      remember: remember,
    );
    _user = user;
    notifyListeners();
    return user;
  }

  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = await service.signUp(
      name: name,
      email: email,
      password: password,
    );
    _user = user;
    notifyListeners();
    return user;
  }

  Future<AuthUser> signInWithGoogle() async {
    final user = await service.signInWithGoogle();
    _user = user;
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    await service.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile(AuthUser updated) async {
    _user = await service.updateProfile(updated);
    notifyListeners();
  }
}
