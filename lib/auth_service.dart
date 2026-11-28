/// Tầng xác thực tách rời khỏi giao diện.
///
/// Hiện tại chỉ có bản hiện thực **mô phỏng** ([DemoAuthService]) chạy hoàn
/// toàn trên thiết bị để dùng thử khi chưa có backend. Nó **không phải** xác
/// thực thật và **không dùng được cho môi trường production**:
///
/// - Tài khoản được lưu trong `SharedPreferences` cục bộ (không gửi lên mạng).
/// - Mật khẩu được băm SHA-256 kèm muối (salt) ngẫu nhiên; **không lưu mật
///   khẩu dạng văn bản** trong dữ liệu người dùng hay `SharedPreferences`.
/// - Tài khoản mẫu `demo@example.com` / `Demo123!` chỉ tồn tại khi bật chế độ
///   demo (`AUTH_DEMO_ENABLED`, mặc định bật) và được đánh dấu rõ là tài khoản
///   mẫu.
///
/// Khi có backend thật (Firebase, Supabase, server riêng…), viết một lớp mới
/// hiện thực [AuthService] rồi thay đúng một chỗ khởi tạo ở `main.dart`; toàn
/// bộ giao diện không cần sửa lại.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_user.dart';

/// Lỗi xác thực dùng để giao diện hiển thị thông báo theo ngôn ngữ.
/// Không mang thông tin nhạy cảm (không cho biết email có tồn tại hay không).
enum AuthFailure {
  invalidCredentials,
  invalidEmail,
  missingName,
  weakPassword,
  emailInUse,
  googleNotConfigured,
  disabled,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException($failure)';
}

/// Cấu hình xác thực đọc từ `--dart-define` lúc build.
///
/// - `AUTH_DEMO_ENABLED` (`true`/`false`) bật/tắt chế độ demo. Khi kết nối
///   backend thật, đặt thành `false` (hoặc thay `AuthService` khác).
/// - `GOOGLE_OAUTH_ENABLED` (`true`/`false`) hiện/ẩn nút "Tiếp tục với Google".
/// - `GOOGLE_OAUTH_CLIENT_ID` là Client ID của Google OAuth; chưa có thì nút
///   Google chỉ hiển thị thông báo "chưa cấu hình" thay vì giả mạo thành công.
class AuthConfig {
  const AuthConfig({
    this.demoEnabled = true,
    this.googleEnabled = true,
    this.googleClientId = '',
  });

  final bool demoEnabled;
  final bool googleEnabled;
  final String googleClientId;

  bool get googleConfigured =>
      googleEnabled && googleClientId.trim().isNotEmpty;

  const AuthConfig.fromEnvironment()
    : demoEnabled = const bool.fromEnvironment(
        'AUTH_DEMO_ENABLED',
        defaultValue: true,
      ),
      googleEnabled = const bool.fromEnvironment(
        'GOOGLE_OAUTH_ENABLED',
        defaultValue: true,
      ),
      googleClientId = const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');
}

/// Giao diện xác thực dùng chung cho bản demo và bản thật.
///
/// Giao diện (các trang đăng nhập/đăng ký/hồ sơ) chỉ phụ thuộc vào giao diện
/// này, nên khi đổi sang Firebase/Supabase/backend riêng chỉ cần thay hiện
/// thực mà không phải viết lại UI.
abstract class AuthService {
  /// Chế độ demo có đang bật hay không (dùng để hiện thẻ tài khoản mẫu).
  bool get demoEnabled;

  /// Có hiện nút "Tiếp tục với Google" hay không.
  bool get googleEnabled;

  /// Google OAuth đã được cấu hình đủ (Client ID) hay chưa.
  bool get googleConfigured;

  /// Email tài khoản mẫu; `null` khi chế độ demo tắt hoặc backend thật.
  String? get demoEmail;

  /// Mật khẩu tài khoản mẫu; `null` khi chế độ demo tắt hoặc backend thật.
  String? get demoPassword;

