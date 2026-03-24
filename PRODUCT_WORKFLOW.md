# 🌐 SpeakEasy Watch — Product Workflow Document
### Real-Time English → Japanese Speech Translator for OnePlus Watch 2R (Wear OS)

> **v3** — Includes bidirectional translation (EN↔JP), volume control, updated connectivity probe, battery optimisations, wakelock lifecycle, and app branding.

---

## 1. 🧭 Product Vision

**Vision Statement:**
> Eliminate the language barrier between English and Japanese speakers — with a single press on their wrist.

**Problem:** Travelers in Japan face constant friction in real-world conversations — shops, restaurants, transit, hotels. Pulling out a phone, opening an app, and waiting for translation is slow and socially awkward.

**Solution:** A Wear OS app that captures English speech via push-to-talk, translates to Japanese, and plays back audio — all within 2–3 seconds, without touching a phone.

**Target Users:**
- English-speaking tourists in Japan
- Business travelers attending meetings/events
- Digital nomads living in Japan short-term

**Key Success Metrics:**

| Metric | Target |
|---|---|
| End-to-end latency | ≤ 3 seconds (mic release → audio out) |
| Translation accuracy | ≥ 92% BLEU on travel phrases |
| Push-to-talk success rate | ≥ 98% (mic triggered correctly) |
| Session crash rate | < 0.5% |
| Avg. session length | 3–8 translations per session |
| Battery consumption per session | < 5% per 10 minutes active use |

---

## 2. 👤 User Personas

### Persona 1 — The Tourist
- **Name:** Sarah, 31, marketing manager from London
- **Tech comfort:** Medium
- **Context:** 10-day trip to Tokyo, Kyoto, Osaka
- **Pain points:**
  - Fumbling with phone mid-conversation feels rude
  - Google Translate mic is unreliable in noisy environments
  - Can't maintain eye contact while translating
- **Expectations:**
  - One-button operation
  - Audio output loud enough in crowded spaces
  - Works without phone in hand

### Persona 2 — The Business Traveler
- **Name:** David, 44, sales director from New York
- **Tech comfort:** High
- **Context:** Quarterly visits to Japanese partners, client dinners
- **Pain points:**
  - Formal translation required (polite Japanese register)
  - Needs confidence the translation sounds natural
  - Cannot appear flustered in front of clients
- **Expectations:**
  - High translation quality (formal register)
  - Minimal latency — conversation flow must feel natural
  - Clean, professional app appearance

### Persona 3 — The Digital Nomad
- **Name:** Priya, 27, remote developer living in Fukuoka for 3 months
- **Tech comfort:** Very high
- **Context:** Daily life tasks — grocery, clinic, landlord communication
- **Pain points:**
  - Repetitive phrases need to be fast
  - Offline fallback when subway signal drops
  - Doesn't want to carry phone everywhere
- **Expectations:**
  - Phrase history / favorites
  - Offline mode for common phrases
  - Lightweight battery usage

---

## 3. 🧩 Core Features Breakdown

### Must-Have (MVP) — Implemented
- Push-to-talk button (tap to start / tap to stop)
- English or Japanese speech capture via watch microphone
- Speech-to-text via OpenAI Whisper API (language param driven by mode)
- **Bidirectional translation: EN→JP and JP→EN** (mode toggle on idle screen) ✅
- Translation output displayed on watch screen
- TTS audio playback via watch speaker (ja-JP for EN→JP, en-US for JP→EN) ✅
- **Connectivity monitoring with real-time status indicator** ✅
- **Mic button gated on network state** ✅
- **Retry logic for unstable network** ✅
- **Volume slider on idle screen with native AudioManager control** ✅
- **FLAG_KEEP_SCREEN_ON + scoped WakelockPlus** ✅

### Good-to-Have (Phase 2)
- Haptic feedback on recording start/stop
- Translation history (last 10 phrases, in-session) — DB built ✅, UI screen partially done
- Phonetic reading (Romaji) displayed below Kanji
- Retry button on failed translation
- Wrist-raise to wake + auto-ready state
- Silence detection (removed; replaced by manual stop + 3-min max)

### Future Enhancements (Phase 3+)
- Offline mode with 200 common travel phrases
- Favorites / saved phrases
- Formal vs casual register toggle
- Multi-language support (Korean, Mandarin, Thai)
- Custom wake word

