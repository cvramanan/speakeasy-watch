# 🛠️ SpeakEasy Watch — Detailed Execution Plan
### Phase-by-phase engineering execution guide for OnePlus Watch 2R (Wear OS)

> This document is the engineering execution companion to `PRODUCT_WORKFLOW.md`.
> It tells you exactly **what to build, in what order, how to verify it, and when to move on**.

---

## How to Use This Document

- Work top to bottom within each phase
- Each task has: **Goal → Steps → Acceptance Test**
- Mark tasks `[x]` as you complete them
- Do not start Phase 2 until Phase 1 exit criteria are fully met on real hardware
- All commands assume: project root = `speakeasy_watch/`, device = `192.168.1.14:34359`

---

## Environment Setup (Do Once)

### Prerequisites Checklist

- [ ] Flutter 3.x installed and on PATH
- [ ] `flutter doctor` passes with Android toolchain ✓
- [ ] `adb connect 192.168.1.14:34359` → `connected`
- [ ] `flutter devices` shows OnePlus Watch 2R
- [ ] OpenAI API key obtained and stored safely (NOT in code)
- [ ] iPhone hotspot configured and accessible from watch

### Project Bootstrap

```bash
# Verify watch is reachable
adb connect 192.168.1.14:34359
flutter devices

# Run existing app to confirm baseline works
flutter run -d 192.168.1.14:34359

# Create local secrets file (gitignored)
echo "OPENAI_API_KEY=sk-your-key-here" >> local.properties
echo "local.properties" >> .gitignore
```

### Folder Structure to Build Towards

```
speakeasy_watch/
├── lib/
│   ├── main.dart
│   ├── app.dart                        # MaterialApp root
│   ├── models/
│   │   ├── network_status.dart         # NetworkStatus enum (connecting/connected/poor/offline)
│   │   ├── translation_mode.dart       # TranslationMode enum (enToJp/jpToEn) ✅
│   │   └── translation_result.dart     # TranslationResult (outputText + mode fields) ✅
│   ├── services/
│   │   ├── connectivity_service.dart   # HTTP probe-based connectivity notifier ✅
│   │   ├── audio_service.dart          # Record + file management (3-min max, no silence det.) ✅
│   │   ├── whisper_service.dart        # OpenAI Whisper API client (language param) ✅
│   │   ├── translation_service.dart    # OpenAI GPT-4o-mini client (per-mode prompts) ✅
│   │   ├── tts_service.dart            # flutter_tts wrapper (mode-aware locale, completion CB) ✅
│   │   ├── volume_service.dart         # STREAM_MUSIC volume via MethodChannel ✅
│   │   ├── history_service.dart        # sqflite v2 with mode column ✅
│   │   └── api_client.dart             # Shared Dio instance with retry interceptor
│   ├── providers/
│   │   ├── pipeline_provider.dart      # PipelineNotifier (takes Ref, reads mode) ✅
│   │   ├── mode_provider.dart          # translationModeProvider StateProvider ✅
│   │   ├── volume_provider.dart        # VolumeNotifier Riverpod provider ✅
│   │   └── history_provider.dart
│   ├── screens/
│   │   ├── idle_screen.dart            # ModeToggle + PttButton + VolumeSlider ✅
│   │   ├── recording_screen.dart       # MM:SS timer, mode.listenLabel, ⚠️ at 2:45 ✅
│   │   ├── processing_screen.dart
│   │   ├── result_screen.dart          # mode-aware header (🔊 EN→JP / JP→EN) ✅
│   │   ├── error_screen.dart
│   │   └── history_screen.dart
│   ├── widgets/
│   │   ├── watch_scaffold.dart         # ClipOval + SingleChildScrollView wrapper ✅
│   │   ├── connectivity_indicator.dart # 4-state indicator incl. connecting ✅
│   │   ├── ptt_button.dart             # Tap-to-start / tap-to-stop button
│   │   ├── mode_toggle.dart            # EN→JP / JP→EN chip toggle ✅
│   │   ├── volume_slider.dart          # 0–100% slider with ⚠️ < 50% warning ✅
│   │   └── waveform_bar.dart
│   └── utils/
│       └── api_keys.dart               # BuildConfig reader
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/.../MainActivity.kt  # FLAG_KEEP_SCREEN_ON + volume MethodChannel ✅
│       └── res/
│           ├── drawable/ic_launcher_foreground.xml  ✅
│           ├── drawable/ic_launcher_background.xml  ✅
│           └── mipmap-anydpi-v26/ic_launcher*.xml   ✅
├── assets/
│   └── images/logo.svg                 # 512×512 branding SVG ✅
├── test/
│   ├── services/
│   └── widgets/
├── PRODUCT_WORKFLOW.md
├── EXECUTION.md                        # this file
└── local.properties                    # gitignored
```

---

## Phase 1: MVP ✅ COMPLETE

**Goal:** Working end-to-end translation on the physical watch, within latency target, with connectivity handling.

**Duration:** 3–4 weeks (completed)
**Branch:** `feature/phase-1-mvp`

---

### Sprint 1 (Week 1): Project Foundation + Connectivity

---

#### TASK 1.1 — Project Cleanup & Dependency Setup

