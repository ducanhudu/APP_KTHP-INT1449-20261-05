/// AI Explain Service – Ngày 3
/// Gọi API để lấy giải thích câu sai. Nếu lỗi hoặc timeout trả về lời giải
/// gốc từ dữ liệu JSON (explanationVi / explanationEn).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'question.dart';

/// Kết quả trả về từ dịch vụ AI.
class AiResult {
  const AiResult({required this.text, required this.fromFallback});

  /// Nội dung giải thích (từ AI hoặc fallback JSON).
  final String text;

  /// true nếu đây là lời giải gốc từ JSON (không phải AI trả về).
  final bool fromFallback;
}

/// Dịch vụ gọi AI để giải thích câu hỏi.
/// Nếu API không phản hồi trong 65 giây hoặc lỗi, dùng lời giải gốc.
class AiService {
  // Demo access code entered by the user, kept only for the current app session.
  // This is separate from the provider API key, which stays on the server.
  // Mã truy cập demo: có thể nhúng lúc build bằng --dart-define=AI_ACCESS_CODE=...
  // để người nhận APK không phải gõ tay. Đây KHÔNG phải khoá nhà cung cấp AI.
  static String accessCode = const String.fromEnvironment('AI_ACCESS_CODE');
  static bool get isConfigured => _baseUrl.isNotEmpty;
  static bool get isAskConfigured => _resolveAskEndpoint(null).isNotEmpty;

  /// Proxy công khai của nhóm dùng cho tính năng hỏi tự do nếu build không
  /// truyền AI_API_URL/AI_ASK_API_URL. Không chứa mã truy cập hay khóa Gemini.
  static const String _defaultAskUrl =
      'https://flutterlab-ai-proxy.onrender.com/ask';

  /// URL của proxy nhóm triển khai, không phải URL nhà cung cấp AI.
  static const String _baseUrl = String.fromEnvironment(
    'AI_API_URL',
    defaultValue: '',
  );
  static const String _askBaseUrl = String.fromEnvironment(
    'AI_ASK_API_URL',
    defaultValue: '',
  );
  static const int maxAskLength = 500;

  // Model thật có thể trả lời 5-90 giây tuỳ tải. Proxy có cache theo nội dung
  // câu hỏi, nên lần hỏi đầu có thể chậm còn bấm 'Hỏi lại' sẽ nhận ngay.
  static const Duration _timeout = Duration(seconds: 65);

  /// Lấy giải thích AI cho [question] theo [language].
  /// Fallback sang lời giải gốc nếu URL chưa cấu hình hoặc gặp lỗi.
  ///
  /// [client] và [endpoint] chỉ dùng trong test: thay mạng thật và URL build-time.
  static Future<AiResult> explain({
    required Question question,
    required QuestionLanguage language,
    http.Client? client,
    String? endpoint,
  }) async {
    final fallback = language.display(
      question.explanationVi,
      question.explanationEn,
    );

    // Nếu URL chưa cấu hình → dùng fallback ngay
    final url = endpoint ?? _baseUrl;
    if (url.isEmpty) {
      return AiResult(text: fallback, fromFallback: true);
    }

    try {
      final uri = Uri.parse(url);
      final body = jsonEncode({
        'questionId': question.id,
        'language': switch (language) {
          QuestionLanguage.vietnamese => 'vi',
          QuestionLanguage.english => 'en',
          QuestionLanguage.bilingual => 'bilingual',
        },
      });
      final headers = {
        'Content-Type': 'application/json',
        if (accessCode.isNotEmpty) 'Authorization': 'Bearer $accessCode',
      };

      final request = client == null
          ? http.post(uri, headers: headers, body: body)
          : client.post(uri, headers: headers, body: body);
      final response = await request.timeout(_timeout);

      if (response.statusCode == 200) {
        final text = _extractText(response.body);
        if (text != null && text.trim().isNotEmpty) {
          return AiResult(text: text.trim(), fromFallback: false);
        }
      }
    } catch (e) {
      debugPrint('AI explain error: $e');
    }

    // Mọi lỗi → fallback lời giải JSON
    return AiResult(text: fallback, fromFallback: true);
  }

  /// Gửi câu hỏi tự do tới route công khai có giới hạn sử dụng. Không có câu
  /// trả lời dự phòng: endpoint hoặc nhà cung cấp lỗi thì trả về null.
  /// [endpoint] nếu truyền vào là URL explain thì tự đổi thành URL ask.
  static Future<AiResult?> ask({
    required String question,
    required QuestionLanguage language,
    http.Client? client,
    String? endpoint,
  }) async {
    final normalized = question.trim();
    if (normalized.isEmpty || normalized.length > maxAskLength) return null;
    final url = _resolveAskEndpoint(endpoint);
    if (url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      final body = jsonEncode({
        'question': normalized,
        'language': switch (language) {
          QuestionLanguage.vietnamese => 'vi',
          QuestionLanguage.english => 'en',
          QuestionLanguage.bilingual => 'bilingual',
        },
      });
      final headers = {'Content-Type': 'application/json'};
      final request = client == null
          ? http.post(uri, headers: headers, body: body)
          : client.post(uri, headers: headers, body: body);
      final response = await request.timeout(_timeout);
      if (response.statusCode != 200) return null;
      final text = _extractText(response.body);
      if (text == null || text.trim().isEmpty) return null;
      return AiResult(text: text.trim(), fromFallback: false);
    } catch (e) {
      debugPrint('AI question error: $e');
      return null;
    }
  }

  static String _resolveAskEndpoint(String? endpoint) {
    final configured =
        endpoint ??
        (_askBaseUrl.isNotEmpty
            ? _askBaseUrl
            : _baseUrl.isNotEmpty
            ? _baseUrl
            : _defaultAskUrl);
    if (configured.isEmpty) return '';
    try {
      final uri = Uri.parse(configured);
      final path = uri.path;
      if (path.endsWith('/ask')) return uri.toString();
      final askPath = path.endsWith('/explain')
          ? '${path.substring(0, path.length - 'explain'.length)}ask'
          : '${path.endsWith('/') ? path : '$path/'}ask';
      return uri.replace(path: askPath).toString();
    } catch (_) {
      return '';
    }
  }

  /// Đọc nội dung trả về của hai kiểu backend:
  /// - Gemini: `candidates[0].content.parts[0].text`
  /// - backend tự viết: `{"text": "..."}` hoặc `{"explanation": "..."}`
  static String? _extractText(String body) {
    final data = jsonDecode(body);
    if (data is! Map) return null;
    final candidates = data['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final parts = candidates.first?['content']?['parts'];
      if (parts is List && parts.isNotEmpty) {
        final text = parts.first?['text'];
        if (text is String) return text;
      }
    }
    for (final key in const ['text', 'explanation']) {
      final value = data[key];
      if (value is String) return value;
    }
    return null;
  }
}