---

## 4. 🗺️ Phased Roadmap

---

### Phase 1: MVP — Minimal Working Translator ✅ COMPLETE

**Goal:** Prove the core loop works end-to-end on real hardware within latency target.

**Features Included:**
- Tap-to-start / tap-to-stop mic button (max 3 min; ⚠️ warning at 2:45)
- Whisper STT → GPT-4o-mini translation → Android TTS audio
- Bidirectional mode: EN→JP and JP→EN via ModeToggle chips
- Simple 3-state UI: Idle / Recording / Result
- **Connectivity monitoring (mandatory — not optional)**
- **Mic disabled when offline; warning shown when poor; connecting state shown while probing**
- **Retry logic (3 attempts, exponential backoff)**
- **Volume slider with native STREAM_MUSIC control**
- **FLAG_KEEP_SCREEN_ON + scoped wakelock**
- Basic error screens

**Technical Tasks:**
- Set up Wear OS Flutter project
- Implement audio recording via `record` package (PCM/WAV, 16kHz mono)
- Build Whisper API client (Dio, multipart POST)
- Build GPT-4o translation client (system prompt: polite Japanese)
- Build TTS playback (Android `TextToSpeech`, ja-JP locale)
- Design 3 Compose screens: Idle, Recording, Result
- Wire push-to-talk with long-press gesture
- Coroutine/async pipeline: record → STT → translate → TTS
- **Implement ConnectivityService (Riverpod StateNotifier)**
- **ConnectivityIndicator widget on all screens**
- **Debounce offline state 1.5s to prevent false flashes**
- **Gate mic button on NetworkStatus**

**Exit Criteria:**
- English phrase spoken → Japanese text on screen + audio out ≤ 3s on WiFi
- No crashes during 20 consecutive translations
- App shows offline state correctly when iPhone hotspot is disabled
- Mic button non-functional when offline
- App recovers automatically when hotspot re-enabled
- 3 retries attempted before showing error screen
- Tested on OnePlus Watch 2R physical device

---

### Phase 2: Usability Improvements

**Goal:** Make the app feel polished and trustworthy for real-world use.

**Features Included:**
- Haptic feedback (record start/stop, success, error)
- Romaji display below Japanese text
- In-session translation history (swipe up)
- Retry button on error
- Volume adjustment
- Silence detection (RMS threshold, auto-stop)
- Network quality indicator refinements
- Proper API key management (BuildConfig / secrets)

**Technical Tasks:**
- Integrate Wear OS Haptics API
- Implement silence detection (RMS on audio buffer)
- Add Romaji conversion (`wanakana-kt` or equivalent)
- Build scrollable history list
- Move API keys to `local.properties` + BuildConfig injection
- Tune GPT-4o system prompt for formal Japanese (丁寧語)

**Exit Criteria:**
- 5 real users complete simulated travel scenario without instruction
- Latency ≤ 3s on LTE
- Zero API key exposure in version-controlled code

---

### Phase 3: Advanced Features

**Goal:** Add intelligence and convenience that makes it a daily companion.

**Features Included:**
- Offline phrase pack (200 travel phrases, pre-cached)
- Favorites (save up to 20 phrases)
- Register toggle (casual / formal / keigo)
- ~~Bidirectional mode~~ — **already shipped in Phase 1** ✅
- Wrist-raise wake + auto-record mode

**Technical Tasks:**
- Bundle offline phrase SQLite DB in assets
- Build fuzzy matcher for offline phrase lookup
- Design register selection UI (single-tap toggle)
- Implement AmbientMode lifecycle hooks

**Exit Criteria:**
- Offline mode covers ≥ 80% of common travel phrases
- Favorites saves and retrieves after app restart

---

### Phase 4: Production Scaling

**Goal:** Harden for Play Store release and real user traffic.

**Features Included:**
- Firebase Analytics integration
- Crashlytics crash reporting
- API key rotation support (remote config)
- Battery optimization audit
- Play Store listing + screenshots
- Privacy policy + data handling compliance
- Rate limiting + quota management

**Exit Criteria:**
- App passes Wear OS pre-launch report
- p95 latency ≤ 3s tracked in Firebase
- Published to Google Play (internal track first)

---

## 5. 🏗️ System Architecture