**Goal:** Replace the current hello_wear app with the SpeakEasy foundation.

**Steps:**

1. Update `pubspec.yaml` with full dependency list:

```yaml
dependencies:
  flutter:
    sdk: flutter
  record: ^5.1.0
  audioplayers: ^6.1.0
  dio: ^5.4.0
  connectivity_plus: ^6.0.0
  internet_connection_checker_plus: ^2.0.0
  flutter_riverpod: ^2.5.0
  shared_preferences: ^2.2.0
  sqflite: ^2.3.0
  wear: ^1.0.0
  wakelock_plus: ^1.2.0
```

2. Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

3. Add `android:uses-feature` for watch:

```xml
<uses-feature android:name="android.hardware.type.watch"/>
```

4. Run `flutter pub get` and verify no errors.

5. Wrap `main.dart` with `ProviderScope` (Riverpod requirement):

```dart
void main() {
  runApp(const ProviderScope(child: SpeakEasyApp()));
}
```

**Acceptance Test:**
- `flutter pub get` exits with no errors
- `flutter run -d 192.168.1.14:34359` deploys and shows blank black screen
- No compile errors

---

#### TASK 1.2 — WatchScaffold (Round Screen Wrapper)

**Goal:** All screens must be safe for a round 454×454 display.

**Steps:**

1. Create `lib/widgets/watch_scaffold.dart`:

```dart
import 'package:flutter/material.dart';

class WatchScaffold extends StatelessWidget {
  final Widget child;
  const WatchScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ClipOval(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

2. Use `WatchScaffold` as the wrapper for every screen going forward.

**Acceptance Test:**
- Deploy to watch; content is fully visible and not clipped by round bezel
- Test with text in all 4 corners — all readable

---

#### TASK 1.3 — NetworkStatus Model

**Goal:** Define the shared enum used across the entire app.

**Steps:**

1. Create `lib/models/network_status.dart`:

```dart
enum NetworkStatus { connected, poor, offline }

extension NetworkStatusX on NetworkStatus {
  bool get canMakeApiCalls =>
    this == NetworkStatus.connected || this == NetworkStatus.poor;

  String get userMessage => switch (this) {
    NetworkStatus.connected => 'Connected',
    NetworkStatus.poor      => 'Weak connection',
    NetworkStatus.offline   => 'No internet. Enable iPhone hotspot.',
  };
}
```

**Acceptance Test:**
- `canMakeApiCalls` returns `true` for connected and poor, `false` for offline
- Unit test covers all 3 enum values

---

#### TASK 1.4 — ConnectivityService ✅ DONE (implementation differs from template below)

> **Note:** `internet_connection_checker_plus` was replaced with a direct HTTP probe to `https://www.google.com/generate_204` (4s timeout, 3 retries, 800ms gap). A `NetworkStatus.connecting` state was added. Periodic recheck is 30s. Initial state is `connecting`, not `offline`. See `lib/services/connectivity_service.dart` for actual code.

**Goal:** Real-time network state monitoring with debounce to prevent false offline flashes (e.g. when watch re-associates to hotspot).

**Steps:**

1. Create `lib/services/connectivity_service.dart`:

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../models/network_status.dart';

final connectivityServiceProvider =
    StateNotifierProvider<ConnectivityNotifier, NetworkStatus>(
  (ref) => ConnectivityNotifier(),
);

class ConnectivityNotifier extends StateNotifier<NetworkStatus> {
  ConnectivityNotifier() : super(NetworkStatus.offline) {
    _init();
  }

  final _connectivity = Connectivity();
  final _checker = InternetConnectionCheckerPlus();
  StreamSubscription? _sub;
  Timer? _debounce;

  void _init() {
    _sub = _connectivity.onConnectivityChanged.listen((_) {
      // Debounce 1.5s to avoid false offline flashes during hotspot re-association
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1500), _evaluate);
    });
    _evaluate(); // immediate check on startup
  }

  Future<void> _evaluate() async {
    final result = await _connectivity.checkConnectivity();
    if (result == ConnectivityResult.none) {
      state = NetworkStatus.offline;
      return;
    }

    final hasInternet = await _checker.hasConnection;
    if (!hasInternet) {
      state = NetworkStatus.offline;
      return;
    }

    final latencyMs = await _pingLatency();
    state = latencyMs > 1500 ? NetworkStatus.poor : NetworkStatus.connected;
  }

  Future<int> _pingLatency() async {
    final sw = Stopwatch()..start();
    try {
      await _checker.hasConnection;
      sw.stop();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return 9999;
    }
  }

  Future<void> recheck() async => _evaluate();

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
```

**Acceptance Test:**
- Enable hotspot → state becomes `connected` within 3s
- Disable hotspot → state becomes `offline` within 3s (after debounce)
- Throttle connection → state becomes `poor`
- Re-enable hotspot → state recovers to `connected` automatically, no user action

---

#### TASK 1.5 — ConnectivityIndicator Widget

**Goal:** Persistent small indicator shown at bottom of every screen.

**Steps:**

1. Create `lib/widgets/connectivity_indicator.dart`:

```dart
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
    NetworkStatus.connected => Icons.wifi,
    NetworkStatus.poor      => Icons.wifi_2_bar,
    NetworkStatus.offline   => Icons.wifi_off,
  };

  Color _color(NetworkStatus s) => switch (s) {
    NetworkStatus.connected => Colors.greenAccent,
    NetworkStatus.poor      => Colors.amberAccent,
    NetworkStatus.offline   => Colors.redAccent,
  };
}
```

**Acceptance Test:**
- Indicator visible on idle screen
- Color and icon change correctly when hotspot is toggled off/on while app is open
- Text fits within watch screen without overflow

---

### Sprint 2 (Week 2): Audio Pipeline

---

#### TASK 2.1 — AudioService ✅ DONE (implementation differs from template below)

> **Note:** Silence detection watchdog was removed. Max duration changed from 10s → 3 minutes. The `startRecording()` signature now accepts `onMaxDuration` callback instead of running a silence watchdog. File size guard: files < 4096 bytes are rejected. See `lib/services/audio_service.dart`.

**Goal:** Capture PCM audio from the watch microphone and save to a temp WAV file ready for Whisper upload.

**Steps:**

1. Create `lib/services/audio_service.dart`:

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  final _recorder = AudioRecorder();
  String? _outputPath;

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _outputPath = '${dir.path}/speakeasy_input.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: _outputPath!,
    );
  }

  Future<File?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file;
  }

  Future<bool> get isRecording => _recorder.isRecording();

  void dispose() => _recorder.dispose();
}
```

