import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/speech_input_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Kiểm tra bộ nhận dạng giọng nói **thật** của Android.
///
/// Không thể "nói" bằng máy, nên test này chỉ chứng minh: quyền đã có, bộ nhận
/// dạng tồn tại và phiên nghe bắt đầu/kết thúc mà không chặn tính năng. Máy im
/// lặng thường trả `noMatch` hoặc hết thời gian — hai lỗi đó **không** tính là
/// hỏng. Độ chính xác nhận chữ tiếng Việt vẫn phải thử bằng micro thật.
///
/// Chạy trên thiết bị/emulator:
/// `flutter test integration_test/speech_native_test.dart -d DEVICE_ID --no-uninstall`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Native recognizer accepts a listening session', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Speech test'))),
    );

    final service = NativeSpeechInputService();
    final failures = <SpeechInputFailure>[];
    final words = <String>[];

    try {
      await service.listen(
        english: false,
        onWords: (text, isFinal) => words.add(text),
        onFailure: failures.add,
        onDone: () {},
      );
      // Máy không nói gì: chờ pauseFor (3 giây) rồi kết thúc phiên.
      await Future<void>.delayed(const Duration(seconds: 5));
      await service.stop();
    } finally {
      await service.dispose();
    }

    debugPrint('speech words=$words failures=${failures.map((f) => f.name)}');

    // Hai lỗi này mới là hỏng thật: bị từ chối quyền hoặc máy thiếu recognizer.
    final blocking = failures.where(
      (f) =>
          f == SpeechInputFailure.permissionDenied ||
          f == SpeechInputFailure.unavailable,
    );
    expect(
      blocking,
      isEmpty,
      reason:
          'recognizer không dùng được: ${blocking.map((f) => f.name).join(', ')}',
    );
  });
}
