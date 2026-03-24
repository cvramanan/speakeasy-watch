import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/network_status.dart';

final connectivityServiceProvider =
    StateNotifierProvider<ConnectivityNotifier, NetworkStatus>(
  (ref) => ConnectivityNotifier(),
);

class ConnectivityNotifier extends StateNotifier<NetworkStatus> {
  ConnectivityNotifier() : super(NetworkStatus.connecting) {
    _init();
  }

  // Google's dedicated connectivity probe — returns 204 instantly
  static const _probeUrl = 'https://www.google.com/generate_204';
  static const _timeoutSec = 4;
  static const _maxRetries = 3;
  static const _retryDelay = Duration(milliseconds: 800);
  static const _periodicInterval = Duration(seconds: 30);

  final _connectivity = Connectivity();
  StreamSubscription? _sub;
  Timer? _debounce;
  Timer? _periodicTimer;

  void _init() {
    _sub = _connectivity.onConnectivityChanged.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1500), _evaluate);
    });
    _periodicTimer = Timer.periodic(_periodicInterval, (_) => _evaluate());
    _evaluate();
  }

  Future<void> _evaluate() async {
    final result = await _connectivity.checkConnectivity();

    // No network interface at all → immediately offline
    if (result.contains(ConnectivityResult.none) && result.length == 1) {
      if (mounted) state = NetworkStatus.offline;
      return;
    }

    // Show connecting while probing (only if currently showing offline to avoid flicker)
    if (mounted && state == NetworkStatus.offline) {
      state = NetworkStatus.connecting;
    }

    // Retry up to _maxRetries times before declaring offline
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      final latencyMs = await _httpProbe();
      if (latencyMs >= 0) {
        if (mounted) {
          state = latencyMs > 2000 ? NetworkStatus.poor : NetworkStatus.connected;
        }
        return;
      }
      if (attempt < _maxRetries - 1) {
        await Future.delayed(_retryDelay);
      }
    }

    if (mounted) state = NetworkStatus.offline;
  }

  /// Returns latency in ms on success, -1 on failure/timeout.
  Future<int> _httpProbe() async {
    final sw = Stopwatch()..start();
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: _timeoutSec)
        ..badCertificateCallback = (_, __, ___) => true;
      final req = await client
          .getUrl(Uri.parse(_probeUrl))
          .timeout(const Duration(seconds: _timeoutSec));
      final resp = await req
          .close()
          .timeout(const Duration(seconds: _timeoutSec));
      await resp.drain<void>();
      sw.stop();
      // 204 = success; accept any non-error response
      return resp.statusCode < 400 ? sw.elapsedMilliseconds : -1;
    } catch (_) {
      return -1;
    } finally {
      client?.close(force: true);
    }
  }

  Future<void> recheck() async => _evaluate();

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}