2. Add `path_provider: ^2.1.0` to `pubspec.yaml`.

3. Implement **silence detection** — auto-stop if amplitude stays below threshold for 1.5s:

```dart
// In AudioService, call this after startRecording()
Future<void> startSilenceWatchdog({
  required VoidCallback onSilenceDetected,
  double rmsThreshold = 0.01,
  Duration silenceDuration = const Duration(milliseconds: 1500),
  Duration maxDuration = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(maxDuration);
  DateTime? silenceStart;

  while (await _recorder.isRecording()) {
    if (DateTime.now().isAfter(deadline)) {
      onSilenceDetected();
      return;
    }

    final amp = await _recorder.getAmplitude();
    final rms = amp.current;

    if (rms < rmsThreshold) {
      silenceStart ??= DateTime.now();
      if (DateTime.now().difference(silenceStart!) >= silenceDuration) {
        onSilenceDetected();
        return;
      }
    } else {
      silenceStart = null;
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }
}
```

**Acceptance Test:**
- Record 3 seconds of speech → WAV file exists, size > 10KB
- Record silence for 2s → watchdog fires and stops recording
- File is mono, 16kHz (verify with `ffprobe` or check file header)
- File is deleted after use (cleanup tested explicitly)

---

#### TASK 2.2 — Push-to-Talk Button Widget

**Goal:** A large, watch-optimized button that triggers recording on long-press and stops on release.

**Steps:**

1. Create `lib/widgets/ptt_button.dart`:

```dart
import 'package:flutter/material.dart';

class PttButton extends StatelessWidget {
  final bool isRecording;
  final bool isDisabled;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  const PttButton({
    super.key,
    required this.isRecording,
    required this.isDisabled,
    required this.onPressStart,
    required this.onPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: isDisabled ? null : (_) => onPressStart(),
      onLongPressEnd: isDisabled ? null : (_) => onPressEnd(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDisabled
              ? Colors.grey.shade800
              : isRecording
                  ? Colors.red.shade700
                  : Colors.blueGrey.shade700,
        ),
        child: Icon(
          isDisabled ? Icons.mic_off : isRecording ? Icons.stop : Icons.mic,
          color: isDisabled ? Colors.grey : Colors.white,
          size: 36,
        ),
      ),
    );
  }
}
```

**Acceptance Test:**
- Button is gray and non-responsive when `isDisabled = true`
- Button turns red immediately on long press
- `onPressStart` fires when long press begins
- `onPressEnd` fires when finger lifts
- Tap (not long press) does NOT trigger recording

---

### Sprint 3 (Week 2–3): API Integration

---

#### TASK 3.1 — API Key Setup

**Goal:** Read OpenAI API key from `local.properties` at build time. Never in source code.

**Steps:**

1. In `android/app/build.gradle.kts`, read local.properties:

```kotlin
import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}

android {
    defaultConfig {
        buildConfigField(
            "String",
            "OPENAI_API_KEY",
            "\"${localProperties.getProperty("OPENAI_API_KEY", "")}\""
        )
    }
    buildFeatures { buildConfig = true }
}
```

2. Create `lib/utils/api_keys.dart`:

```dart
import 'package:flutter/services.dart';

class ApiKeys {
  static const _channel = MethodChannel('com.example.speakeasy/config');

  static Future<String> get openAiKey async {
    // Read from BuildConfig via platform channel
    return await _channel.invokeMethod('getOpenAiKey');
  }
}
```

3. Alternatively (simpler for MVP): pass key via `--dart-define`:

```bash
flutter run -d 192.168.1.14:34359 \
  --dart-define=OPENAI_API_KEY=sk-your-key-here
```

```dart
// lib/utils/api_keys.dart
class ApiKeys {
  static const openAiKey =
    String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
}
```

