import 'account_service.dart';
import 'auth_service.dart';
import 'auth_user.dart';

/// Adapts the server-backed account API to the app's existing auth screens.
class BackendAuthService implements AuthService {
  const BackendAuthService(this.api);

  final AccountService api;

  @override
  bool get demoEnabled => false;
  @override
  bool get googleEnabled => false;
  @override
  bool get googleConfigured => false;
  @override
  String? get demoEmail => null;
  @override
  String? get demoPassword => null;
  @override
  bool isDemoAccount(String email) => false;

  AuthUser _toUser(AccountSession session) => AuthUser(
    name: session.displayName,
    email: session.email,
    joinedAt: DateTime.tryParse(session.createdAt) ?? DateTime.now(),
    avatarBase64: session.avatarBase64,
  );

  @override
  Future<AuthUser?> restoreSession() async {
    final session = await api.loadSession();
    return session == null ? null : _toUser(session);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    bool remember = false,
  }) async {
    try {
      final session = await api.login(email: email, password: password);
      await api.saveSession(session);
      return _toUser(session);
    } on AccountApiException catch (error) {
      if (error.message.contains('Email hoặc mật khẩu')) {
        throw const AuthException(AuthFailure.invalidCredentials);
      }
      rethrow;
    }
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (password.length < 8) {
      throw const AuthException(AuthFailure.weakPassword);
    }
    try {
      final session = await api.register(
        email: email,
        password: password,
        displayName: name,
      );
      await api.saveSession(session);
      return _toUser(session);
    } on AccountApiException catch (error) {
      if (error.message.contains('đã được đăng ký')) {
        throw const AuthException(AuthFailure.emailInUse);
      }
      rethrow;
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() =>
      Future.error(const AuthException(AuthFailure.googleNotConfigured));

  @override
  Future<void> signOut() async {
    final session = await api.loadSession();
    if (session != null) {
      try {
        await api.logout(session);
      } catch (_) {
        // Clear local login even offline; the server session expires naturally.
      } finally {
        await api.clearSession();
      }
    }
  }

  @override
  Future<AuthUser> updateProfile(AuthUser user) async {
    final session = await api.loadSession();
    if (session == null) throw const AuthException(AuthFailure.disabled);
    final updated = await api.updateProfile(
      session,
      displayName: user.name,
      avatarBase64: user.avatarBase64,
      clearAvatar: !user.hasAvatar,
    );
    return _toUser(updated);
  }
}