```
┌──────────────────────────────────────────┐
│           OnePlus Watch 2R               │
│                                          │
│  Flutter App                             │
│    │                                     │
│    ├── ConnectivityService (Riverpod)    │
│    │       │                             │
│    │    connectivity_plus ────────────── │─── WiFi State
│    │    internet_connection_checker ──── │─── Reachability ping
│    │                                     │
│    ├── Audio Recorder (record pkg)       │
│    │       │  WAV 16kHz mono             │
│    ├── Whisper API Client (Dio)          │
│    │       │  transcript                 │
│    ├── GPT-4o Translation Client (Dio)   │
│    │       │  japanese text              │
│    └── Android TTS (ja-JP)              │
│            │  audio out                  │
└────────────┼─────────────────────────────┘
             │  WiFi (802.11)
             ▼
    ┌─────────────────┐
    │  iPhone         │
    │  Personal       │
    │  Hotspot        │
    └────────┬────────┘
             │  LTE / 5G
             ▼
    ┌─────────────────┐
    │  OpenAI API     │
    │  (Whisper +     │
    │   GPT-4o)       │
    └─────────────────┘
```

**Data Flow:**
1. User holds button → audio recording starts (PCM, 16kHz mono)
2. Button released → WAV file finalized
3. Whisper API: audio → English transcript (~0.8s)
4. GPT-4o API: transcript → Japanese translation (~0.8s)
5. Android TTS: Japanese text → synthesized speech (~0.3s)
6. Watch speaker plays audio + screen shows Japanese + Romaji
7. **Total: ~1.9–2.5s on good LTE**

---

## 6. 🔧 Technical Design

### Tech Stack

| Layer | Technology |
|---|---|
| Language (UI) | Dart (Flutter) |
| Language (Native bridges) | Kotlin (MethodChannel only where needed) |
| UI Framework | Flutter for Wear OS |
| Async | Dart async/await + Riverpod streams |
| HTTP Client | Dio 5.x (timeout, interceptors, retry) |
| Audio Capture | `record` Flutter package |
| STT | OpenAI Whisper API (`whisper-1`, `language` param set per mode) |
| Translation | OpenAI GPT-4o-mini (`/chat/completions`) — downgraded from gpt-4o for battery |
| TTS | `flutter_tts` Android TTS; `ja-JP` for EN→JP, `en-US` for JP→EN; speech rate 0.5 |
| Translation Mode | `TranslationMode` enum (enToJp / jpToEn); `translationModeProvider` StateProvider |
| Mode UI | `ModeToggle` widget (chip pair on idle screen) |
| Volume | `VolumeService` + `VolumeNotifier` (Riverpod); native MethodChannel `com.example.speakeasy_watch/volume` → `AudioManager.STREAM_MUSIC` |
| Connectivity | `connectivity_plus` + direct HTTP probe to `https://www.google.com/generate_204` (4s timeout, 3 retries, 0.8s gap, 30s periodic recheck) |
| Network States | `connecting` / `connected` / `poor` / `offline` — mic NOT disabled during `connecting` |
| State Management | Riverpod |
| Storage | SharedPreferences (volume), sqflite v2 (history with `mode` column) |
| Wakelock | `WakelockPlus` — enable on startRecording, disable after TTS completes or on error/reset |
| Screen-on | `FLAG_KEEP_SCREEN_ON` set in `MainActivity.onCreate()` |
| Analytics | Firebase Analytics (Wear-compatible) — Phase 4 |
| Crash Reporting | Firebase Crashlytics — Phase 4 |

### Flutter on Wear OS — Constraints & Mitigations

| Constraint | Mitigation |
|---|---|
| No official Wear OS Flutter SDK | Use `wear` Flutter package + custom `ClipOval` layouts |
| Round screen clipping | Wrap all screens in `ClipOval` + 20px EdgeInsets safe zone |
| Small screen (454×454px) | Min tap target 48×48dp; title 16sp, body 13sp, caption 11sp |
| Flutter engine memory (~40MB) | Minimize widget tree depth; use `const` constructors everywhere |
| No native `MediaRecorder` in Flutter | Use `record` package; fallback to `MethodChannel` → Kotlin |

### Flutter Package Stack

