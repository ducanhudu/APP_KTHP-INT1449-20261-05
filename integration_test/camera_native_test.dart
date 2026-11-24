import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/question_search.dart';
import 'package:flutter_quiz_app/study_image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'camera_qr_fixtures.dart';

/// Real Android ML Kit, using synthetic images rather than mock recognition.
/// Use a test device. Run with `--no-uninstall` to retain the application/data:
/// `flutter test integration_test/camera_native_test.dart -d DEVICE_ID --no-uninstall`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final name in ['en', 'vi', 'qr', 'external']) {
    testWidgets('Native camera recognizer: $name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Camera recognition test')),
        ),
      );
      final dir = await Directory.systemTemp.createTemp('flutterlab-camera-');
      final file = File('${dir.path}/fixture.png');
      try {
        final bank = decodeQuestions(
          await rootBundle.loadString('assets/flutter_quiz_300.json'),
        );
        final qr = ['qr', 'external'].contains(name);
        if (qr) {
          await file.writeAsBytes(
            base64Decode(name == 'qr' ? validQr : externalQr),
          );
        } else {
          final q = bank.first;
          final text = name == 'en' ? q.en : q.vi;
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: 40,
                color: Colors.black,
                fontFamily: 'sans-serif',
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 1000);
          final height = painter.height.ceil() + 100;
          canvas.drawRect(
            Rect.fromLTWH(0, 0, 1100, height.toDouble()),
            Paint()..color = Colors.white,
          );
          painter.paint(canvas, const Offset(50, 50));
          final picture = recorder.endRecording();
          final image = await picture.toImage(1100, height);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
          picture.dispose();
          painter.dispose();
        }
        final reading = await NativeStudyImageService().read(
          file.path,
          qr ? StudyScanMode.qr : StudyScanMode.text,
        );
        if (name == 'qr') {
          expect(reading.codes, contains('flutterlab://question/81'));
          expect(questionFromStudyQr(bank, reading.codes.first)?.id, 81);
        } else if (name == 'external') {
          expect(reading.codes, isNotEmpty);
          expect(questionFromStudyQr(bank, reading.codes.first), isNull);
        } else {
          expect(reading.text.trim(), isNotEmpty);
          expect(searchStudyQuestions(bank, reading.text).first.question.id, 1);
        }
      } finally {
        if (await file.exists()) await file.delete();
        await dir.delete();
      }
    });
  }
}
