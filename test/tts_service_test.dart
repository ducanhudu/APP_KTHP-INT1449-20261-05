import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return 1;
    });
  });
  tearDown(
    () =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
  );

  test('English and Vietnamese select the correct speech language', () async {
    final service = TtsService();
    await service.speak(
      'English explanation',
      language: QuestionLanguage.english,
    );
    expect(
      calls.firstWhere((c) => c.method == 'setLanguage').arguments,
      'en-US',
    );
    calls.clear();
    await service.speak('Lời giải', language: QuestionLanguage.vietnamese);
    expect(
      calls.firstWhere((c) => c.method == 'setLanguage').arguments,
      'vi-VN',
    );
    service.dispose();
  });

  test('Closing while stop is pending prevents speech from starting', () async {
    final pending = Completer<int>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return call.method == 'stop' ? pending.future : 1;
    });
    final service = TtsService();
    final speaking = service.speak('Must not play after closing');
    service.dispose();
    pending.complete(1);
    await speaking;
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
    // A late stop/completion must not add an event to a closed stream.
    await service.stop();
    service.dispose();
  });
}
