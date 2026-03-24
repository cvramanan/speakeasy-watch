import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation_mode.dart';

final translationModeProvider = StateProvider<TranslationMode>(
  (ref) => TranslationMode.enToJp,
);