**Acceptance Test:**
- `grep -r "sk-" lib/` returns no results
- `grep -r "sk-" android/` returns no results
- App can read the key at runtime and make a successful API call

---

#### TASK 3.2 — Dio API Client (Base + Retry)

**Goal:** Single shared Dio instance with auth header and retry interceptor for all API calls.

**Steps:**

1. Create `lib/services/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import '../utils/api_keys.dart';

Dio buildApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.openai.com/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer ${ApiKeys.openAiKey}',
      },
    ),
  );

  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      retries: 3,
      retryDelays: const [
        Duration(milliseconds: 500),
        Duration(seconds: 1),
        Duration(seconds: 2),
      ],
      retryEvaluator: (error, attempt) =>
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          (error.response?.statusCode ?? 0) == 503,
    ),
  );

  return dio;
}
```

2. Add `dio_smart_retry: ^6.0.0` to `pubspec.yaml` for `RetryInterceptor`.

**Acceptance Test:**
- Mock server returns 503 → client retries 3 times
- Mock server returns 200 on 3rd try → response returned successfully
- Timeout after 10s receive → throws `DioExceptionType.receiveTimeout`

---

#### TASK 3.3 — WhisperService ✅ DONE (implementation differs from template below)

> **Note:** `transcribe()` now accepts a `language` parameter (`'en'` or `'ja'`) driven by `TranslationMode`. Short transcript check removed (empty string is the only guard). See `lib/services/whisper_service.dart`.

**Goal:** Upload a WAV file to OpenAI Whisper and return the transcript.

**Steps:**

1. Create `lib/services/whisper_service.dart`:

```dart
import 'dart:io';
import 'package:dio/dio.dart';

class WhisperService {
  final Dio _dio;
  WhisperService(this._dio);

  Future<String> transcribe(File audioFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioFile.path,
        filename: 'audio.wav',
      ),
      'model': 'whisper-1',
      'language': 'en',
    });

    final response = await _dio.post(
      '/audio/transcriptions',
      data: formData,
    );

    final transcript = (response.data['text'] as String?)?.trim() ?? '';

    if (transcript.isEmpty || transcript.split(' ').length < 2) {
      throw Exception('Empty or too-short transcript: "$transcript"');
    }

    return transcript;
  }
}
```

**Acceptance Test:**
- Upload a 3s WAV recording of "How much does this cost?" → transcript matches
- Upload silent WAV → throws exception (empty transcript)
- Mock server timeout → Dio retry fires 3 times
- Latency logged: target < 1200ms on WiFi

---

#### TASK 3.4 — TranslationService ✅ DONE (implementation differs from template below)

> **Note:** Model changed to `gpt-4o-mini`. `translate()` now accepts `TranslationMode`; separate system prompts per direction. JP→EN direction does NOT validate for Japanese characters. See `lib/services/translation_service.dart`.

**Goal:** Send transcript to GPT-4o-mini and receive natural translation (EN→JP or JP→EN).

**Steps:**

1. Create `lib/services/translation_service.dart`:

```dart
import 'package:dio/dio.dart';

class TranslationService {
  final Dio _dio;
  TranslationService(this._dio);

  static const _systemPrompt =
      'You are a professional Japanese translator. '
      'Translate the English text to natural, polite Japanese (丁寧語). '
      'Reply with ONLY the Japanese translation. No explanations, no romanization, no English.';

  Future<String> translate(String englishText) async {
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': englishText},
        ],
        'max_tokens': 150,
        'temperature': 0.2,
      },
    );

    final japanese =
        response.data['choices'][0]['message']['content'] as String? ?? '';

    // Validate output contains at least one Japanese character
    final hasJapanese = RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]').hasMatch(japanese);
    if (!hasJapanese) {
      throw Exception('Translation did not return Japanese text: "$japanese"');
    }

    return japanese.trim();
  }
}
```

**Acceptance Test:**
- "How much does this cost?" → returns string containing Japanese characters
- Input with very long text (100+ words) → still completes within 3s
- If API returns English-only → exception thrown
- Latency logged: target < 1200ms on WiFi

---

#### TASK 3.5 — TtsService ✅ DONE (implementation differs from template below)

> **Note:** Uses `flutter_tts` (not `audioplayers`). Speech rate reduced to 0.5 (from 0.9). TTS engine volume always set to 1.0; actual loudness controlled by `VolumeService.setMaxVolume()` (native STREAM_MUSIC). `speakAtVolume()` accepts `TranslationMode` and sets locale accordingly: `en-US` for JP→EN, `ja-JP` for EN→JP. TTS completion handler added to release wakelock after playback ends. See `lib/services/tts_service.dart`.

**Goal:** Pre-initialized Android TTS that speaks translation output on demand.

**Steps:**

1. Create `lib/services/tts_service.dart`:

```dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.9);   // slightly slower = more natural
    await _tts.setVolume(1.0);       // max volume
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> speak(String japaneseText) async {
    if (!_initialized) await init();
    await _tts.stop();               // stop any current speech
    await _tts.speak(japaneseText);
  }

  Future<void> stop() async => _tts.stop();

  void dispose() => _tts.stop();
}
```

2. Add `flutter_tts: ^4.0.2` to `pubspec.yaml`.

3. Call `ttsService.init()` at app startup (in `main.dart`), not on first use.

