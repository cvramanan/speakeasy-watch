import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation_mode.dart';
import '../providers/pipeline_provider.dart';
import '../providers/mode_provider.dart';
import '../widgets/watch_scaffold.dart';
import '../widgets/ptt_button.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with SingleTickerProviderStateMixin {
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pipeline = ref.read(pipelineProvider.notifier);
    final mode = ref.watch(translationModeProvider);

    return WatchScaffold(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // REC indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Icon(
                    Icons.fiber_manual_record,
                    color: Colors.red
                        .withOpacity(0.4 + 0.6 * _pulseController.value),
                    size: 11,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '🎙️ REC  ${_formatTime(_seconds)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            if (_seconds >= 165)
              const Text(
                '⚠️ Max 3 min',
                style: TextStyle(fontSize: 9, color: Colors.amberAccent),
              ),
            const SizedBox(height: 10),
            // Stop button — tap to stop
            PttButton(
              isRecording: true,
              isDisabled: false,
              onTap: () => pipeline.stopAndProcess(),
            ),
            const SizedBox(height: 8),
            Text(
              mode.listenLabel,
              style: const TextStyle(fontSize: 9, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
