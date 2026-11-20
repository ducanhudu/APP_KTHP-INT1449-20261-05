/// TTS Service – Ngày 3
/// Bọc flutter_tts để phát giọng đọc, dừng và xử lý quyền bị từ chối.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { stopped, playing, error }

class TtsService {
  TtsService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  TtsState state = TtsState.stopped;
  bool permissionDenied = false;

  final _stateController = StreamController<TtsState>.broadcast();
  Stream<TtsState> get onStateChanged => _stateController.stream;

  void _init() {
    _tts.setStartHandler(() => _setState(TtsState.playing));
    _tts.setCompletionHandler(() => _setState(TtsState.stopped));
    _tts.setCancelHandler(() => _setState(TtsState.stopped));
    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      // Nếu lỗi liên quan quyền mic/audio → đánh dấu
      if (msg.toString().toLowerCase().contains('permission')) {
        permissionDenied = true;
      }
      _setState(TtsState.error);
    });
  }

  void _setState(TtsState s) {
    state = s;
    _stateController.add(s);
  }

  Future<void> speak(String text) async {
    if (permissionDenied) return;
    try {
      await _tts.stop();
      await _tts.setLanguage('vi-VN');
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _setState(TtsState.error);
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _setState(TtsState.stopped);
  }

  void dispose() {
    _tts.stop();
    _stateController.close();
  }
}
