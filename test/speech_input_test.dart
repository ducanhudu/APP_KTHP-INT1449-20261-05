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
  }) async {
    tester.view.physicalSize = const Size(440, 1200);
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
  });
}
