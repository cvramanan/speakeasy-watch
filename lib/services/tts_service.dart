import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/translation_mode.dart';
import 'volume_service.dart';

class TtsService {
  TtsService._();
  static final instance = TtsService._();

  final _tts = FlutterTts();
  bool _initialized = false;

  static const _speechRate = 0.5; // 50% speed — slow and clear for Japanese

  Future<void> init() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSharedInstance(true);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!_initialized) await init();
    await VolumeService.instance.setMaxVolume();
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(_speechRate);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speakAtVolume(
    String text,
    double volume, {
    TranslationMode mode = TranslationMode.enToJp,
    VoidCallback? onComplete,
  }) async {
    if (!_initialized) await init();
    await VolumeService.instance.setMaxVolume();
    await _tts.setVolume(1.0);

    if (mode == TranslationMode.jpToEn) {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
    } else {
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(_speechRate);
    }

    _tts.setCompletionHandler(() => onComplete?.call());

    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async => _tts.stop();

  void dispose() => _tts.stop();
}
