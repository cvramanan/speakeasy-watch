import 'translation_mode.dart';

class TranslationResult {
  final String transcript;
  final String outputText;
  final TranslationMode mode;
  final int totalLatencyMs;
  final DateTime timestamp;

  TranslationResult({
    required this.transcript,
    required this.outputText,
    required this.mode,
    required this.totalLatencyMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Backward-compat accessor used by history (DB column is still named 'japanese')
  String get japanese => outputText;
}
