import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolumeService {
  VolumeService._();
  static final instance = VolumeService._();

  static const _channel = MethodChannel('com.example.speakeasy_watch/volume');
  static const _prefKey = 'tts_volume';

  // Cached value so UI can read without async
  double _current = 1.0;
  double get current => _current;

  /// Load persisted volume on startup and apply to system.
  /// If the stored value is below 0.8, override it to max for best audibility.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(_prefKey) ?? 1.0;
    if (stored < 0.8) {
      // Stored volume is too low — force max so speech is always audible
      _current = 1.0;
      await prefs.setDouble(_prefKey, _current);
    } else {
      _current = stored;
    }
    await _applyToSystem(_current);
  }

  /// Set volume (0.0–1.0), persist it, and apply to system immediately
  Future<void> setVolume(double percent) async {
    _current = percent.clamp(0.0, 1.0);
    await _applyToSystem(_current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, _current);
  }

  /// Force system media stream to absolute maximum
  Future<void> setMaxVolume() async {
    _current = 1.0;
    try {
      await _channel.invokeMethod('setMaxVolume');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, _current);
  }

  /// Read current system volume as a 0.0–1.0 fraction
  Future<double> readSystemVolume() async {
    try {
      final v = await _channel.invokeMethod<double>('getVolume');
      _current = v ?? _current;
      return _current;
    } catch (_) {
      return _current;
    }
  }

  Future<void> _applyToSystem(double percent) async {
    try {
      await _channel.invokeMethod('setVolume', {'percent': percent});
    } on MissingPluginException {
      // Running on non-Android (e.g. tests) — skip silently
    } catch (_) {}
  }
}