```yaml
dependencies:
  flutter:
    sdk: flutter
  record: ^5.1.0
  dio: ^5.4.0
  connectivity_plus: ^6.0.0
  # internet_connection_checker_plus removed — replaced by direct HTTP probe
  flutter_riverpod: ^2.5.0
  flutter_tts: ^4.x          # replaces audioplayers for TTS
  shared_preferences: ^2.2.0
  sqflite: ^2.3.0
  path: ^1.x
  path_provider: ^2.1.0
  wear: ^1.0.0
  wakelock_plus: ^1.2.0
```

### Screen Layout Rule (Round Display)

All screens are wrapped in `SingleChildScrollView` to prevent overflow. Padding reduced to 16px.

```dart
ClipOval(
  child: Container(
    width: double.infinity,
    height: double.infinity,
    color: Colors.black,
    padding: const EdgeInsets.all(16), // reduced from 20
    child: SingleChildScrollView(
      child: /* screen content */,
    ),
  ),
)
```

### API Design

**Whisper:**
```
POST https://api.openai.com/v1/audio/transcriptions
Content-Type: multipart/form-data
- file: audio.wav
- model: whisper-1
- language: "en" (EN→JP mode) | "ja" (JP→EN mode)   ← driven by TranslationMode
```

**GPT-4o-mini (EN→JP):**
```
POST https://api.openai.com/v1/chat/completions
{
  "model": "gpt-4o-mini",
  "messages": [
    { "role": "system", "content": "You are a professional Japanese translator. Translate the English text to natural, polite Japanese (丁寧語). Reply with ONLY the Japanese translation. No explanations, no romanization, no English." },
    { "role": "user", "content": "<transcript>" }
  ],
  "max_tokens": 150,
  "temperature": 0.2
}
```

**GPT-4o-mini (JP→EN):**
```
POST https://api.openai.com/v1/chat/completions
{
  "model": "gpt-4o-mini",
  "messages": [
    { "role": "system", "content": "You are a professional English translator. Translate the Japanese text to natural, clear English. Reply with ONLY the English translation. No explanations, no Japanese." },
    { "role": "user", "content": "<transcript>" }
  ],
  "max_tokens": 150,
  "temperature": 0.2
}
```

### Latency Optimization
- Pre-warm HTTP connection pool on app launch
- `okhttp3.ConnectionPool` keep-alive
- `max_tokens: 150` + `temperature: 0.2` to cap GPT decode time
- `gpt-4o-mini` instead of `gpt-4o` — faster + cheaper, minimal accuracy impact
- Pre-initialize TTS engine on app start (not on first use)
- Silence detection removed; manual stop keeps recordings concise
- Max recording duration: 3 minutes (auto-stop)
- Target audio file size: < 150KB for typical phrases

---

## 7. 🌐 Connectivity Monitoring System

### NetworkStatus States

| State | Indicator | Behavior |
|---|---|---|
| `connecting` | 🔵 Blue-grey "Checking…" | Shown while HTTP probe is in-flight; mic NOT disabled |
| `connected` | 🟢 Green WiFi icon | Normal operation |
| `poor` | 🟡 Yellow WiFi icon | Allow recording, show warning banner, retry on failure |
| `offline` | 🔴 Red WiFi off icon | Disable mic button, show hotspot message |

### ConnectivityService (Riverpod) — Actual Implementation

Replaced `internet_connection_checker_plus` with a direct HTTP probe to `https://www.google.com/generate_204`.

```dart
enum NetworkStatus { connecting, connected, poor, offline }

// Probe parameters (actual values in production):
// - URL: https://www.google.com/generate_204
// - timeout: 4s per attempt
// - retries: 3, delay 800ms between retries
// - periodic recheck: every 30s
// - debounce on connectivity change: 1.5s
// - connects → connected if latency ≤ 2000ms, else poor

// Initial state: NetworkStatus.connecting (not offline)
// Mic is only disabled when state == NetworkStatus.offline
```

### Mic Button Behavior

| State | Button | Action |
|---|---|---|
| `connecting` | Enabled (not blocked) | Probing — user can still attempt to record |
| `connected` | Enabled | Normal push-to-talk |
| `poor` | Enabled + warning banner | Record; retry automatically on API failure |
| `offline` | Disabled (grayed) | Tap shows: "No internet. Please enable iPhone hotspot." |

### Dio Retry Interceptor

```dart
dio.interceptors.add(RetryInterceptor(
  dio: dio,
  retries: 3,
  retryDelays: [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ],
  retryEvaluator: (error, attempt) =>
    error.type == DioExceptionType.connectionTimeout ||
    error.type == DioExceptionType.receiveTimeout ||
    error.response?.statusCode == 503,
));
```

