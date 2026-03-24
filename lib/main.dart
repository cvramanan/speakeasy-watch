import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/tts_service.dart';
import 'services/volume_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load persisted volume (Android: also sets system stream to max)
  await VolumeService.instance.init();
  // Pre-initialize TTS — wrapped so a platform error never prevents the app launching
  try {
    await TtsService.instance.init();
  } catch (_) {
    // TTS will re-initialize lazily on first use
  }
  runApp(const ProviderScope(child: SpeakEasyApp()));
}
