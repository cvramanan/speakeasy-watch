import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import '../models/network_status.dart';
import '../providers/pipeline_provider.dart';
import '../services/connectivity_service.dart';
import '../widgets/watch_scaffold.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/ptt_button.dart';
import '../widgets/volume_slider.dart';
import '../widgets/mode_toggle.dart';
import 'history_screen.dart';

class IdleScreen extends ConsumerStatefulWidget {
  const IdleScreen({super.key});

  @override
  ConsumerState<IdleScreen> createState() => _IdleScreenState();
}

class _IdleScreenState extends ConsumerState<IdleScreen> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final recorder = AudioRecorder();
    final granted = await recorder.hasPermission();
    await recorder.dispose();
    if (mounted) setState(() => _hasPermission = granted);
  }

  @override
  Widget build(BuildContext context) {
    final network = ref.watch(connectivityServiceProvider);
    final pipeline = ref.read(pipelineProvider.notifier);
    final isOffline = network == NetworkStatus.offline; // connecting/poor are NOT offline
    final isDisabled = isOffline || !_hasPermission;

    return WatchScaffold(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🌐 SpeakEasy',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            const ModeToggle(),
            const SizedBox(height: 4),
            if (!_hasPermission)
              const Text(
                'Mic permission\nrequired',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.orangeAccent),
              )
            else if (isOffline)
              const Text(
                'No internet.\nEnable iPhone hotspot.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.redAccent),
              )
            else if (network == NetworkStatus.connecting)
              const Text(
                'Checking connection...',
                style: TextStyle(fontSize: 10, color: Colors.blueGrey),
              )
            else if (network == NetworkStatus.poor)
              const Text(
                '⚠️ Weak connection',
                style: TextStyle(fontSize: 10, color: Colors.amberAccent),
              )
            else
              const Text(
                'Tap to speak',
                style: TextStyle(fontSize: 10, color: Colors.white38),
              ),
            const SizedBox(height: 6),
            PttButton(
              isRecording: false,
              isDisabled: isDisabled,
              onTap: () => pipeline.startRecording(),
            ),
            const SizedBox(height: 6),
            const VolumeSlider(),
            const SizedBox(height: 4),
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -300) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                }
              },
              child: const ConnectivityIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