  /// Khôi phục phiên đã lưu (nếu người dùng chọn "Ghi nhớ đăng nhập").
  /// Trả về `null` nếu chưa có phiên hợp lệ.
  Future<AuthUser?> restoreSession();

  /// Đăng nhập bằng email/mật khẩu. [remember] lưu phiên qua các lần mở app.
  Future<AuthUser> signIn({
    required String email,
    required String password,
    bool remember,
  });

  /// Đăng ký tài khoản mới rồi tự động đăng nhập.
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Đăng nhập bằng Google. Bản demo chưa tích hợp OAuth nên luôn ném
  /// [AuthException] với [AuthFailure.googleNotConfigured] (không giả thành công).
  Future<AuthUser> signInWithGoogle();

  /// Đăng xuất và xoá trạng thái đăng nhập đã lưu.
  Future<void> signOut();

  /// Cập nhật hồ sơ (họ tên / ảnh đại diện) của người dùng hiện tại.
  Future<AuthUser> updateProfile(AuthUser user);

  /// Email [email] có phải tài khoản mẫu hay không (để hiện nhãn demo).
  bool isDemoAccount(String email);
}

/// Bản ghi tài khoản lưu trong bộ nhớ cục bộ.
///
/// Chỉ chứa muối và giá trị băm của mật khẩu — **không** chứa mật khẩu văn bản.
class StoredAccount {
  const StoredAccount({
    required this.name,
    required this.email,
    required this.salt,
    required this.passwordHash,
    required this.joinedAt,
    this.avatarBase64,
  });

  final String name;
  final String email;
  final String salt;
  final String passwordHash;
  final DateTime joinedAt;
  final String? avatarBase64;

  AuthUser toUser() => AuthUser(
    name: name,
    email: email,
    joinedAt: joinedAt,
    avatarBase64: avatarBase64,
  );

  StoredAccount copyWith({
    String? name,
    String? avatarBase64,
    bool clearAvatar = false,
  }) {
    return StoredAccount(
      name: name ?? this.name,
      email: email,
      salt: salt,
      passwordHash: passwordHash,
      joinedAt: joinedAt,
      avatarBase64: clearAvatar ? null : (avatarBase64 ?? this.avatarBase64),
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'salt': salt,
    'passwordHash': passwordHash,
    'joinedAt': joinedAt.toIso8601String(),
    if (avatarBase64 != null && avatarBase64!.isNotEmpty)
      'avatarBase64': avatarBase64,
  };

  factory StoredAccount.fromJson(Map<String, Object?> json) {
    return StoredAccount(
      name: json['name'] as String? ?? '',
      email: (json['email'] as String? ?? '').trim().toLowerCase(),
      salt: json['salt'] as String? ?? '',
      passwordHash: json['passwordHash'] as String? ?? '',
      joinedAt:
          DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
          DateTime.now(),
      avatarBase64: json['avatarBase64'] as String?,
    );
  }
}

/// Nơi lưu tài khoản và phiên đăng nhập (tách để test dùng bản lưu trong RAM).
abstract class AuthStore {
  Future<List<StoredAccount>> loadAccounts();
  Future<void> saveAccounts(List<StoredAccount> accounts);
  Future<String?> loadSessionEmail();
  Future<void> saveSessionEmail(String? email);
}

/// Lưu bằng `SharedPreferences` (bền vững trên Android/iOS/Desktop).
class SharedPrefsAuthStore implements AuthStore {
  const SharedPrefsAuthStore({
    this.accountsKey = 'flutter_lab_accounts_v1',
    this.sessionKey = 'flutter_lab_session_v1',
  });

  final String accountsKey;
  final String sessionKey;

  @override
  Future<List<StoredAccount>> loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(accountsKey);
      if (raw == null || raw.trim().isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final accounts = <StoredAccount>[];
      for (final element in decoded) {
        try {
          if (element is Map<String, Object?>) {
            accounts.add(StoredAccount.fromJson(element));
          } else if (element is Map) {
            accounts.add(
              StoredAccount.fromJson(Map<String, Object?>.from(element)),
            );
          }
        } catch (e) {
          debugPrint('Bỏ qua tài khoản bị lỗi: $e');
        }
      }
      return accounts;
    } catch (e) {
      debugPrint('Lỗi đọc tài khoản từ SharedPreferences: $e');
      return const [];
    }
  }

