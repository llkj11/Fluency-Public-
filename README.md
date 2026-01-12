# Fluency

**Fluency** is a powerful macOS utility that bridges the gap between your thoughts and your screen. It provides seamless, global Speech-to-Text (Dictation) and Text-to-Speech (TTS) capabilities using advanced AI models from **OpenAI** and **Google Gemini**.

## Features

### 🎙️ AI Dictation (Speech-to-Text)
- **Global Hotkey**: Hold `Fn` key to speak, release to stop.
- **GPT-4o Mini Integration**: Uses OpenAI's fast and accurate `gpt-4o-mini-transcribe` model.
- **Smart Formatting**: Automatically handles punctuation and formatting.
- **Auto-Paste**: Inserts transcribed text directly into your active application.

### 🗣️ AI Text-to-Speech (TTS)
- **Global Hotkey**: Select text, then hold `Option` and press `Fn` to hear it read aloud.
- **Multi-Provider Support**:
  - **OpenAI**: Uses `gpt-4o-mini-tts` for natural, human-like speech.
  - **Google Gemini**: Uses `gemini-2.5-flash-preview` for expressive, director-controlled performances.
- **Voice Presets**: Choose from 5 built-in styles (Neutral, Cheerful, Calm, Professional, Storyteller) or create your own custom presets.
- **Visual Overlay**: Beautiful animated waveform overlay while speaking.
- **30+ Voices**: Access a massive library of voices from both providers.

### 🎨 Global Themes
- **Customize Your Experience**: Choose from 6 unique themes that transform the app's colors, fonts, and styling.
- **Available Themes**:
  - **Aurora**: Vibrant purple to cyan gradient (Default).
  - **Midnight**: Deep indigo and electric blue.
  - **Ember**: Warm orange and deep red.
  - **Forest**: Emerald green and teal.
  - **Monochrome**: Minimal grayscale.
  - **Sakura**: Soft pink and lavender.
- **Persistent Selection**: Your chosen theme is automatically saved across sessions.

## Setup

1.  **Launch the App**: Open **Fluency.app**.
2.  **Permissions**: Grant **Accessibility** and **Microphone** permissions when prompted (required for hotkeys and audio capture).

### Customizing Hotkeys
Open **Settings → Keyboard Shortcuts** to customize your global hotkeys:
- **Start Recording**: Default `Fn` (hold to record)
- **Cancel Recording**: Default `Control + Fn`
- **Read Aloud (TTS)**: Default `Option + Fn`

Click the keyboard icon next to any action to toggle secondary modifiers (Option, Control, Shift, Command).
3.  **API Configuration**:
    - Open **Settings** (Click menu bar icon -> Settings).
    - Enter your **OpenAI API Key** (for Dictation & TTS).
    - Enter your **Google Gemini API Key** (optional, for Gemini TTS).
4.  **Select Provider**: Choose your preferred TTS provider in Settings.

## Usage

| Feature | Action |
| :--- | :--- |
| **Dictate** | Hold `Fn`, speak, then release |
| **Read Selected Text** | Highlight text, then hold `Option` and press `Fn` |
| **Stop Reading** | Hold `Option` then press `Fn` |

## Requirements
- macOS 13.0 (Ventura) or later.
- Active internet connection (for API calls).
