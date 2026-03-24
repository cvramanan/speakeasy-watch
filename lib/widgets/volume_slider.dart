import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/volume_provider.dart';

class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(volumeProvider);
    final notifier = ref.read(volumeProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              volume == 0
                  ? Icons.volume_off
                  : volume < 0.5
                      ? Icons.volume_down
                      : Icons.volume_up,
              size: 12,
              color: Colors.white60,
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 90,
              height: 20,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2.5,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.grey.shade800,
                  thumbColor: Colors.white,
                  overlayColor: Colors.blueAccent.withOpacity(0.2),
                ),
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) => notifier.set(v),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${(volume * 100).round()}%',
              style: const TextStyle(fontSize: 9, color: Colors.white38),
            ),
          ],
        ),
        // Warning when volume is too low
        if (volume < 0.5)
          const Text(
            '⚠️ Increase volume',
            style: TextStyle(fontSize: 8, color: Colors.amber),
          ),
        // Max volume quick tap
        if (volume < 1.0)
          GestureDetector(
            onTap: () => notifier.maxOut(),
            child: const Text(
              '▲ Max',
              style: TextStyle(fontSize: 8, color: Colors.blueAccent),
            ),
          ),
      ],
    );
  }
}