**Acceptance Test:**
- `speak("これはいくらですか？")` → audible Japanese speech from watch speaker
- Volume is at maximum
- Second call while first is playing → first stops, second starts immediately
- TTS initialized at startup → no delay on first translation

---

### Sprint 4 (Week 3): Translation Pipeline Orchestration

---

#### TASK 4.1 — TranslationProvider / PipelineProvider (Full Pipeline) ✅ DONE (implementation differs from template below)

> **Note:** Provider is now `pipelineProvider` in `lib/providers/pipeline_provider.dart`. `PipelineNotifier` takes `Ref` to read `translationModeProvider` at recording time. `TranslationResult` has `outputText` + `mode` fields; `japanese` kept as backward-compat getter. Wakelock enabled on `startRecording()`, released after TTS completion callback or on error/reset. Pipeline reads mode from provider, passes it to whisper + translator + TTS.

**Goal:** Riverpod provider that orchestrates the full record → transcribe → translate → speak pipeline with state management.

**Steps:**

1. Create `lib/models/translation_result.dart`:

```dart
class TranslationResult {
  final String transcript;
  final String japanese;
  final int totalLatencyMs;

  const TranslationResult({
    required this.transcript,
    required this.japanese,
    required this.totalLatencyMs,
  });
}
```

2. Create `lib/providers/translation_provider.dart`:

```dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation_result.dart';
import '../services/audio_service.dart';
import '../services/whisper_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';
import '../services/api_client.dart';

enum PipelineState { idle, recording, processing, result, error }

class PipelineNotifier extends StateNotifier<PipelineState> {
  PipelineNotifier() : super(PipelineState.idle);

  final _audio = AudioService();
  final _whisper = WhisperService(buildApiClient());
  final _translator = TranslationService(buildApiClient());
  final _tts = TtsService();

  TranslationResult? lastResult;
  String? lastError;

  Future<void> startRecording() async {
    state = PipelineState.recording;
    await _audio.startRecording();
  }

  Future<void> stopAndProcess() async {
    state = PipelineState.processing;
    final stopwatch = Stopwatch()..start();

    try {
      final file = await _audio.stopRecording();
      if (file == null) throw Exception('No audio recorded');

      final transcript = await _whisper.transcribe(file);
      final japanese = await _translator.translate(transcript);

      stopwatch.stop();
      lastResult = TranslationResult(
        transcript: transcript,
        japanese: japanese,
        totalLatencyMs: stopwatch.elapsedMilliseconds,
      );

      // Cleanup temp file
      await file.delete();

      state = PipelineState.result;
      await _tts.speak(japanese);
    } catch (e) {
      stopwatch.stop();
      lastError = e.toString();
      state = PipelineState.error;
    }
  }

  Future<void> replayAudio() async {
    if (lastResult != null) await _tts.speak(lastResult!.japanese);
  }

  void reset() => state = PipelineState.idle;
}

final pipelineProvider =
    StateNotifierProvider<PipelineNotifier, PipelineState>(
  (ref) => PipelineNotifier(),
);
```

**Acceptance Test:**
- Speak a phrase → pipeline transitions: idle → recording → processing → result
- `lastResult.totalLatencyMs` < 3000 on WiFi
- On network failure → state transitions to `error`, `lastError` is set
- Temp audio file is deleted after each translation

---

### Sprint 5 (Week 3–4): Screens & UI

---

#### TASK 5.1 — Idle Screen ✅ DONE

Implemented at `lib/screens/idle_screen.dart`. Actual layout (top to bottom):
- App title "🌐 SpeakEasy"
- `ModeToggle` (EN→JP / JP→EN chip pair) ← new
- Status text: mic permission error / offline message / "Checking connection..." / "⚠️ Weak connection" / "Tap to speak"
- `PttButton` (tap to start)
- `VolumeSlider` (0–100%) ← new
- `ConnectivityIndicator` (swipe-up opens HistoryScreen)

Mic is disabled only when `NetworkStatus.offline` or mic permission not granted. `connecting` and `poor` states do NOT disable the button.

---

#### TASK 5.2 — Recording Screen ✅ DONE

Implemented at `lib/screens/recording_screen.dart`. Actual layout:
- Pulsing red dot + "🎙️ REC  MM:SS" timer (MM:SS format)
- ⚠️ "Max 3 min" warning shown at 2:45 (`_seconds >= 165`)
- `PttButton` (tap to stop)
- `mode.listenLabel` text ("Listening for English..." or "Listening for Japanese...")

WakelockPlus enabled on `startRecording()` (in PipelineNotifier, not in this screen).

---

#### TASK 5.3 — Processing Screen

```dart
// lib/screens/processing_screen.dart
// Shows: "Translating..." + animated 3-dot indicator + transcript preview
// Behavior: auto-navigates to result or error
```

Key implementation notes:
- Animated dots use `AnimationController` with `repeat()`
- Show transcript text as soon as Whisper returns (before GPT completes)

---

#### TASK 5.4 — Result Screen ✅ DONE

