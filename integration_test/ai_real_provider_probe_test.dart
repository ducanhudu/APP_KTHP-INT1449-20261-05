import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_quiz_app/ai_service.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Probe **nhà cung cấp AI thật** qua proxy của nhóm.
///
/// Khác với `ai_proxy_native_test.dart` (dùng upstream giả), test này cần server
/// chạy với `GEMINI_API_KEY` thật và **không** đặt `AI_UPSTREAM`:
///
/// ```powershell
/// $env:GEMINI_API_KEY = Read-Host 'Gemini API key'
/// $env:AI_ACCESS_CODE = 'ma-nhom'
/// $env:PORT = '8787'
/// node server/server.js
/// ```
///
/// Rồi chạy trên emulator (10.0.2.2 là loopback của host):
///
/// ```powershell
/// flutter test integration_test/ai_real_provider_probe_test.dart -d emulator-5554 `
///   --dart-define=AI_PROBE_ACCESS_CODE=ma-nhom --no-uninstall
/// ```
///
/// Kết quả dùng làm bằng chứng rubric "AI giải thích bằng API thật". Mã truy cập
/// chỉ truyền qua `--dart-define` của lệnh test, không nằm trong APK phát hành.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const endpoint = String.fromEnvironment(
    'AI_PROBE_ENDPOINT',
    defaultValue: 'http://10.0.2.2:8787/explain',
  );
  const accessCode = String.fromEnvironment('AI_PROBE_ACCESS_CODE');

  testWidgets('API thật trả lời qua proxy của nhóm', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('AI real provider probe'))),
    );
    final question = decodeQuestions(
      await rootBundle.loadString('assets/flutter_quiz_300.json'),
    ).first;

    AiService.accessCode = accessCode;
    final startedAt = DateTime.now();
    final result = await AiService.explain(
      question: question,
      language: QuestionLanguage.vietnamese,
      endpoint: endpoint,
    );
    final elapsed = DateTime.now().difference(startedAt);

    debugPrint(
      'AI_REAL endpoint=$endpoint codeSet=${accessCode.isNotEmpty} '
      'ms=${elapsed.inMilliseconds} fromFallback=${result.fromFallback}',
    );
    debugPrint('AI_REAL_TEXT ${result.text.replaceAll('\n', ' ').trim()}');

    expect(
      result.fromFallback,
      isFalse,
      reason:
          'Proxy/AI thật không trả nội dung: kiểm tra khoá, mã truy cập, quota',
    );
    expect(result.text.trim(), isNot(question.explanationVi.trim()));
  });
}
