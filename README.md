# Fluency

**Fluency** is a powerful macOS utility that bridges the gap between your thoughts and your screen. It provides seamless, global Speech-to-Text (Dictation) and Text-to-Speech (TTS) capabilities using advanced AI models from **OpenAI** and **Google Gemini**.

## Features

### 🎙️ AI Dictation (Speech-to-Text)
- **Global Hotkey**: Double-tap `Fn` to start listening instantly anywhere.
- **Whisper Integration**: Uses high-accuracy transcription (via OpenAI) to convert speech to text.
- **Smart Formatting**: Automatically handles punctuation and formatting.
- **Auto-Paste**: Inserts transcribed text directly into your active application.

### 🗣️ AI Text-to-Speech (TTS)
- **Global Hotkey**: Select text and press `Fn` + `Control` to hear it read aloud.
- **Multi-Provider Support**:
  - **OpenAI**: Uses `gpt-4o-mini-tts` for natural, human-like speech.
  - **Google Gemini**: Uses `gemini-2.5-flash-preview` for expressive, director-controlled performances.
- **Voice Presets**: Choose from 5 built-in styles (Neutral, Cheerful, Calm, Professional, Storyteller) or create your own custom presets.
- **Visual Overlay**: Beautiful animated waveform overlay while speaking.
- **30+ Voices**: Access a massive library of voices from both providers.

## Setup

1.  **Launch the App**: Open **Fluency.app**.
2.  **Permissions**: Grant **Accessibility** and **Microphone** permissions when prompted (required for hotkeys and audio capture).
3.  **API Configuration**:
    - Open **Settings** (Click menu bar icon -> Settings).
    - Enter your **OpenAI API Key** (for Dictation & TTS).
    - Enter your **Google Gemini API Key** (optional, for Gemini TTS).
4.  **Select Provider**: Choose your preferred TTS provider in Settings.

## Usage

| Feature | Action |
| :--- | :--- |
| **Start Dictation** | Double-tap `Fn` |
| **Stop Dictation** | Tap `Fn` again (or wait for silence) |
| **Read Selected Text** | Highlight text, then hold `Fn` and press `Control` |
| **Stop Reading** | Tap `Fn` |

## Requirements
- macOS 13.0 (Ventura) or later.
- Active internet connection (for API calls).