Implemented at `lib/screens/result_screen.dart`. Actual layout:
- Mode header: "🔊 EN→JP" or "🔊 JP→EN" (driven by `result.mode`)
- Output text (large, white, max 4 lines)
- Original transcript (small, gray, 1 line)
- [Again] [Back] action buttons
- Total latency in ms (small, bottom)
- Double-tap anywhere → `replayAudio()`

No Romaji display (Phase 2). No favorites star (Phase 2).

---

#### TASK 5.5 — Error Screen

```dart
// lib/screens/error_screen.dart
// Shows: error icon + short message + retry button
// Behavior: retry re-runs stopAndProcess() from last audio
```

Key implementation notes:
- Map error types to friendly messages:
  - timeout → "Taking too long. Check connection."
  - empty transcript → "No speech detected. Try again."
  - API error → "Translation failed. Tap to retry."
- Retry button re-triggers `pipelineProvider.notifier.stopAndProcess()`

---

#### TASK 5.6 — Offline Screen (inline state, not separate screen)

Do NOT navigate to a separate screen for offline state. Instead:
- Idle screen shows offline message inline when `NetworkStatus.offline`
- Mic button is disabled
- `ConnectivityIndicator` shows red
- Message: "No internet.\nEnable iPhone hotspot."

---

#### TASK 5.7 — App Router

Wire all screens via `PipelineState` watch in `app.dart`:

```dart
// lib/app.dart
class SpeakEasyApp extends ConsumerWidget {
  const SpeakEasyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = ref.watch(pipelineProvider);

    return MaterialApp(
      title: 'SpeakEasy',
      theme: ThemeData.dark(),
      home: switch (pipeline) {
        PipelineState.idle      => const IdleScreen(),
        PipelineState.recording => const RecordingScreen(),
        PipelineState.processing => const ProcessingScreen(),
        PipelineState.result    => const ResultScreen(),
        PipelineState.error     => const ErrorScreen(),
      },
    );
  }
}
```

**Acceptance Test for all screens:**
- All screens visible on 454×454 round display without clipping
- Navigation between all states works correctly via `PipelineState`
- `ConnectivityIndicator` visible on idle, recording, and result screens
- All tap targets ≥ 48×48dp

---

### Phase 1 Exit Criteria Checklist ✅ PASSED

```
PIPELINE
[x] "How much does this cost?" → Japanese on screen + audio ≤ 3s on WiFi
[x] "Where is the train station?" → correct Japanese translation
[x] 20 consecutive translations without crash
[x] Temp audio file deleted after each translation

BIDIRECTIONAL
[x] EN→JP mode: English speech → Japanese output + ja-JP TTS
[x] JP→EN mode: Japanese speech → English output + en-US TTS
[x] ModeToggle switches mode; persists for session

CONNECTIVITY
[x] Disable iPhone hotspot → red indicator + mic disabled within 3s
[x] Re-enable hotspot → green indicator + mic re-enabled automatically
[x] Speak while poor connection → warning shown, retry attempted
[x] API timeout → error screen shown, retry button works
[x] App shows "Checking connection..." while probing (connecting state)

VOLUME
[x] Volume slider on idle screen adjusts STREAM_MUSIC
[x] ⚠️ warning shown when slider < 50%
[x] Startup auto-boosts to 1.0 if persisted value < 0.8

RECORDING
[x] Timer shows MM:SS format
[x] ⚠️ "Max 3 min" warning appears at 2:45
[x] Recording stops automatically at 3:00

SECURITY
[x] grep -r "sk-" lib/ → no results
[x] local.properties in .gitignore
[x] flutter run requires --dart-define key to work

UI
[x] All screens render without clipping on round display (SingleChildScrollView)
[x] PTT button clearly distinguishable: idle / recording / disabled states
[x] ConnectivityIndicator visible on all main screens
[x] FLAG_KEEP_SCREEN_ON prevents screen dimming mid-playback
```

---

---

## Phase 1 Addendum — Completed Beyond Original Scope

These tasks were completed during Phase 1 iteration (all deployed and verified on device):

| Task | Description | Files |
|---|---|---|
| A1 | **Bidirectional translation** — `TranslationMode` enum, `translationModeProvider`, `ModeToggle` widget, per-mode Whisper lang + system prompts + TTS locale | `models/translation_mode.dart`, `providers/mode_provider.dart`, `widgets/mode_toggle.dart` |
| A2 | **Volume control** — `VolumeService` (STREAM_MUSIC MethodChannel), `VolumeNotifier` Riverpod, `VolumeSlider` widget on idle screen, startup auto-boost to 1.0 if stored < 0.8, ⚠️ warning < 50% | `services/volume_service.dart`, `providers/volume_provider.dart`, `widgets/volume_slider.dart`, `MainActivity.kt` |
| A3 | **Connectivity overhaul** — replaced `internet_connection_checker_plus` with direct HTTP probe; added `NetworkStatus.connecting` state; periodic recheck 30s | `services/connectivity_service.dart`, `models/network_status.dart` |
| A4 | **Recording stability** — silence detection removed; max duration 3 min; MM:SS timer; ⚠️ warning at 2:45; file size guard (< 4096 bytes rejected) | `services/audio_service.dart`, `screens/recording_screen.dart` |
| A5 | **TTS completion handler** — wakelock released via `setCompletionHandler` callback after playback ends; speech rate 0.5; TTS engine volume 1.0 + `VolumeService.setMaxVolume()` before every speak call | `services/tts_service.dart`, `providers/pipeline_provider.dart` |
| A6 | **Wakelock lifecycle** — `WakelockPlus.enable()` on startRecording; disable after TTS completes OR on error OR on reset | `providers/pipeline_provider.dart` |
| A7 | **FLAG_KEEP_SCREEN_ON** — set in `MainActivity.onCreate()` to prevent Wear OS from dimming mid-playback | `android/.../MainActivity.kt` |
| A8 | **SingleChildScrollView** on all screens + padding reduced 22px → 16px | all screen files |
| A9 | **HistoryService v2** — sqflite DB bumped to version 2; `mode` column added with migration | `services/history_service.dart` |
| A10 | **TranslationResult updated** — `outputText` + `mode` fields; `japanese` kept as backward-compat getter | `models/translation_result.dart` |
| A11 | **gpt-4o → gpt-4o-mini** — battery + cost optimisation, minimal accuracy impact | `services/translation_service.dart` |
| A12 | **App branding** — SVG logo `assets/images/logo.svg`; Android adaptive icon with `#1565C0` background | `assets/images/logo.svg`, `res/drawable/`, `res/mipmap-anydpi-v26/` |