  @override
  Future<void> saveAccounts(List<StoredAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      accountsKey,
      jsonEncode([for (final account in accounts) account.toJson()]),
    );
  }

  @override
  Future<String?> loadSessionEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(sessionKey);
      return (email == null || email.trim().isEmpty) ? null : email.trim();
    } catch (e) {
      debugPrint('Lỗi đọc phiên đăng nhập: $e');
      return null;
    }
  }

  @override
  Future<void> saveSessionEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email == null || email.trim().isEmpty) {
      await prefs.remove(sessionKey);
    } else {
      await prefs.setString(sessionKey, email.trim());
    }
  }
}

/// Lưu trong RAM dùng cho Unit Test / Widget Test.
class MemoryAuthStore implements AuthStore {
  MemoryAuthStore({List<StoredAccount>? accounts, this._sessionEmail})
    : _accounts = [...?accounts];

  final List<StoredAccount> _accounts;
  String? _sessionEmail;

  @override
  Future<List<StoredAccount>> loadAccounts() async => List.of(_accounts);

  @override
  Future<void> saveAccounts(List<StoredAccount> accounts) async {
    _accounts
      ..clear()
      ..addAll(accounts);
  }

  @override
  Future<String?> loadSessionEmail() async => _sessionEmail;

  @override
  Future<void> saveSessionEmail(String? email) async {
    _sessionEmail = (email == null || email.trim().isEmpty)
        ? null
        : email.trim();
  }
}

final Random _random = Random.secure();

String _generateSalt() =>
    base64UrlEncode(List<int>.generate(16, (_) => _random.nextInt(256)));

String _hashPassword(String password, String salt) =>
    sha256.convert(utf8.encode('$salt:$password')).toString();

String _normalizeEmail(String email) => email.trim().toLowerCase();

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool _isValidEmail(String email) => _emailPattern.hasMatch(email);

/// So sánh hai chuỗi băm theo thời gian hằng để hạn chế timing attack.
bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// Hiện thực xác thực **mô phỏng** cho chế độ demo.
///
/// KHÔNG dùng cho môi trường thật: tài khoản nằm trên thiết bị, không có
/// xác minh email hay khôi phục mật khẩu. Chỉ để chạy thử giao diện.
class DemoAuthService implements AuthService {
  DemoAuthService({
    this.config = const AuthConfig.fromEnvironment(),
    AuthStore? store,
  }) : _store = store ?? const SharedPrefsAuthStore();

  final AuthConfig config;
  final AuthStore _store;

  static const String _demoSeedEmail = 'demo@example.com';
  static const String _demoSeedPassword = 'Demo123!';
  static const String _demoSalt = 'flutter-lab-demo-account';
  static final String _demoHash = _hashPassword(_demoSeedPassword, _demoSalt);
  static final DateTime _demoJoinedAt = DateTime(2026, 1, 1);

  Future<void> _lock = Future<void>.value();

  /// Tuần tự hoá các thao tác đọc-sửa-ghi để tránh race condition.
  Future<T> _synchronized<T>(Future<T> Function() action) {
    final previous = _lock;
    final completer = Completer<void>();
    _lock = completer.future;
    return previous.catchError((_) {}).then((_) => action()).whenComplete(() {
      if (!completer.isCompleted) completer.complete();
    });
  }

  @override
  bool get demoEnabled => config.demoEnabled;

  @override
  bool get googleEnabled => config.googleEnabled;

  @override
  bool get googleConfigured => config.googleConfigured;

  @override
  String? get demoEmail => demoEnabled ? _demoSeedEmail : null;

  @override
  String? get demoPassword => demoEnabled ? _demoSeedPassword : null;

  @override
  bool isDemoAccount(String email) =>
      demoEnabled && _normalizeEmail(email) == _demoSeedEmail;

