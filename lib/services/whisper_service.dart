import 'dart:io';
import 'package:dio/dio.dart';

class WhisperService {
  final Dio _dio;
  WhisperService(this._dio);

  Future<String> transcribe(File audioFile, {String language = 'en'}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioFile.path,
        filename: 'audio.wav',
      ),
      'model': 'whisper-1',
      'language': language,
    });

    final response = await _dio.post(
      '/audio/transcriptions',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final transcript = (response.data['text'] as String?)?.trim() ?? '';
    if (transcript.isEmpty) {
      throw Exception('whisper:empty');
    }
    return transcript;
  }
}