---

## 8. 📱 UX Design Guidelines (Wear OS)

### Screen States

**Idle:**
```
┌─────────────────┐
│  🌐 SpeakEasy   │
│  [EN→JP][JP→EN] │  ← ModeToggle chips
│  ┌───────────┐  │
│  │  🎤 TAP   │  │
│  │  TO TALK  │  │
│  └───────────┘  │
│  🔊 ─────── 80% │  ← VolumeSlider
│  🟢 Connected   │
└─────────────────┘
```

**Recording:**
```
┌─────────────────┐
│  ● REC  00:05   │  ← MM:SS timer
│  ┌───────────┐  │
│  │  🔴 TAP   │  │
│  │  TO STOP  │  │
│  └───────────┘  │
│  Listening for  │
│  English...     │  ← driven by TranslationMode
└─────────────────┘
```

**Processing:**
```
┌─────────────────┐
│   Translating   │
│    ◌ ◌ ◌        │
│  "How much      │
│   does this..." │
└─────────────────┘
```

**Result:**
```
┌─────────────────┐
│  🔊 EN→JP       │  ← or "🔊 JP→EN" based on mode
│  これはいくら   │
│  ですか？       │
│  how much is... │  ← original transcript (small)
│  [↩ Again][Back]│
│  1850ms         │  ← latency
└─────────────────┘
```

**Offline:**
```
┌─────────────────┐
│  🌐 SpeakEasy   │
│  ┌───────────┐  │
│  │  🎤  (🚫) │  │
│  └───────────┘  │
│  No internet.   │
│  Enable hotspot │
│  🔴 Offline     │
└─────────────────┘
```

### Button Behavior
- **Press and hold** → start recording
- **Release** → stop + trigger pipeline
- **Double tap** → replay last translation
- **Swipe up** → translation history
- **Swipe down** → settings

### Haptic Feedback

| Event | Pattern |
|---|---|
| Recording started | 1 short pulse |
| Recording stopped | 2 short pulses |
| Translation ready | 1 long vibration |
| Error | 3 rapid pulses |

---

## 9. ⚠️ Edge Cases & Failure Handling

| Scenario | Detection | Handling |
|---|---|---|
| No speech detected | RMS < threshold | "No speech detected. Try again." |
| Background noise only | Whisper returns < 3 words | Validate transcript; show retry |
| No network | ConnectivityManager pre-call | "No internet. Please enable iPhone hotspot." |
| Whisper timeout (>5s) | OkHttp timeout | "Taking too long... retry?" |
| GPT-4o non-Japanese response | Regex check for Japanese chars | Re-call with stricter prompt; log error |
| TTS engine failure | onError callback | Display text only; "Audio unavailable" |
| Watch goes ambient mid-flow | onEnterAmbient lifecycle | Pause recording; resume on wake |
| API quota exceeded (429) | HTTP response code | Exponential backoff; "Service busy" |
| Internet drops mid-Whisper upload | DioException timeout | Retry up to 3x; "Connection lost. Retrying..." |
| iPhone hotspot auto-sleeps | ConnectivityResult.none | "Hotspot may be off. Enable iPhone hotspot and tap retry." |
| Connected WiFi, no data | InternetChecker returns false | "Connected but no internet. Check hotspot data." |
| Network recovers during retry wait | connectivityProvider emits connected | Resume queued API call immediately |
| Weak network, partial response | Malformed JSON parse failure | Treat as failure; retry |
| Watch WiFi re-associates (DHCP delay) | Brief offline flash | Debounce 1.5s before acting on offline state |

---

## 10. 📊 Product Metrics & Tracking

### Core Events

```
translation_started        { trigger: "button_hold" }
recording_duration_ms      { value: 2400 }
whisper_latency_ms         { value: 820 }
gpt_latency_ms             { value: 750 }
tts_latency_ms             { value: 280 }
total_latency_ms           { value: 1850 }
translation_success        { transcript_len: 6, output_lang: "ja" }
translation_error          { error_type: "network|timeout|empty|api_error" }
network_status_changed     { from: "connected", to: "offline" }
api_call_retried           { attempt: 2, reason: "timeout", phase: "whisper" }
api_retry_succeeded        { total_attempts: 2, added_latency_ms: 1200 }
api_retry_failed           { total_attempts: 3, final_error: "timeout" }
offline_block_shown        { user_attempted_record: true }
connectivity_recovery_ms   { value: 3200 }
phrase_favorited           {}
session_start              { network_type: "wifi|lte|none" }
session_end                { translations_count: 4, duration_s: 180 }
```