  AuthUser _demoUser() => AuthUser(
    name: 'Demo User',
    email: _demoSeedEmail,
    joinedAt: _demoJoinedAt,
  );

  @override
  Future<AuthUser?> restoreSession() async {
    if (!demoEnabled) return null;
    final email = await _store.loadSessionEmail();
    if (email == null) return null;
    final normalized = _normalizeEmail(email);
    if (normalized == _demoSeedEmail) return _demoUser();
    final accounts = await _store.loadAccounts();
    for (final account in accounts) {
      if (_normalizeEmail(account.email) == normalized) return account.toUser();
    }
    return null;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    bool remember = false,
  }) async {
    if (!demoEnabled) throw const AuthException(AuthFailure.disabled);

    final normalized = _normalizeEmail(email);
    if (!_isValidEmail(normalized)) {
      throw const AuthException(AuthFailure.invalidEmail);
    }

    AuthUser user;
    if (normalized == _demoSeedEmail) {
      final hash = _hashPassword(password, _demoSalt);
      if (!_constantTimeEquals(hash, _demoHash)) {
        throw const AuthException(AuthFailure.invalidCredentials);
      }
      user = _demoUser();
    } else {
      final accounts = await _store.loadAccounts();
      StoredAccount? match;
      for (final account in accounts) {
        if (_normalizeEmail(account.email) == normalized) {
          match = account;
          break;
        }
      }
      if (match == null ||
          !_constantTimeEquals(
            _hashPassword(password, match.salt),
            match.passwordHash,
          )) {
        throw const AuthException(AuthFailure.invalidCredentials);
      }
      user = match.toUser();
    }

    await _store.saveSessionEmail(remember ? normalized : null);
    return user;
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) => _synchronized(() async {
    if (!demoEnabled) throw const AuthException(AuthFailure.disabled);

    final trimmedName = name.trim();
    final normalized = _normalizeEmail(email);
    if (trimmedName.isEmpty) {
      throw const AuthException(AuthFailure.missingName);
    }
    if (!_isValidEmail(normalized)) {
      throw const AuthException(AuthFailure.invalidEmail);
    }
    if (password.length < 8) {
      throw const AuthException(AuthFailure.weakPassword);
    }

    final accounts = await _store.loadAccounts();
    if (normalized == _demoSeedEmail) {
      throw const AuthException(AuthFailure.emailInUse);
    }
    for (final account in accounts) {
      if (_normalizeEmail(account.email) == normalized) {
        throw const AuthException(AuthFailure.emailInUse);
      }
    }

    final salt = _generateSalt();
    final account = StoredAccount(
      name: trimmedName,
      email: normalized,
      salt: salt,
      passwordHash: _hashPassword(password, salt),
      joinedAt: DateTime.now(),
    );
    await _store.saveAccounts([...accounts, account]);
    await _store.saveSessionEmail(normalized);
    return account.toUser();
  });

  @override
  Future<AuthUser> signInWithGoogle() async {
    // Chưa có backend hay thông tin OAuth của Google. Không giả mạo thành công:
    // luôn báo "chưa cấu hình" để người dùng biết phần này cần cấu hình sau.
    throw const AuthException(AuthFailure.googleNotConfigured);
  }

  @override
  Future<void> signOut() => _synchronized(() => _store.saveSessionEmail(null));

  @override
  Future<AuthUser> updateProfile(AuthUser user) => _synchronized(() async {
    final normalized = _normalizeEmail(user.email);
    if (normalized == _demoSeedEmail) {
      // Tài khoản mẫu không lưu bền vững; thay đổi chỉ tồn tại trong phiên.
      return user;
    }
    final accounts = await _store.loadAccounts();
    final index = accounts.indexWhere(
      (account) => _normalizeEmail(account.email) == normalized,
    );
    if (index == -1) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    accounts[index] = accounts[index].copyWith(
      name: user.name,
      avatarBase64: user.hasAvatar ? user.avatarBase64 : null,
      clearAvatar: !user.hasAvatar,
    );
    await _store.saveAccounts(accounts);
    return accounts[index].toUser();
  });
}
