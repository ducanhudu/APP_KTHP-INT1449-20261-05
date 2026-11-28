import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'history_storage.dart';
import 'quiz_attempt.dart';

/// Account/session API for the optional self-hosted backend.
class AccountSession {
  const AccountSession({
    required this.token,
    required this.id,
    required this.email,
    required this.displayName,
    this.createdAt = '',
    this.avatarBase64,
  });

  final String token;
  final String id;
  final String email;
  final String displayName;
  final String createdAt;
  final String? avatarBase64;

  factory AccountSession.fromJson(Map<String, Object?> json) => AccountSession(
    token: json['token'] as String,
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    createdAt: json['createdAt'] as String? ?? '',
    avatarBase64: json['avatarBase64'] as String?,
  );

  Map<String, Object?> toJson() => {
    'token': token,
    'id': id,
    'email': email,
    'displayName': displayName,
    'createdAt': createdAt,
    if (avatarBase64 != null) 'avatarBase64': avatarBase64,
  };

  AccountSession copyWith({
    String? displayName,
    String? avatarBase64,
    bool clearAvatar = false,
  }) => AccountSession(
    token: token,
    id: id,
    email: email,
    displayName: displayName ?? this.displayName,
    createdAt: createdAt,
    avatarBase64: clearAvatar ? null : (avatarBase64 ?? this.avatarBase64),
  );
}

class AccountApiException implements Exception {
  const AccountApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AccountService {
  AccountService({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? _configuredBaseUrl).trim().replaceFirst(
        RegExp(r'/+$'),
        '',
      ),
      _client = client ?? http.Client();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'APP_API_URL',
    defaultValue: '',
  );
  static const String _sessionKey = 'flutter_lab_account_session_v1';
  static final AccountService instance = AccountService();

  final String baseUrl;
  final http.Client _client;
  bool get isConfigured => baseUrl.isNotEmpty;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<AccountSession?> loadSession() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _sessionKey,
      );
      if (raw == null) return null;
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      final map = Map<String, Object?>.from(value);
      if ([
        map['token'],
        map['id'],
        map['email'],
        map['displayName'],
      ].any((field) => field is! String || field.isEmpty)) {
        return null;
      }
      return AccountSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(AccountSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> logout(AccountSession session) async {
    final response = await _client.post(
      _uri('/api/auth/logout'),
      headers: {'Authorization': 'Bearer ${session.token}'},
    );
    if (response.statusCode != 204) {
      throw AccountApiException(
        _messageFor(_decode(response.body)['error'] as String?),
      );
    }
  }

  Future<AccountSession> register({
    required String email,
    required String password,
    String displayName = '',
  }) => _authenticate('/api/auth/register', {
    'email': email,
    'password': password,
    'displayName': displayName,
  });

  Future<AccountSession> login({
    required String email,
    required String password,
  }) =>
      _authenticate('/api/auth/login', {'email': email, 'password': password});

  Future<AccountSession> _authenticate(
    String path,
    Map<String, Object?> body,
  ) async {
    if (!isConfigured) {
      throw const AccountApiException(
        'Chưa cấu hình APP_API_URL khi build ứng dụng.',
      );
    }
    try {
      final response = await _client.post(
        _uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final decoded = _decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AccountApiException(_messageFor(decoded['error'] as String?));
      }
      final user = decoded['user'];
      final token = decoded['token'];
      if (user is! Map || token is! String) {
        throw const AccountApiException('Phản hồi máy chủ không hợp lệ.');
      }
      return AccountSession.fromJson({
        'token': token,
        ...Map<String, Object?>.from(user),
      });
    } on AccountApiException {
      rethrow;
    } catch (_) {
      throw const AccountApiException(
        'Không thể kết nối máy chủ. Kiểm tra mạng và địa chỉ API.',
      );
    }
  }

  Map<String, Object?> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } catch (_) {}
    return const {};
  }

  String _messageFor(String? error) => switch (error) {
    'email_already_registered' => 'Email này đã được đăng ký.',
    'invalid_credentials' => 'Email hoặc mật khẩu không đúng.',
    'invalid_registration' =>
      'Thông tin chưa hợp lệ. Mật khẩu cần ít nhất 8 ký tự.',
    'rate_limited' => 'Bạn thao tác quá nhanh. Vui lòng thử lại sau một phút.',
    'auth_not_configured' => 'Máy chủ chưa cấu hình xác thực.',
    _ => 'Đăng nhập không thành công. Vui lòng thử lại.',
  };

  Future<AccountSession> currentUser(AccountSession session) async {
    final response = await _client.get(
      _uri('/api/auth/me'),
      headers: {'Authorization': 'Bearer ${session.token}'},
    );
    if (response.statusCode != 200) {
      throw AccountApiException(
        _messageFor(_decode(response.body)['error'] as String?),
      );
    }
    final user = _decode(response.body)['user'];
    if (user is! Map) {
      throw const AccountApiException('Hồ sơ máy chủ không hợp lệ.');
    }
    final updated = AccountSession.fromJson({
      'token': session.token,
      ...Map<String, Object?>.from(user),
    });
    await saveSession(updated);
    return updated;
  }

  Future<AccountSession> updateProfile(
    AccountSession session, {
    required String displayName,
    String? avatarBase64,
    bool clearAvatar = false,
  }) async {
    final response = await _client.patch(
      _uri('/api/auth/me'),
      headers: {
        'Authorization': 'Bearer ${session.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'displayName': displayName,
        if (avatarBase64 != null || clearAvatar)
          'avatarBase64': clearAvatar ? null : avatarBase64,
      }),
    );
    if (response.statusCode != 200) {
      throw AccountApiException(
        _messageFor(_decode(response.body)['error'] as String?),
      );
    }
    final user = _decode(response.body)['user'];
    if (user is! Map) {
      throw const AccountApiException('Hồ sơ máy chủ không hợp lệ.');
    }
    final updated = AccountSession.fromJson({
      'token': session.token,
      ...Map<String, Object?>.from(user),
    });
    await saveSession(updated);
    return updated;
  }

  Future<List<QuizAttempt>> loadAttempts(AccountSession session) async {
    final response = await _client.get(
      _uri('/api/history'),
      headers: {'Authorization': 'Bearer ${session.token}'},
    );
    if (response.statusCode != 200) {
      throw AccountApiException(
        _messageFor(_decode(response.body)['error'] as String?),
      );
    }
    final raw = _decode(response.body)['attempts'];
    if (raw is! List) {
      throw const AccountApiException('Lịch sử máy chủ không hợp lệ.');
    }
    return [
      for (final value in raw)
        if (value is Map)
          QuizAttempt.fromJson(Map<String, Object?>.from(value)),
    ];
  }

  Future<void> saveAttempt(AccountSession session, QuizAttempt attempt) async {
    final response = await _client.post(
      _uri('/api/history'),
      headers: {
        'Authorization': 'Bearer ${session.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(attempt.toJson()),
    );
    if (response.statusCode != 201) {
      throw AccountApiException(
        _messageFor(_decode(response.body)['error'] as String?),
      );
    }
  }

  Future<void> deleteAttempt(AccountSession session, String id) async {
    final response = await _client.delete(
      _uri('/api/history/${Uri.encodeComponent(id)}'),
      headers: {'Authorization': 'Bearer ${session.token}'},
    );
    if (response.statusCode != 204) {
      throw AccountApiException(
        _messageFor(_decode(response.body)['error'] as String?),
      );
    }
  }

  Future<void> clearAttempts(AccountSession session) async {
    final response = await _client.delete(
      _uri('/api/history'),
      headers: {'Authorization': 'Bearer ${session.token}'},
    );
    if (response.statusCode != 204) {
      throw AccountApiException(
        _messageFor(_decode(response.body)['error'] as String?),
      );
    }
  }
}