### Key Dashboards

| Panel | Alert Threshold |
|---|---|
| p50/p95/p99 total latency | p95 > 3s → investigate |
| Translation success rate | < 95% → investigate |
| Network failure rate | > 5% → investigate |
| Retry success rate | < 70% → latency issue |
| Avg connectivity recovery time | > 8s → UX degradation |
| Offline blocks per session | > 1 → hotspot reliability issue |

---

## 11. 🚀 Execution Plan (Jira-Ready Backlog)

### Epic 0 — Connectivity Foundation *(complete before Epic 2)*
- Task 0.1: Integrate `connectivity_plus` + `internet_connection_checker_plus`
- Task 0.2: Build `ConnectivityIndicator` widget (green/yellow/red)
- Task 0.3: Gate mic button on network state
- Task 0.4: Implement Dio retry interceptor (3x, exponential backoff)
- Task 0.5: Debounce offline state (1.5s)

### Epic 1 — Core Audio Pipeline
- Task 1.1: Set up Wear OS Flutter project
- Task 1.2: Implement push-to-talk audio recording
- Task 1.3: Silence detection (RMS, auto-stop)

### Epic 2 — API Integration
- Task 2.1: Whisper STT client
- Task 2.2: GPT-4o translation client
- Task 2.3: API error handling (timeout, 429, 5xx)

### Epic 3 — TTS & Audio Output
- Task 3.1: Android TTS setup (ja-JP, pre-initialized)
- Task 3.2: Volume control

### Epic 4 — Flutter UI (All Screens)
- Task 4.1: Idle screen
- Task 4.2: Recording screen (waveform + timer)
- Task 4.3: Processing screen (animated dots)
- Task 4.4: Result screen (Japanese + Romaji + buttons)
- Task 4.5: Error screen (retry CTA)
- Task 4.6: Offline screen
- Task 4.7: History screen (swipe-up)

### Epic 5 — Haptics & Polish
- Task 5.1: Vibration patterns per state
- Task 5.2: Wrist-raise wake behavior
- Task 5.3: Ambient mode lifecycle

### Epic 6 — Security & Config
- Task 6.1: API key management via `local.properties`
- Task 6.2: ProGuard/R8 config
- Task 6.3: Privacy policy

### Epic 7 — Analytics & Observability
- Task 7.1: Firebase integration
- Task 7.2: Custom event logging
- Task 7.3: Crashlytics

---

## 12. ⏱️ Timeline

| Phase | Duration | Dependencies |
|---|---|---|
| Phase 1 (MVP) | 3–4 weeks | OpenAI API access, Watch device ready |
| Phase 2 (Usability) | 2–3 weeks | Phase 1 complete + 3 beta testers |
| Phase 3 (Advanced) | 4–5 weeks | Phase 2 stable, offline phrase dataset |
| Phase 4 (Production) | 2 weeks | Phase 3 complete, Play Dev account |
| **Total** | **~12 weeks** | |

**Critical Path:**
```
Week 1:    Connectivity system + audio recording
Week 2-3:  Whisper + GPT-4o + TTS pipeline
Week 4:    Flutter UI + end-to-end test on watch
Week 5-6:  Haptics, history, error handling polish
Week 7-8:  Offline mode + bidirectional
Week 9-10: Analytics + security hardening
Week 11-12: Play Store prep + launch
```

---

## 13. 🧪 Testing Strategy

### Functional Testing
- Unit tests for API clients (MockWebServer)
- Unit tests for silence detection
- Flutter widget tests for each screen state
- Integration test: WAV file → Japanese text pipeline

### Connectivity Test Scenarios

| Test | Steps | Expected |
|---|---|---|
| Cold start offline | Launch with hotspot off | Red indicator, mic disabled |
| Hotspot enable after launch | Turn on hotspot while app open | Green within 3s, mic re-enables |
| Drop during Whisper upload | Disable hotspot 0.5s after button release | Retry shown, recovers on reconnect |
| Connected WiFi, no data | Captive portal with no internet | Yellow/red shown, API blocked |
| Weak signal simulation | Throttle to 50kbps | Poor state shown, retry engaged |

