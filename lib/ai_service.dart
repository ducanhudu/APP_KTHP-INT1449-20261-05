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
/// Nếu API không phản hồi trong 5 giây hoặc lỗi, dùng lời giải gốc.
class AiService {
  /// Thay bằng URL thực khi tích hợp backend.
  /// Ví dụ: https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent
  static const String _baseUrl = String.fromEnvironment(
    'AI_API_URL',
    defaultValue: '',
  );

  static const Duration _timeout = Duration(seconds: 5);

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
      final prompt =
          'Giải thích ngắn gọn câu hỏi Flutter/Dart sau bằng '
          '${language == QuestionLanguage.english ? 'English' : 'tiếng Việt'}:\n\n'
          '${language.display(question.vi, question.en)}\n\n'
          'Đáp án đúng: ${question.correctId}\n'
          'Lời giải gốc: $fallback';

      final uri = Uri.parse(url);
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      });

      final request = client == null
          ? http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
          : client.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            );
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
