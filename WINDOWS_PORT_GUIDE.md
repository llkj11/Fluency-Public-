# Fluency for Windows - Implementation Guide

A high-level guide for porting Fluency from macOS (Swift/SwiftUI) to Windows (C#/WinUI 3).

## Overview

Fluency is a dictation and TTS utility that runs in the system tray. It captures audio, transcribes via Groq Whisper API, and reads text aloud via OpenAI/Gemini TTS with streaming playback.

---

## Architecture Mapping

### Platform Equivalents

| macOS Component | Windows Equivalent |
|-----------------|-------------------|
| SwiftUI + AppKit | WinUI 3 (Windows App SDK) |
| AVAudioEngine | WASAPI or NAudio library |
| AVAudioPlayer | NAudio WaveOutEvent |
| URLSession | HttpClient |
| Keychain | Windows Credential Manager (PasswordVault) |
| UserDefaults | ApplicationData.LocalSettings |
| NSSound | System.Media.SoundPlayer |
| CGEventTap (Hotkeys) | Win32 SetWindowsHookEx / RegisterHotKey |
| NSPasteboard | Windows.ApplicationModel.DataTransfer.Clipboard |
| Accessibility API | UI Automation (UIA) |

---

## Services to Port

### 1. HotkeyService
**Purpose**: Global keyboard shortcuts (Hold Fn → Transcribe, Option+Fn → TTS)

**Windows Approach**:
- Use `SetWindowsHookEx` with `WH_KEYBOARD_LL` for low-level keyboard hook
- Track key down/up timing for "hold" detection
- Note: Fn key behavior varies by laptop manufacturer; may need alternative trigger

### 2. AudioRecorder
**Purpose**: Capture microphone audio for transcription

**Windows Approach**:
- Use **NAudio** library (`WasapiCapture`) for low-latency recording
- Match format: 16kHz, 16-bit, mono (Whisper's expected input)
- Save to WAV or stream directly

### 3. TranscriptionService
**Purpose**: Send audio to Groq Whisper API, receive text

**Windows Approach**:
- Use `HttpClient` with `MultipartFormDataContent`
- API calls are identical—just different HTTP library
- Parse JSON response with `System.Text.Json`

### 4. TTSService
**Purpose**: Convert text to speech via OpenAI/Gemini APIs

**Windows Approach**:
- Use `HttpClient.GetStreamAsync()` for streaming response
- Request PCM format (`response_format: "pcm"`)
- Stream chunks to audio player as they arrive

### 5. StreamingAudioPlayer
**Purpose**: Play PCM audio chunks in real-time

**Windows Approach**:
- Use **NAudio** `BufferedWaveProvider` + `WaveOutEvent`
- Configure: 24kHz sample rate, 16-bit, mono
- Buffer ~500ms before starting playback (matches Mac behavior)

### 6. TextCaptureService
**Purpose**: Get selected text from any application

**Windows Approach**:
- **Option A**: UI Automation API to query focused element's selection
- **Option B**: Simulate Ctrl+C, read clipboard, restore original clipboard
- Option B is more reliable across legacy apps

### 7. PasteService
**Purpose**: Type transcribed text into active window

**Windows Approach**:
- Use `SendInput` Win32 API to simulate keyboard input
- Or set clipboard and simulate Ctrl+V

### 8. KeychainHelper
**Purpose**: Securely store API keys

**Windows Approach**:
- Use `Windows.Security.Credentials.PasswordVault`
- Or use DPAPI (`ProtectedData.Protect/Unprotect`)

### 9. GroqService
**Purpose**: Analyze text tone for "Auto" preset

**Windows Approach**:
- Standard `HttpClient` POST to Groq API
- API logic is identical to macOS version

### 10. AudioFeedbackService
**Purpose**: Play system sounds for feedback

**Windows Approach**:
- Use `System.Media.SoundPlayer` for WAV files
- Or use `SystemSounds.Beep.Play()` for system sounds

---

## UI Components

### System Tray App
- Use `NotifyIcon` or WinUI 3's system tray support
- Show context menu with options (Settings, Quit, Stats)

### Floating Overlay (Recording Indicator)
- Borderless, always-on-top window
- Show waveform visualization during recording
- Position at bottom-center of screen

### Settings Window
- API key inputs (OpenAI, Gemini, Groq)
- Voice selection dropdowns
- Preset management
- Hotkey configuration

### Stats Dashboard
- Display usage statistics
- Word counts, transcription history

---

## Key Technical Considerations

### Audio Format Consistency
- **Recording**: 16kHz, 16-bit, mono (for Whisper)
- **TTS Playback**: 24kHz, 16-bit, mono (OpenAI output)
- Match these exactly to avoid quality issues

### Streaming Buffer Size
- Buffer 500ms (~24,000 bytes at 24kHz 16-bit) before playback
- Prevents choppy audio and allows beep to complete

### Hotkey Handling
- Fn key is often not reported to OS on Windows laptops
- Consider alternative: `Ctrl+Shift+Space` or configurable

### Startup & Background
- App should start minimized to system tray
- Add to Windows startup via registry or Task Scheduler

---

## Recommended Libraries

| Purpose | Library |
|---------|---------|
| Audio Recording/Playback | NAudio |
| HTTP Requests | System.Net.Http.HttpClient |
| JSON Parsing | System.Text.Json |
| UI Framework | WinUI 3 (Windows App SDK) |
| Keyboard Hooks | SharpHook or raw Win32 |
| UI Automation | System.Windows.Automation |

---

## Development Setup

1. Install **Visual Studio 2022** (Community edition is free)
2. Install **.NET 8 SDK**
3. Install **Windows App SDK** workload
4. Clone this repository for reference
5. Create new **WinUI 3** project

---

## Suggested Port Order

1. **Phase 1 - Core Services** (No UI)
   - KeychainHelper → PasswordVault wrapper
   - GroqService → HttpClient implementation
   - TTSService → HttpClient + NAudio streaming

2. **Phase 2 - Audio Pipeline**
   - AudioRecorder → NAudio WasapiCapture
   - StreamingAudioPlayer → NAudio BufferedWaveProvider
   - AudioFeedbackService → SoundPlayer

3. **Phase 3 - System Integration**
   - HotkeyService → Keyboard hooks
   - TextCaptureService → UI Automation or clipboard
   - PasteService → SendInput

4. **Phase 4 - UI**
   - System tray icon
   - Settings window
   - Recording overlay
   - Stats dashboard

---

## Notes

- The API logic (OpenAI, Gemini, Groq) is platform-agnostic—only the HTTP library changes
- The "Director's Notes" prompt format for Gemini TTS works identically
- Voice presets and their instructions transfer directly
- Focus on getting streaming TTS working first—it's the most complex part