### Real-World Travel Scenarios (10 Standard Phrases)
1. "How much does this cost?"
2. "Where is the nearest train station?"
3. "I would like to order this, please."
4. "Do you have an English menu?"
5. "Can I pay by card?"
6. "Please call an ambulance."
7. Background noise test (crowded environment)
8. Whisper speech only (incomplete sentence)
9. Multi-sentence phrase
10. Very fast speech

### Performance Targets

| Phase | Criteria |
|---|---|
| MVP | 10/10 phrases < 3s on WiFi |
| Phase 2 | 10/10 < 3s on LTE; 0 crashes in 100 translations |
| Phase 3 | Offline covers 8/10 common scenarios |
| Phase 4 | p95 ≤ 3s in Firebase; crash-free ≥ 99.5% |

---

## 14. 🔐 Security Considerations

- **API keys:** `local.properties` → `BuildConfig` injection; never hardcoded
- **Production key rotation:** Firebase Remote Config (no app update needed)
- **Voice data:** Streamed directly to OpenAI; temp WAV deleted immediately after upload
- **No cloud persistence:** Translation history stored locally in sqflite only
- **Privacy Policy must state:** "Voice data is processed by OpenAI and not retained by SpeakEasy Watch"
- **Network security:** `network_security_config.xml` enforces HTTPS only
- **Certificate pinning:** OpenAI endpoints (Phase 4)
- **GDPR:** Consent screen required if targeting EU users

---

---

## 15. 🎨 Branding & App Icon

### SVG Logo
- Path: `assets/images/logo.svg`
- 512×512; blue circle (#1565C0 background), microphone icon, EN/JP speech bubbles with ↔ arrows

### Android Adaptive Icon (API 26+)
- Foreground: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- Background: `android/app/src/main/res/drawable/ic_launcher_background.xml` — color `#1565C0`
- Manifest entries: `mipmap-anydpi-v26/ic_launcher.xml` + `ic_launcher_round.xml`

---

## 16. 📐 Current Implementation State (as of 2026-03-25)

| Area | Status | Notes |
|---|---|---|
| Core translation pipeline | ✅ Done | EN→JP and JP→EN end-to-end |
| Bidirectional mode | ✅ Done | ModeToggle, TranslationMode enum, per-mode Whisper lang + TTS locale |
| Recording | ✅ Done | Manual stop, 3-min max, MM:SS timer, ⚠️ at 2:45 |
| Silence detection | ❌ Removed | Replaced by manual stop |
| Volume control | ✅ Done | Slider on idle screen, native STREAM_MUSIC, auto-boost to 1.0 on startup if < 0.8 |
| TTS | ✅ Done | speech rate 0.5, engine volume 1.0, VolumeService.setMaxVolume() before speak, completion handler |
| Connectivity | ✅ Done | HTTP probe, 4 states incl. connecting, 30s periodic recheck |
| Wakelock | ✅ Done | Scoped: enable on record start, disable after TTS completes or on error/reset |
| Screen-on | ✅ Done | FLAG_KEEP_SCREEN_ON in MainActivity.onCreate() |
| Translation history DB | ✅ Done | sqflite v2, mode column, up to 50 entries |
| History UI screen | Partial | HistoryScreen built; swipe-up nav from idle screen |
| App icon / branding | ✅ Done | SVG logo + adaptive icon |
| Haptics | ⬜ Not started | Phase 2 |
| Romaji display | ⬜ Not started | Phase 2 |
| Firebase Analytics | ⬜ Not started | Phase 4 |
| Offline phrase pack | ⬜ Not started | Phase 3 |

---

## Dev Quick Reference

```
Watch ADB:     adb connect 192.168.1.14:34359
Run on watch:  flutter run -d 192.168.1.14:34359
Project path:  ccode_on_android_watch/speakeasy_watch/
Device:        OnePlus Watch 2R (OPWWE234), Android 14, API 34
Internet:      iPhone Personal Hotspot (standalone — no Android phone)
```

---

*This document is the single source of truth for the SpeakEasy Watch product. Each phase has clear entry/exit criteria — no phase begins until the previous one passes its exit criteria on real hardware.*
