/// Mô hình hồ sơ thành viên đã đăng nhập.
///
/// Lớp này chỉ chứa thông tin công khai (họ tên, email, ảnh đại diện, ngày
/// tham gia). **Không bao giờ** chứa mật khẩu hay dữ liệu nhạy cảm nào.
library;

class AuthUser {
  const AuthUser({
    required this.name,
    required this.email,
    required this.joinedAt,
    this.avatarBase64,
  });

  /// Họ tên hiển thị của thành viên.
  final String name;

  /// Email đăng nhập (đã chuẩn hoá về chữ thường).
  final String email;

  /// Ngày tham gia (ngày tạo tài khoản).
  final DateTime joinedAt;

  /// Ảnh đại diện đã mã hoá base64 (JPEG/PNG). `null` hoặc rỗng nghĩa là
  /// dùng ảnh đại diện mặc định (chữ cái đầu của họ tên).
  final String? avatarBase64;

  /// Có ảnh đại diện tuỳ chỉnh hay chưa.
  bool get hasAvatar => avatarBase64 != null && avatarBase64!.trim().isNotEmpty;

  /// Hai chữ cái đầu dùng cho ảnh đại diện mặc định.
  /// Ví dụ: "Nguyễn Văn An" → "NA", "Demo" → "D".
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  AuthUser copyWith({
    String? name,
    String? avatarBase64,
    bool clearAvatar = false,
  }) {
    return AuthUser(
      name: name ?? this.name,
      email: email,
      joinedAt: joinedAt,
      avatarBase64: clearAvatar ? null : (avatarBase64 ?? this.avatarBase64),
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'joinedAt': joinedAt.toIso8601String(),
    if (hasAvatar) 'avatarBase64': avatarBase64,
  };

  factory AuthUser.fromJson(Map<String, Object?> json) {
    return AuthUser(
      name: json['name'] as String? ?? '',
      email: (json['email'] as String? ?? '').trim().toLowerCase(),
      joinedAt:
          DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
          DateTime.now(),
      avatarBase64: json['avatarBase64'] as String?,
    );
  }
}
