/// test/ai_service_test.dart – Unit test cho AiService
///
/// Kiểm tra 3 tình huống thật của lớp gọi AI:
/// 1. Chưa cấu hình AI_API_URL → lời giải gốc từ JSON.
/// 2. Server giữ khoá trả về đúng định dạng Gemini → dùng nội dung AI.
/// 3. Server trả lời kiểu `{"text": ...}` hoặc lỗi 500 → đọc được / rơi về JSON.
library;

import 'dart:convert';

import 'package:flutter_quiz_app/ai_service.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Câu hỏi mẫu dùng trong test.
Question _sampleQuestion() {
  return Question.fromJson({
    'id': 1,
    'topic': 1,
    'level': 'easy',
    'question_vi': 'Dart là ngôn ngữ gì?',
    'question_en': 'What is Dart?',
    'code_snippet': '',
    'explanation_vi': 'Dart là ngôn ngữ lập trình hướng đối tượng.',
    'explanation_en': 'Dart is an object-oriented programming language.',
    'correct_answer': 'A',
    'options': [
      {'id': 'A', 'vi': 'Hướng đối tượng', 'en': 'Object-oriented'},
      {'id': 'B', 'vi': 'Hàm thuần túy', 'en': 'Pure functional'},
      {'id': 'C', 'vi': 'Lập trình logic', 'en': 'Logic programming'},
      {'id': 'D', 'vi': 'Lập trình tuyến tính', 'en': 'Linear programming'},
    ],
  });
}

void main() {
  tearDown(() => AiService.accessCode = '');
  test('Gửi mã truy cập và chỉ mã câu, không gửi prompt tùy ý', () async {
    AiService.accessCode = 'session-code';
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer session-code');
      expect(jsonDecode(request.body), {'questionId': 1, 'language': 'en'});
      return http.Response('{"error":"unauthorized"}', 401);
    });
    final q = _sampleQuestion();
    final result = await AiService.explain(
      question: q,
      language: QuestionLanguage.english,
      endpoint: 'https://ai.test/explain',
      client: client,
    );
    expect(result.fromFallback, isTrue);
    expect(result.text, q.explanationEn);
  });
  group('AiService', () {
    test('Sends a free-form question to the derived /ask URL', () async {
      AiService.accessCode = 'session-code';
      Uri? requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer session-code');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(jsonDecode(request.body), {
          'question': 'Flutter là gì?',
          'language': 'vi',
        });
        return http.Response(
          jsonEncode({'text': 'Flutter là framework.'}),
          200,
        );
      });

      final result = await AiService.ask(
        question: '  Flutter là gì?  ',
        language: QuestionLanguage.vietnamese,
        endpoint: 'https://ai.test/api/explain',
        client: client,
      );

      expect(requestedUri?.path, '/api/ask');
      expect(result?.fromFallback, isFalse);
      expect(result?.text, 'Flutter là framework.');
    });

    test(
      'Returns no fake answer when an open-question request fails',
      () async {
        final client = MockClient(
          (_) async => http.Response('{"error":"rate_limited"}', 429),
        );
        final result = await AiService.ask(
          question: 'Flutter là gì?',
          language: QuestionLanguage.vietnamese,
          endpoint: 'https://ai.test/explain',
          client: client,
        );
        expect(result, isNull);
      },
    );

    test('Rejects empty or too-long questions before sending', () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('{"text":"ok"}', 200);
      });
      expect(
        await AiService.ask(
          question: ' ',
          language: QuestionLanguage.vietnamese,
          endpoint: 'https://ai.test/explain',
          client: client,
        ),
        isNull,
      );
      expect(
        await AiService.ask(
          question: List.filled(501, 'x').join(),
          language: QuestionLanguage.vietnamese,
          endpoint: 'https://ai.test/explain',
          client: client,
        ),
        isNull,
      );
      expect(requests, 0);
    });

    test('Trả về fallback lời giải gốc khi AI_API_URL chưa cấu hình', () async {
      // Vì biến môi trường AI_API_URL không được set trong test, AiService
      // phải trả về fromFallback=true với text từ explanationVi.
      final q = _sampleQuestion();
      final result = await AiService.explain(
        question: q,
        language: QuestionLanguage.vietnamese,
      );

      expect(result.fromFallback, isTrue);
      expect(result.text, equals(q.explanationVi));
    });

    test('Trả về fallback bằng tiếng Anh khi language=english', () async {
      final q = _sampleQuestion();
      final result = await AiService.explain(
        question: q,
        language: QuestionLanguage.english,
      );

      expect(result.fromFallback, isTrue);
      expect(result.text, equals(q.explanationEn));
    });
  });

  group('AiService với server giữ khoá (dùng MockClient)', () {
    test('Đọc đúng định dạng Gemini của proxy', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        // App phải gửi prompt lên server, không phải khoá.
        expect(jsonDecode(request.body), {'questionId': 1, 'language': 'vi'});
        expect(request.headers['Content-Type'], contains('application/json'));
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Câu này nói về hướng đối tượng.'},
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await AiService.explain(
        question: _sampleQuestion(),
        language: QuestionLanguage.vietnamese,
        client: client,
        endpoint: 'https://ai.test/explain',
      );

      expect(result.fromFallback, isFalse);
      expect(result.text, 'Câu này nói về hướng đối tượng.');
    });

    test('Đọc được backend tự viết trả {"text": ...}', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'text': 'Giải thích từ backend riêng.'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await AiService.explain(
        question: _sampleQuestion(),
        language: QuestionLanguage.vietnamese,
        client: client,
        endpoint: 'https://ai.test/explain',
      );

      expect(result.fromFallback, isFalse);
      expect(result.text, 'Giải thích từ backend riêng.');
    });

    test('Server lỗi 500 thì rơi về lời giải gốc', () async {
      final client = MockClient(
        (_) async => http.Response('{"error":"upstream_failed"}', 500),
      );
      final q = _sampleQuestion();

      final result = await AiService.explain(
        question: q,
        language: QuestionLanguage.vietnamese,
        client: client,
        endpoint: 'https://ai.test/explain',
      );

      expect(result.fromFallback, isTrue);
      expect(result.text, q.explanationVi);
    });

    test('Server mất mạng (ném lỗi) thì rơi về lời giải gốc', () async {
      final client = MockClient((_) async => throw const SocketException());
      final q = _sampleQuestion();

      final result = await AiService.explain(
        question: q,
        language: QuestionLanguage.english,
        client: client,
        endpoint: 'https://ai.test/explain',
      );

      expect(result.fromFallback, isTrue);
      expect(result.text, q.explanationEn);
    });
  });
}

/// Lỗi mạng giả, không phụ thuộc dart:io để test chạy được trên mọi nền tảng.
class SocketException implements Exception {
  const SocketException();
  @override
  String toString() => 'SocketException: mất mạng';
}
