# Fluency - Project Scope

## What Is This?
A native macOS menu bar app that provides voice interaction anywhere on your Mac:
- **Speech-to-Text (STT)**: Hold Fn key to speak, release to transcribe and paste
- **Text-to-Speech (TTS)**: Select text anywhere, press Fn+Control to hear it spoken

## Tech Stack
- Swift 5.9+ / SwiftUI
- AVFoundation for audio recording and playback
- CGEvent tap for global Fn key detection
- OpenAI `gpt-4o-mini-transcribe` API for STT
- OpenAI `gpt-4o-mini-tts` API for TTS
- SwiftData for history persistence
- UserDefaults for API key and settings storage

## Key Features
1. **Hold Fn Key** - Hold to record, release to transcribe (STT)
2. **Fn + Control** - Speaks selected text aloud (TTS)
3. **Auto-Paste** - Transcription auto-pastes into the active text field
4. **Recording Overlay** - Floating popup with waveform animation
5. **Speaking Overlay** - Floating popup with sound wave animation
6. **History View** - See past transcriptions with timestamps
7. **Voice Selection** - Choose from 13 OpenAI TTS voices
8. **Settings** - API key input, voice selection, launch at login
9. **Menu Bar App** - Lives in menu bar, minimal footprint

## Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| Hold **Fn** | Record voice → Speech-to-Text → Auto-paste |
| **Fn + Control** | Selected text → Text-to-Speech → Audio playback |

## Project Structure
```
Fluency/
├── FluencyApp.swift           # App entry, menu bar setup, AppDelegate, AppState
├── Models/
│   └── Transcription.swift    # SwiftData model for history
├── Services/
│   ├── HotkeyService.swift    # Global Fn key detection via CGEvent
│   ├── AudioRecorder.swift    # AVAudioRecorder wrapper (records to .m4a)
│   ├── TranscriptionService.swift  # OpenAI STT API + KeychainHelper
│   ├── TTSService.swift       # OpenAI TTS API + AVAudioPlayer
│   ├── TextCaptureService.swift    # Capture selected text via Cmd+C
│   ├── PasteService.swift     # Accessibility paste via AXUIElement
│   ├── AudioFeedbackService.swift  # Sound effects
│   └── StatsService.swift     # Usage statistics
├── Views/
│   ├── MenuBarView.swift      # Menu bar popover with status & actions
│   ├── RecordingOverlay.swift # Floating "Listening..." popup with waveform
│   ├── SpeakingOverlay.swift  # Floating "Speaking..." popup with sound waves
│   ├── HistoryView.swift      # List of past transcriptions
│   ├── SettingsView.swift     # API key, voice selection, permissions
│   └── StatsView.swift        # Usage statistics display
└── Resources/
    ├── Info.plist             # Permissions (microphone)
    └── Fluency.entitlements   # Audio input entitlement
```

## Required Permissions
1. **Microphone** - For recording voice
2. **Accessibility** - For CGEvent tap (hotkey detection) and text paste/capture

## OpenAI API Details

### Speech-to-Text (STT)
- Endpoint: `POST https://api.openai.com/v1/audio/transcriptions`
- Model: `gpt-4o-mini-transcribe`
- Audio format: AAC (.m4a), 16kHz, mono
- Response format: `text`
- Cost: ~$0.003/minute

### Text-to-Speech (TTS)
- Endpoint: `POST https://api.openai.com/v1/audio/speech`
- Model: `gpt-4o-mini-tts`
- Audio format: WAV (for low latency)
- Available voices: alloy, ash, ballad, coral, echo, fable, marin⭐, cedar⭐, nova, onyx, sage, shimmer, verse
- Cost: ~$0.015/1K characters

## Implementation Status

### Completed
- [x] FluencyApp.swift - Main app entry with AppDelegate and AppState
- [x] Transcription.swift - SwiftData model
- [x] AudioRecorder.swift - AVAudioRecorder service
- [x] HotkeyService.swift - Fn key detection with CGEvent tap (Fn only + Fn+Control)
- [x] TranscriptionService.swift - OpenAI STT API
- [x] TTSService.swift - OpenAI TTS API with 13 voice options
- [x] TextCaptureService.swift - Capture selected text
- [x] PasteService.swift - Accessibility paste
- [x] AudioFeedbackService.swift - Sound effects
- [x] StatsService.swift - Usage statistics
- [x] RecordingOverlay.swift - Floating UI with waveform animation
- [x] SpeakingOverlay.swift - Floating UI with sound wave animation
- [x] MenuBarView.swift - Menu bar popover
- [x] HistoryView.swift - History list with search
- [x] SettingsView.swift - API key, voice selection, permissions
- [x] StatsView.swift - Usage statistics display
- [x] Info.plist - Permissions configured
- [x] Fluency.entitlements - Audio input enabled
- [x] Xcode project file (project.pbxproj)

### Ready to Build
All code is complete. Open the project in Xcode and build.

## How to Build & Run
1. Open `/Users/llkj/Documents/Projects/fluency/Fluency.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities (or leave blank for local testing)
3. Build and run (Cmd+R)
4. Grant microphone permission when prompted
5. Grant Accessibility permission in System Settings when prompted
6. Add your OpenAI API key in Settings (click the menu bar icon)
7. Set Fn key to "Do Nothing" in System Settings → Keyboard
8. Hold Fn key to record, release to transcribe!
9. Select text anywhere, then press Fn+Control to hear it spoken!

## API Documentation
- STT: See `/Users/llkj/Documents/DOCS/openai_speech_to_text.md`
- TTS: See `/Users/llkj/Documents/DOCS/openai_text_to_speech.md`

