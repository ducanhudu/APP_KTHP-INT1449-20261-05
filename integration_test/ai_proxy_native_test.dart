import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_quiz_app/ai_service.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Kiểm tra **đường mạng thật** của tính năng AI trên Android, dùng proxy nội
/// bộ thay cho nhà cung cấp:
///
/// 1. Proxy + upstream stub trả lời → app dùng nội dung từ AI (không fallback).
/// 2. Sai mã truy cập → proxy trả 401 → app rơi về lời giải JSON.
/// 3. Không có server → app rơi về lời giải JSON thay vì treo.
///
/// Cần chạy trước trên máy host:
///   node server/stub-upstream.js
///   AI_UPSTREAM=http://127.0.0.1:9999/explain GEMINI_API_KEY=demo
///   AI_ACCESS_CODE=probe123 PORT=8787 node server/server.js
///
/// Chạy trên emulator (10.0.2.2 là host) hoặc máy thật có `adb reverse`:
/// `flutter test integration_test/ai_proxy_native_test.dart -d DEVICE_ID --no-uninstall`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const endpoint = 'http://10.0.2.2:8787/explain';

  Future<Question> firstQuestion() async {
    final bank = decodeQuestions(
      await rootBundle.loadString('assets/flutter_quiz_300.json'),
    );
    return bank.first;
  }

  Future<void> pumpHost(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: Text('AI proxy test'))),
  );

  testWidgets('Proxy trả lời thật thì app dùng nội dung AI', (tester) async {
    await pumpHost(tester);
    final question = await firstQuestion();
    AiService.accessCode = 'probe123';
    final result = await AiService.explain(
      question: question,
      language: QuestionLanguage.vietnamese,
      endpoint: endpoint,
    );
    debugPrint(
      'AI_OK fromFallback=${result.fromFallback} '
      'text=${result.text.replaceAll('\n', ' ')}',
    );
    expect(result.fromFallback, isFalse);
    expect(result.text, contains('[Stub AI]'));
  });

  testWidgets('Sai mã truy cập thì rơi về lời giải JSON', (tester) async {
    await pumpHost(tester);
    final question = await firstQuestion();
    AiService.accessCode = 'wrong-code';
    final result = await AiService.explain(
      question: question,
      language: QuestionLanguage.vietnamese,
      endpoint: endpoint,
    );
    debugPrint('AI_401 fromFallback=${result.fromFallback}');
    expect(result.fromFallback, isTrue);
    expect(result.text, question.explanationVi);
  });

  testWidgets('Không có server thì rơi về lời giải JSON', (tester) async {
    await pumpHost(tester);
    final question = await firstQuestion();
    AiService.accessCode = 'probe123';
    final result = await AiService.explain(
      question: question,
      language: QuestionLanguage.vietnamese,
      endpoint: 'http://10.0.2.2:9/explain',
    );
    debugPrint('AI_DOWN fromFallback=${result.fromFallback}');
    expect(result.fromFallback, isTrue);
    expect(result.text, question.explanationVi);
  });
}