---

## Phase 2: Usability Improvements

**Goal:** Make the app feel trustworthy and polished for real users.

**Duration:** 2–3 weeks
**Branch:** `feature/phase-2-polish`
**Prerequisite:** All Phase 1 exit criteria pass on device ✅

---

### P2 Task List

| # | Task | Description | Est. | Status |
|---|---|---|---|---|
| 2.1 | Haptic feedback | `WearOS HapticFeedback` on record start/stop, success, error | 1 day | ⬜ |
| 2.2 | Romaji conversion | Convert Japanese text to Romaji using `japanese_romaji` or custom map | 2 days | ⬜ |
| 2.3 | Translation history | sqflite v2 table built; swipe-up HistoryScreen UI | 2 days | ✅ DB done, UI partial |
| 2.4 | Volume slider | ✅ Already shipped in Phase 1 (VolumeService + VolumeSlider widget) | — | ✅ DONE |
| 2.5 | API key via Remote Config | Move from `--dart-define` to Firebase Remote Config | 1 day | ⬜ |
| 2.6 | GPT prompt tuning | Test 20 travel phrases, refine system prompt for accuracy | 1 day | ⬜ |
| 2.7 | Wrist-raise wake | Integrate `wear` package `AmbientMode` → ready state on raise | 1 day | ⬜ |
| 2.8 | LTE latency testing | Measure all 10 standard phrases on LTE (not WiFi); must be ≤ 3s | 1 day | ⬜ |

### Phase 2 Exit Criteria
- [ ] 5 real users complete simulated travel scenario without instruction
- [ ] Latency ≤ 3s on LTE for 9/10 standard phrases
- [ ] Haptics fire correctly for all state transitions
- [ ] History screen shows last 10 translations correctly
- [ ] Zero crashes in 100 consecutive translations

---

## Phase 3: Advanced Features

**Duration:** 4–5 weeks
**Branch:** `feature/phase-3-advanced`
**Prerequisite:** Phase 2 exit criteria pass

---

### P3 Task List

| # | Task | Description | Est. | Status |
|---|---|---|---|---|
| 3.1 | Offline phrase pack | 200 travel phrases in SQLite; fuzzy matcher | 5 days | ⬜ |
| 3.2 | ~~Bidirectional mode~~ | ✅ Already shipped in Phase 1 | — | ✅ DONE |
| 3.3 | Favorites | Star button saves phrase; favorites screen | 2 days | ⬜ |
| 3.4 | Register toggle | Casual / Polite / Keigo; persisted in SharedPreferences | 2 days | ⬜ |
| 3.5 | Ambient mode | Screen dims between translations; wake on wrist raise | 2 days | ⬜ |
| 3.6 | Offline indicator enhancement | Show offline phrase count available | 1 day | ⬜ |

### Phase 3 Exit Criteria
- [ ] Offline mode covers ≥ 80% of 25 standard travel scenarios
- [ ] Favorites saves and retrieves correctly after app restart

---

## Phase 4: Production

**Duration:** 2 weeks
**Branch:** `feature/phase-4-production`
**Prerequisite:** Phase 3 exit criteria pass

---

### P4 Task List

| # | Task | Description | Est. |
|---|---|---|---|
| 4.1 | Firebase Analytics | Integrate, add all custom events from PRODUCT_WORKFLOW.md §9 | 2 days |
| 4.2 | Crashlytics | Setup, verify crash reports appear in console | 1 day |
| 4.3 | Battery profiling | 30-min session < 5% drain; fix any leaks found | 2 days |
| 4.4 | ProGuard / R8 | Enable minification; verify no runtime crashes | 1 day |
| 4.5 | Privacy policy | Write + host; link in Play Store listing | 1 day |
| 4.6 | Play Store prep | Signed APK, store listing, screenshots, description | 2 days |
| 4.7 | CI/CD | GitHub Actions: build + sign APK on push to main | 1 day |

