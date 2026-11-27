import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/camera_study_page.dart';
import 'package:flutter_quiz_app/card_storage.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/speech_input_service.dart';
import 'package:flutter_quiz_app/study_image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class FakeStudyImages implements StudyImageService {
  @override
  Future<String?> pick(ImageSource source) async => null;
  @override
  Future<String?> recoverLostImage() async => null;
  @override
  Future<StudyImageReading> read(String path, StudyScanMode mode) async =>
      const StudyImageReading();
}

class FakeSpeech implements SpeechInputService {
  void Function(String words, bool isFinal)? onWords;
  void Function(SpeechInputFailure failure)? onFailure;
  void Function()? onDone;
  Object? listenError;
  bool? english;
  int listens = 0;
  int stops = 0;
  bool disposed = false;

  /// Giữ `listen()` chưa trả về để mô phỏng plugin khởi động chậm.
  Completer<void>? listenGate;

  @override
  Future<void> listen({
    required bool english,
    required void Function(String words, bool isFinal) onWords,
    required void Function(SpeechInputFailure failure) onFailure,
    required void Function() onDone,
  }) async {
    this.english = english;
    this.onWords = onWords;
    this.onFailure = onFailure;
    this.onDone = onDone;
    listens++;
    if (listenGate != null) await listenGate!.future;
    if (listenError != null) throw listenError!;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  final bank = decodeQuestions(
    File('assets/flutter_quiz_300.json').readAsStringSync(),
  );

  Future<void> open(
    WidgetTester tester,
    FakeSpeech speech, {
    QuestionLanguage language = QuestionLanguage.vietnamese,
    double height = 1200,
  }) async {
    tester.view.physicalSize = Size(440, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CameraStudyPage(
          imageService: FakeStudyImages(),
          speechService: speech,
          questions: bank,
          storage: MemoryCardStorage(),
          language: language,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapMic(WidgetTester tester) async {
    final button = find.text('Nhập bằng giọng nói');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// Nút "Tìm trong 300 câu" là `FilledButton.icon` (subclass private), nên
  /// tìm theo text rồi lấy tổ tiên là `ButtonStyleButton`.
  ButtonStyleButton searchButtonOf(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(
        find
            .ancestor(
              of: find.text('Tìm trong 300 câu'),
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            )
            .first,
      );

  testWidgets('Speech fills the text field without searching on its own', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await open(tester, speech);
    await tapMic(tester);
    expect(speech.listens, 1);

    speech.onWords!('Trong Dart từ khóa nào yêu cầu giá trị của biến', false);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, contains('Trong Dart'));
    // Chưa bấm tìm thì chưa có kết quả nào: đúng yêu cầu "sửa trước khi dùng".
    expect(find.text('Câu hỏi gợi ý'), findsNothing);

    speech.onWords!('Trong Dart từ khóa nào yêu cầu giá trị của biến', true);
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã chép lời'), findsOneWidget);

    final search = find.text('Tìm trong 300 câu');
    await tester.ensureVisible(search);
    await tester.tap(search);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('K01-001'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('K01-001'), findsOneWidget);
  });

  testWidgets('Denied microphone keeps manual typing and search usable', (
    tester,
  ) async {
    final speech = FakeSpeech()
      ..listenError = const SpeechInputException(
        SpeechInputFailure.permissionDenied,
      );
    await open(tester, speech);
    await tapMic(tester);
    expect(find.textContaining('Chưa được phép dùng micro'), findsOneWidget);

    await tester.enterText(find.byType(TextField), bank.first.vi);
    await tester.pumpAndSettle();
    final search = find.text('Tìm trong 300 câu');
    await tester.ensureVisible(search);
    await tester.tap(search);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('K01-001'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('K01-001'), findsOneWidget);
  });

  testWidgets('Stopping recording keeps the transcribed words', (tester) async {
    final speech = FakeSpeech();
    await open(tester, speech);
    await tapMic(tester);
    speech.onWords!('từ khóa const', false);
    await tester.pumpAndSettle();

    final stop = find.text('Dừng ghi âm');
    await tester.ensureVisible(stop);
    await tester.tap(stop);
    await tester.pumpAndSettle();

    expect(speech.stops, 1);
    expect(find.text('Nhập bằng giọng nói'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'từ khóa const',
    );
  });

  testWidgets('Leaving the page releases the microphone', (tester) async {
    final speech = FakeSpeech();
    await open(tester, speech);
    await tapMic(tester);
    expect(speech.disposed, isFalse);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    expect(speech.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lần nghe thứ hai sau khi tìm là câu mới, không nối câu cũ', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await open(tester, speech, height: 2600);

    // Lần 1: nghe rồi tìm.
    await tapMic(tester);
    speech.onWords!(bank.first.vi, true);
    await tester.pumpAndSettle();
    final search = find.text('Tìm trong 300 câu');
    await tester.ensureVisible(search);
    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(find.textContaining('K01-001'), findsOneWidget);

    // Lần 2: nói câu khác. Chữ phải được THAY THẾ, kết quả cũ vẫn hiện trong
    // lúc đang nói để trang không bị reset giữa chừng.
    await tapMic(tester);
    speech.onWords!('Một câu hoàn toàn mới', false);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Một câu hoàn toàn mới');
    expect(find.textContaining('K01-001'), findsOneWidget);

    // Chốt phiên: nội dung khác lần tìm trước nên kết quả cũ được bỏ.
    speech.onWords!('Một câu hoàn toàn mới', true);
    await tester.pumpAndSettle();
    expect(find.textContaining('K01-001'), findsNothing);
  });

  testWidgets('Đang nghe thì không tìm được, dừng nghe thì tìm lại được', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await open(tester, speech);
    await tester.enterText(find.byType(TextField), 'FutureBuilder');
    await tester.pumpAndSettle();

    await tapMic(tester);
    expect(find.text('Dừng ghi âm'), findsOneWidget);
    expect(searchButtonOf(tester).onPressed, isNull);

    await tester.tap(find.text('Dừng ghi âm'));
    await tester.pumpAndSettle();
    expect(searchButtonOf(tester).onPressed, isNotNull);
  });

  testWidgets('Bấm mic hai lần liên tiếp không tạo phiên chồng', (
    tester,
  ) async {
    final speech = FakeSpeech()..listenGate = Completer<void>();
    await open(tester, speech);

    await tester.tap(find.text('Nhập bằng giọng nói'));
    await tester.pump();
    expect(find.text('Đang bật micro…'), findsOneWidget);

    // Bấm lần 2 khi listen() chưa trả về: phải bị bỏ qua, không gọi stop().
    await tester.tap(find.byIcon(Icons.stop_circle_outlined));
    await tester.pump();
    expect(speech.stops, 0);

    speech.listenGate!.complete();
    await tester.pumpAndSettle();
    expect(speech.listens, 1);
    expect(find.text('Dừng ghi âm'), findsOneWidget);

    // Kết thúc phiên để huỷ watchdog 10 giây.
    await tester.tap(find.text('Dừng ghi âm'));
    await tester.pumpAndSettle();
    expect(speech.stops, 1);
  });

  testWidgets('English interface asks the recognizer for English', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await open(tester, speech, language: QuestionLanguage.english);
    final button = find.text('Speak the question');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(speech.english, isTrue);

    // Đóng trang để huỷ watchdog 10 giây của phiên đang nghe.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
  });
}
