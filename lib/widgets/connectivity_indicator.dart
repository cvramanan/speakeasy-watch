import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/network_status.dart';
import '../services/connectivity_service.dart';

class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityServiceProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon(status), size: 10, color: _color(status)),
        const SizedBox(width: 3),
        Text(
          status.userMessage,
          style: TextStyle(fontSize: 9, color: _color(status)),
        ),
      ],
    );
  }

  IconData _icon(NetworkStatus s) => switch (s) {
    NetworkStatus.connecting => Icons.wifi_find,
    NetworkStatus.connected  => Icons.wifi,
    NetworkStatus.poor       => Icons.wifi_2_bar,
    NetworkStatus.offline    => Icons.wifi_off,
  };

  Color _color(NetworkStatus s) => switch (s) {
    NetworkStatus.connecting => Colors.blueGrey,
    NetworkStatus.connected  => Colors.greenAccent,
    NetworkStatus.poor       => Colors.amberAccent,
    NetworkStatus.offline    => Colors.redAccent,
  };
}