### Phase 4 Exit Criteria
- [ ] Wear OS pre-launch report: 0 crashes on test matrix
- [ ] p95 latency ≤ 3s visible in Firebase dashboard
- [ ] Battery drain < 5% per 10 minutes active use
- [ ] App published to Google Play (internal testing track)

---

## Daily Dev Workflow

```bash
# 1. Connect watch
adb connect 192.168.1.14:34359

# 2. Run with hot reload
flutter run -d 192.168.1.14:34359 \
  --dart-define=OPENAI_API_KEY=sk-your-key

# 3. Hot reload (press 'r' in terminal)
# 4. Hot restart (press 'R' in terminal)
# 5. View logs
adb -s 192.168.1.14:34359 logcat | grep flutter

# 6. Run tests
flutter test

# 7. Build release APK
flutter build apk --release \
  --dart-define=OPENAI_API_KEY=sk-your-key
```

---

## Latency Measurement Script

Run this after Phase 1 to baseline performance. Add timestamps at each pipeline step:

```dart
// In PipelineNotifier.stopAndProcess()
final t0 = DateTime.now().millisecondsSinceEpoch;
final file = await _audio.stopRecording();

final t1 = DateTime.now().millisecondsSinceEpoch;
final transcript = await _whisper.transcribe(file!);
debugPrint('LATENCY whisper: ${DateTime.now().millisecondsSinceEpoch - t1}ms');

final t2 = DateTime.now().millisecondsSinceEpoch;
final japanese = await _translator.translate(transcript);
debugPrint('LATENCY gpt: ${DateTime.now().millisecondsSinceEpoch - t2}ms');

final t3 = DateTime.now().millisecondsSinceEpoch;
await _tts.speak(japanese);
debugPrint('LATENCY tts: ${DateTime.now().millisecondsSinceEpoch - t3}ms');
debugPrint('LATENCY total: ${DateTime.now().millisecondsSinceEpoch - t0}ms');
```

**Target benchmarks:**

| Step | WiFi Target | LTE Target |
|---|---|---|
| Whisper STT | < 1000ms | < 1400ms |
| GPT-4o-mini translation | < 700ms | < 1000ms |
| TTS synthesis | < 300ms | < 300ms |
| **Total** | **< 2000ms** | **< 2700ms** |

---

## Troubleshooting Reference

| Problem | Likely Cause | Fix |
|---|---|---|
| `adb connect` fails | Watch screen off or ADB toggled off | Wake watch, re-enable ADB in Developer Options |
| `flutter run` can't find device | ADB disconnected | Re-run `adb connect 192.168.1.14:34359` |
| Whisper returns empty string | Audio file too small / silent | Check mic permission; verify file size > 5KB |
| GPT returns English text | System prompt ignored | Strengthen prompt; add "Japanese only" assertion |
| TTS speaks wrong language | TTS locale not set | Ensure `setLanguage('ja-JP')` called before `speak()` |
| Connectivity always shows offline | HTTP probe can't reach `generate_204` | Check watch can reach internet; verify hotspot is active; probe has 4s timeout + 3 retries |
| App crashes on round screen | Widget overflow outside `ClipOval` | Wrap offending widget in `Flexible` or reduce padding |
| Build fails after pubspec change | Gradle cache stale | Run `flutter clean && flutter pub get` |
| iOS app crashes immediately on launch | `AVAudioSession.setActive(true)` conflicts with `flutter_tts` | Removed from AppDelegate — only set category, let TTS manage activation |
| iOS `flutter run` times out (exit 144) | Dart VM socket blocked over WiFi | Use USB cable or build release mode |
| iOS app crashes after USB disconnect | Debug build requires VM service connection | Install via `flutter run --release` — no debugger dependency |
| iOS app stuck with termination assertions | Previous crash left OS holding process state | Wait 30s or restart iPhone; then reinstall |
| iOS `flutter install` fails mid-install | App was running/crashed during install | Kill old process first, then reinstall |

---

## iOS Deployment Reference

### Build & Install (release — standalone, no USB needed)

```bash
flutter run --release -d 00008150-001604AE0C01401C \
  --dart-define=OPENAI_API_KEY=$(grep OPENAI_API_KEY local.properties | cut -d= -f2-)
# Press 'd' to detach (app stays on phone) or 'q' to quit
```

### Trust certificate on iPhone (first install only)

Settings → General → VPN & Device Management → Developer App → Trust

### Certificate expiry

| Account type | Certificate valid for |
|---|---|
| Free Apple ID | 7 days — reinstall weekly |
| Paid Apple Developer ($99/yr) | 1 year |

### iOS device IDs

| Device | Flutter UDID | CoreDevice UUID |
|---|---|---|
| Venkatrc (iPhone 17) | `00008150-001604AE0C01401C` | `528DFF3A-B024-5656-B371-68A8E4B88003` |

### Verified real-device latency (iPhone 17, iOS 26.1)

| Run | Whisper | GPT-4o-mini | Total |
|---|---|---|---|
| 1 | 1578ms | 2694ms | 4339ms |
| 2 | 1317ms | 1984ms | 3321ms |

---

*Last updated: 2026-03-25. Phase 1 complete. Bidirectional translation, volume control, connectivity overhaul, battery optimisations, and branding all shipped. Entering Phase 2.*
