import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

enum StudyScanMode { text, qr }

class StudyImageReading {
  const StudyImageReading({this.text = '', this.codes = const []});
  final String text;
  final List<String> codes;
}

abstract class StudyImageService {
  Future<String?> pick(ImageSource source);
  Future<String?> recoverLostImage();
  Future<StudyImageReading> read(String path, StudyScanMode mode);
}

class NativeStudyImageService implements StudyImageService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pick(ImageSource source) async => (await _picker.pickImage(
    source: source,
    maxWidth: 2400,
    maxHeight: 2400,
    imageQuality: 90,
    requestFullMetadata: false,
  ))?.path;

  @override
  Future<String?> recoverLostImage() async {
    if (!Platform.isAndroid) return null;
    final response = await _picker.retrieveLostData();
    if (response.exception != null) throw response.exception!;
    final files = response.files;
    return files == null || files.isEmpty ? null : files.first.path;
  }

  @override
  Future<StudyImageReading> read(String path, StudyScanMode mode) async {
    if (await File(path).length() > 12 * 1024 * 1024) {
      throw const FormatException('image_too_large');
    }
    final input = InputImage.fromFilePath(path);
    if (mode == StudyScanMode.qr) {
      final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
      try {
        final barcodes = await scanner.processImage(input);
        return StudyImageReading(
          codes: [
            for (final barcode in barcodes)
              if (barcode.rawValue != null) barcode.rawValue!,
          ],
        );
      } finally {
        await scanner.close();
      }
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return StudyImageReading(
        text: (await recognizer.processImage(input)).text,
      );
    } finally {
      await recognizer.close();
    }
  }
}