/// Keeps a per-account local fallback while syncing authenticated history.
/// Unauthenticated local records are never copied into another user's account.
class AccountHistoryStorage implements HistoryStorage {
  AccountHistoryStorage({
    required this.session,
    required this.api,
    required this.local,
  });

  final AccountSession? Function() session;
  final AccountService api;
  final HistoryStorage local;

  @override
  Future<List<QuizAttempt>> loadHistory() async {
    final activeSession = session();
    final localItems = await local.loadHistory();
    if (activeSession == null || !api.isConfigured) return localItems;
    try {
      final remoteItems = await api.loadAttempts(activeSession);
      final remoteIds = remoteItems.map((attempt) => attempt.id).toSet();
      for (final attempt in localItems.where(
        (item) => !remoteIds.contains(item.id),
      )) {
        await api.saveAttempt(activeSession, attempt);
      }
      final merged = <String, QuizAttempt>{
        for (final attempt in remoteItems) attempt.id: attempt,
        for (final attempt in localItems) attempt.id: attempt,
      };
      return merged.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return localItems;
    }
  }

  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {
    await local.saveAttempt(attempt);
    final activeSession = session();
    if (activeSession != null && api.isConfigured) {
      await api.saveAttempt(activeSession, attempt);
    }
  }

  @override
  Future<void> deleteAttempt(String id) async {
    await local.deleteAttempt(id);
    final activeSession = session();
    if (activeSession != null && api.isConfigured) {
      await api.deleteAttempt(activeSession, id);
    }
  }

  @override
  Future<void> clearHistory() async {
    await local.clearHistory();
    final activeSession = session();
    if (activeSession != null && api.isConfigured) {
      await api.clearAttempts(activeSession);
    }
  }
}
