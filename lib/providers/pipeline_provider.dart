import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/translation_result.dart';
import '../models/translation_mode.dart';
import '../services/audio_service.dart';
import '../services/whisper_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';
import '../services/volume_service.dart';
import '../services/history_service.dart';
import '../services/api_client.dart';
import 'mode_provider.dart';

enum PipelineState { idle, recording, processing, result, error }

class PipelineNotifier extends StateNotifier<PipelineState> {
  final Ref _ref;
  PipelineNotifier(this._ref) : super(PipelineState.idle);

  final _audio = AudioService();
  late final _whisper = WhisperService(buildApiClient());
  late final _translator = TranslationService(buildApiClient());
  final _tts = TtsService.instance;

  TranslationResult? lastResult;
  String? lastError;
  String? _transcript;

  String? get transcript => _transcript;

  Future<void> startRecording() async {
    if (state == PipelineState.recording) return;
    await WakelockPlus.enable();
    state = PipelineState.recording;
    await _audio.startRecording(
      onMaxDuration: () => stopAndProcess(),
    );
  }

  Future<void> stopAndProcess() async {
    if (state != PipelineState.recording) return;
    state = PipelineState.processing;

    final mode = _ref.read(translationModeProvider);
    final stopwatch = Stopwatch()..start();
    File? audioFile;

    try {
      audioFile = await _audio.stopRecording();
      if (audioFile == null) throw Exception('whisper:empty');

      _transcript = null;
      final t1 = DateTime.now().millisecondsSinceEpoch;
      _transcript = await _whisper.transcribe(
        audioFile,
        language: mode.whisperLang,
      );
      final whisperMs = DateTime.now().millisecondsSinceEpoch - t1;

      final t2 = DateTime.now().millisecondsSinceEpoch;
      final outputText = await _translator.translate(_transcript!, mode);
      final gptMs = DateTime.now().millisecondsSinceEpoch - t2;

      stopwatch.stop();
      lastResult = TranslationResult(
        transcript: _transcript!,
        outputText: outputText,
        mode: mode,
        totalLatencyMs: stopwatch.elapsedMilliseconds,
      );

      await HistoryService.instance.save(lastResult!);

      debugPrint(
        'LATENCY whisper=${whisperMs}ms gpt=${gptMs}ms total=${stopwatch.elapsedMilliseconds}ms',
      );

      state = PipelineState.result;
      await _tts.speakAtVolume(
        outputText,
        VolumeService.instance.current,
        mode: mode,
        onComplete: () => WakelockPlus.disable(), // release after playback ends
      );
    } catch (e) {
      stopwatch.stop();
      lastError = _mapError(e.toString());
      state = PipelineState.error;
      await WakelockPlus.disable();
    } finally {
      try {
        await audioFile?.delete();
      } catch (_) {}
    }
  }

  String _mapError(String raw) {
    if (raw.contains('whisper:empty')) return 'No speech detected.\nTry again.';
    if (raw.contains('translation:not_japanese')) {
      return 'Translation failed.\nTap to retry.';
    }
    if (raw.contains('SocketException') || raw.contains('connection')) {
      return 'Connection lost.\nCheck iPhone hotspot.';
    }
    if (raw.contains('timeout')) {
      return 'Request timed out.\nCheck your connection.';
    }
    return 'Something went wrong.\nTap to retry.';
  }

  Future<void> replayAudio() async {
    if (lastResult != null) {
      await _tts.speakAtVolume(
        lastResult!.outputText,
        VolumeService.instance.current,
        mode: lastResult!.mode,
      );
    }
  }

  void reset() {
    lastError = null;
    _transcript = null;
    state = PipelineState.idle;
    WakelockPlus.disable();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }
}

final pipelineProvider =
    StateNotifierProvider<PipelineNotifier, PipelineState>(
  (ref) => PipelineNotifier(ref),
);
