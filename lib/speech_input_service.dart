/// Nhận dạng giọng nói cho ô nhập câu hỏi.
///
/// Tách interface khỏi plugin để widget test chạy được mà không cần micro
/// thật, cùng cách đã dùng cho [StudyImageService] ở camera.
///
/// Âm thanh do bộ nhận dạng của hệ điều hành xử lý. App không gửi tệp âm
/// thanh hay bản chép lời tới backend AI của nhóm: chữ nhận được chỉ nằm
/// trong ô nhập để người dùng sửa trước khi tìm câu.
library;

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Lỗi khi dùng micro, đủ chi tiết để chọn thông báo cho người dùng.
enum SpeechInputFailure { permissionDenied, noMatch, busy, unavailable, failed }

class SpeechInputException implements Exception {
  const SpeechInputException(this.failure);

  final SpeechInputFailure failure;

  @override
  String toString() => 'SpeechInputException(${failure.name})';
}

/// Nghe một lượt nói và trả chữ đã nhận.
abstract class SpeechInputService {
  /// Bắt đầu một lượt nghe.
  ///
  /// [onWords] nhận **toàn bộ** chữ của lượt hiện tại (kể cả kết quả tạm),
  /// không phải phần nối thêm. [onFailure] chỉ được gọi khi lỗi xảy ra sau
  /// khi đã bắt đầu nghe. [onDone] được gọi khi micro tự dừng (hết thời gian
  /// hoặc bộ nhận dạng kết thúc).
  Future<void> listen({
    required bool english,
    required void Function(String words, bool isFinal) onWords,
    required void Function(SpeechInputFailure failure) onFailure,
    required void Function() onDone,
  });

  /// Kết thúc lượt nghe, giữ kết quả cuối cùng.
  Future<void> stop();

  /// Hủy lượt nghe và giải phóng micro.
  Future<void> dispose();
}

/// Bản dùng plugin `speech_to_text` và bộ nhận dạng của Android.
class NativeSpeechInputService implements SpeechInputService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  void Function(SpeechInputFailure failure)? _onFailure;
  void Function()? _onDone;

  @override
  Future<void> listen({
    required bool english,
    required void Function(String words, bool isFinal) onWords,
    required void Function(SpeechInputFailure failure) onFailure,
    required void Function() onDone,
  }) async {
    _onFailure = onFailure;
    _onDone = onDone;
    if (!_initialized) {
      final ready = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
      if (!ready) {
        // Phân biệt bị từ chối quyền với máy không có bộ nhận dạng.
        final granted = await _speech.hasPermission;
        throw SpeechInputException(
          granted
              ? SpeechInputFailure.unavailable
              : SpeechInputFailure.permissionDenied,
        );
      }
      _initialized = true;
    }
    final localeId = await _localeId(english);
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) =>
          onWords(result.recognizedWords, result.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 60),
        localeId: localeId,
        // Lỗi vĩnh viễn tự hủy lượt nghe, tránh micro treo.
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (!_initialized) return;
    await _speech.stop();
  }

  @override
  Future<void> dispose() async {
    _onFailure = null;
    _onDone = null;
    if (!_initialized) return;
    await _speech.cancel();
  }

  /// Chọn ngôn ngữ nhận dạng theo ngôn ngữ giao diện; `null` để hệ thống quyết.
  Future<String?> _localeId(bool english) async {
    try {
      final locales = await _speech.locales();
      final prefix = english ? 'en' : 'vi';
      for (final locale in locales) {
        final id = locale.localeId.replaceAll('_', '-').toLowerCase();
        if (id.startsWith(prefix)) return locale.localeId;
      }
    } catch (error) {
      debugPrint('Speech locales error: $error');
    }
    return null;
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint(
      'Speech error: ${error.errorMsg} (permanent: ${error.permanent})',
    );
    _onFailure?.call(_mapError(error.errorMsg));
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') _onDone?.call();
  }

  static SpeechInputFailure _mapError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('permission')) return SpeechInputFailure.permissionDenied;
    if (msg.contains('no_match')) return SpeechInputFailure.noMatch;
    if (msg.contains('busy')) return SpeechInputFailure.busy;
    if (msg.contains('not_available') || msg.contains('missing')) {
      return SpeechInputFailure.unavailable;
    }
    return SpeechInputFailure.failed;
  }
}
