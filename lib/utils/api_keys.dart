class ApiKeys {
  // Injected via --dart-define=OPENAI_API_KEY=... at build time
  // Falls back to BuildConfig value set in build.gradle.kts
  static const openAiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );
}
