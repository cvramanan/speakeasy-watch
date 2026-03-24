import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/volume_service.dart';

class VolumeNotifier extends StateNotifier<double> {
  VolumeNotifier() : super(1.0) {
    _load();
  }

  Future<void> _load() async {
    final v = await VolumeService.instance.readSystemVolume();
    if (mounted) state = v;
  }

  Future<void> set(double value) async {
    state = value;
    await VolumeService.instance.setVolume(value);
  }

  Future<void> maxOut() async {
    state = 1.0;
    await VolumeService.instance.setMaxVolume();
  }
}

final volumeProvider =
    StateNotifierProvider<VolumeNotifier, double>(
  (ref) => VolumeNotifier(),
);
