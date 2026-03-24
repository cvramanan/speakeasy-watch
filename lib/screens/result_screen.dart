import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation_mode.dart';
import '../providers/pipeline_provider.dart';
import '../widgets/watch_scaffold.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(pipelineProvider.notifier);
    final result = notifier.lastResult;

    return WatchScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: GestureDetector(
        onDoubleTap: () => notifier.replayAudio(),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volume_up, size: 11, color: Colors.blueAccent),
                  const SizedBox(width: 3),
                  Text(
                    result?.mode == TranslationMode.jpToEn
                        ? '🔊 JP → EN'
                        : '🔊 EN → JP',
                    style: const TextStyle(fontSize: 9, color: Colors.blueAccent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                result?.outputText ?? '',
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.3),
              ),
              const SizedBox(height: 4),
              if (result?.transcript != null)
                Text(
                  result!.transcript,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.replay,
                    label: 'Again',
                    onTap: () => notifier.replayAudio(),
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.arrow_back,
                    label: 'Back',
                    onTap: () => notifier.reset(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${result?.totalLatencyMs ?? 0}ms',
                style: TextStyle(fontSize: 8, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 3),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
