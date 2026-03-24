enum NetworkStatus { connecting, connected, poor, offline }

extension NetworkStatusX on NetworkStatus {
  bool get canMakeApiCalls =>
      this == NetworkStatus.connecting ||
      this == NetworkStatus.connected ||
      this == NetworkStatus.poor;

  String get userMessage => switch (this) {
    NetworkStatus.connecting => 'Connecting...',
    NetworkStatus.connected  => 'Connected',
    NetworkStatus.poor       => 'Weak signal',
    NetworkStatus.offline    => 'No internet',
  };

  String get detailedMessage => switch (this) {
    NetworkStatus.connecting => 'Checking connection...',
    NetworkStatus.connected  => 'Connected',
    NetworkStatus.poor       => 'Weak connection — retrying if needed',
    NetworkStatus.offline    => 'No internet.\nEnable iPhone hotspot.',
  };
}
