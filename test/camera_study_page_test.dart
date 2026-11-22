import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quiz_app/camera_study_page.dart';
import 'package:flutter_quiz_app/card_storage.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/study_image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class FakeStudyImages implements StudyImageService {
  String? path;
  Object? error;
  StudyImageReading reading = const StudyImageReading();
  Completer<String?>? pending;
  ImageSource? source;
  @override
  Future<String?> pick(ImageSource source) async {
    this.source = source;
    if (error != null) throw error!;
    return pending == null ? path : pending!.future;
  }

  @override
  Future<String?> recoverLostImage() async => null;
  @override
  Future<StudyImageReading> read(String path, StudyScanMode mode) async =>
      reading;
}

void main() {
  final bank = decodeQuestions(
    File('assets/flutter_quiz_300.json').readAsStringSync(),
  );
  Future<void> open(
    WidgetTester tester,
    FakeStudyImages images, {
    CardStorage? storage,
  }) async {
    tester.view.physicalSize = const Size(440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CameraStudyPage(
          imageService: images,
          questions: bank,
          storage: storage ?? MemoryCardStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Cancel camera preserves editable text and allows another capture',
    (tester) async {
      final images = FakeStudyImages();
      await open(tester, images);
      await tester.enterText(find.byType(TextField), 'FutureBuilder');
      await tester.tap(find.text('Chụp ảnh'));
      await tester.pumpAndSettle();
      expect(images.source, ImageSource.camera);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'FutureBuilder',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Denied capture shows a recovery message and manual search still works',
    (tester) async {
      final images = FakeStudyImages()
        ..error = PlatformException(code: 'camera_access_denied');
      await open(tester, images);
      await tester.tap(find.text('Chụp ảnh'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa được phép'), findsOneWidget);
      await tester.enterText(find.byType(TextField), bank.first.vi);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tìm trong 300 câu'));
      await tester.tap(find.text('Tìm trong 300 câu'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('K01-001'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('K01-001'), findsOneWidget);
    },
  );
  testWidgets(
    'Search result opens correct answer and saves the same card without duplicates',
    (tester) async {
      final storage = MemoryCardStorage();
      await open(tester, FakeStudyImages(), storage: storage);
      await tester.enterText(find.byType(TextField), bank.first.vi);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tìm trong 300 câu'));
      await tester.tap(find.text('Tìm trong 300 câu'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('K01-001'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('K01-001'));
      await tester.pumpAndSettle();
      expect(find.text('Đáp án đúng: C'), findsOneWidget);
      await tester.ensureVisible(find.text('Lưu thẻ ôn'));
      await tester.tap(find.text('Lưu thẻ ôn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu thẻ ôn'));
      await tester.pumpAndSettle();
      expect((await storage.loadCards()).map((c) => c.questionId), [1]);
      expect(find.text('Thẻ đã có trong bộ ôn.'), findsOneWidget);
    },
  );
  testWidgets(
    'Leaving camera during picker does not update a disposed widget',
    (tester) async {
      final images = FakeStudyImages()..pending = Completer<String?>();
      await open(tester, images);
      await tester.tap(find.text('Chụp ảnh'));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      images.pending!.complete('unused.png');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
