import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/tts_service.dart';
import 'services/volume_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load persisted volume + set system stream to max
  await VolumeService.instance.init();
  // Pre-initialize TTS so first translation has no delay
  await TtsService.instance.init();
  runApp(const ProviderScope(child: SpeakEasyApp()));
}
