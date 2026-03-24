import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  final _recorder = AudioRecorder();
  String? _outputPath;
  Timer? _silenceTimer;
  Timer? _maxDurationTimer;

  Future<void> startRecording({
    VoidCallback? onMaxDuration,
  }) async {
    // Stop any lingering session before starting fresh
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();

    final dir = await getTemporaryDirectory();
    _outputPath = '${dir.path}/speakeasy_input.wav';

    // Delete stale file from previous session if it exists
    final stale = File(_outputPath!);
    if (await stale.exists()) await stale.delete();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.mic,
        ),
      ),
      path: _outputPath!,
    );

    // Auto-stop after 3 minutes max
    _maxDurationTimer = Timer(const Duration(minutes: 3), () {
      onMaxDuration?.call();
    });
  }

  Future<File?> stopRecording() async {
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    final path = await _recorder.stop();
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final size = await file.length();
    if (size < 4096) return null; // too small = no real audio
    return file;
  }

  Future<bool> get isRecording => _recorder.isRecording();

  void dispose() {
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    _recorder.dispose();
  }
}
