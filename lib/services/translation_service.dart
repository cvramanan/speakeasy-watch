import 'package:dio/dio.dart';
import '../models/translation_mode.dart';

class TranslationService {
  final Dio _dio;
  TranslationService(this._dio);

  static const _enToJpPrompt =
      'You are a professional Japanese translator. '
      'Translate the English text to natural, polite Japanese (丁寧語). '
      'Reply with ONLY the Japanese translation. No explanations, no romanization, no English.';

  static const _jpToEnPrompt =
      'You are a professional English translator. '
      'Translate the Japanese text to natural, clear English. '
      'Reply with ONLY the English translation. No explanations, no Japanese.';

  Future<String> translate(String text, TranslationMode mode) async {
    final systemPrompt =
        mode == TranslationMode.enToJp ? _enToJpPrompt : _jpToEnPrompt;

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': text},
        ],
        'max_tokens': 150,
        'temperature': 0.2,
      },
    );

    final output =
        response.data['choices'][0]['message']['content'] as String? ?? '';

    if (output.trim().isEmpty) {
      throw Exception('translation:empty');
    }

    if (mode == TranslationMode.enToJp) {
      final hasJapanese =
          RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]').hasMatch(output);
      if (!hasJapanese) throw Exception('translation:not_japanese');
    }

    return output.trim();
  }
}
