enum TranslationMode { enToJp, jpToEn }

extension TranslationModeX on TranslationMode {
  String get label => switch (this) {
        TranslationMode.enToJp => 'EN → JP',
        TranslationMode.jpToEn => 'JP → EN',
      };

  String get whisperLang => switch (this) {
        TranslationMode.enToJp => 'en',
        TranslationMode.jpToEn => 'ja',
      };

  String get listenLabel => switch (this) {
        TranslationMode.enToJp => 'Listening for English...',
        TranslationMode.jpToEn => 'Listening for Japanese...',
      };

  String get dbValue => switch (this) {
        TranslationMode.enToJp => 'en_to_jp',
        TranslationMode.jpToEn => 'jp_to_en',
      };

  static TranslationMode fromDb(String? value) =>
      value == 'jp_to_en' ? TranslationMode.jpToEn : TranslationMode.enToJp;
}
