# Fluency

A macOS menu bar app for global AI-powered dictation and text-to-speech. Use your own API keys - no subscriptions, no usage limits beyond what you pay for.

Built as an alternative to Whisper Flow and similar services.

## Features

### Dictation (Speech-to-Text)
- **Global hotkey**: Hold `Fn` to speak, release to transcribe
- **Auto-paste**: Transcribed text inserts directly into your active app
- Uses OpenAI's `gpt-4o-mini-transcribe` model

### Text-to-Speech
- **Global hotkey**: Select text, hold `Option + Fn` to hear it read aloud
- **Multiple providers**: OpenAI (`gpt-4o-mini-tts`) or Google Gemini (`gemini-2.5-flash-preview`)
- **30+ voices** with 5 built-in presets (Neutral, Cheerful, Calm, Professional, Storyteller)
- **Custom presets**: Create your own voice + style combinations

### Screen Intelligence
- **Smart OCR**: `Fn + Shift` + select region to extract and read text
- **Scene Description**: `Fn + Shift + Option` + select region to describe visual content
- Uses Google Gemini Flash for fast vision analysis

### Themes
6 color themes: Aurora (default), Midnight, Ember, Forest, Monochrome, Sakura

---

## Installation

### Option 1: Download Release (Recommended)
1. Download the latest `Fluency.zip` from [Releases](../../releases)
2. Unzip and drag `Fluency.app` to your Applications folder
3. Open Terminal and run:
   ```bash
   xattr -cr /Applications/Fluency.app
   ```
4. Double-click Fluency to launch

> **Note**: The Terminal command is required because the app isn't notarized with Apple. It removes the quarantine flag macOS adds to downloaded files.

### Option 2: Build from Source
Requires Xcode 15+ and macOS 13.0+

```bash
git clone https://github.com/llkj11/fluency-app.git
cd fluency-app
open Fluency.xcodeproj
```

In Xcode:
1. Select the "Fluency" scheme
2. Set signing team to your Apple Developer account (or Personal Team)
3. Build and run (`Cmd + R`)

---

## Setup

### 1. Grant Permissions
On first launch, grant these permissions when prompted:
- **Accessibility**: Required for global hotkeys and auto-paste
- **Microphone**: Required for dictation

You can also enable these in **System Settings > Privacy & Security**.

### 2. Get API Keys (Required Before Use)

**You must enter at least an OpenAI API key before dictation or TTS will work.** Gemini is optional but enables additional TTS voices and vision features.

| Provider | Get Key | Required For |
|----------|---------|--------------|
| OpenAI | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) | Dictation, TTS |
| Google Gemini | [aistudio.google.com/apikey](https://aistudio.google.com/app/apikey) | Gemini TTS, Vision/OCR |

**Cost estimates** (as of Jan 2025):
- Dictation: ~$0.001 per minute of audio
- TTS: ~$0.015 per 1000 characters
- Vision: ~$0.001 per image

### 3. Configure Fluency
1. Click the Fluency icon in your menu bar
2. Open **Settings**
3. Enter your API keys
4. Select your preferred TTS provider

---

## Usage

| Action | Hotkey |
|--------|--------|
| Dictate | Hold `Fn`, speak, release |
| Read selected text | Select text, then `Option + Fn` |
| Stop reading | `Option + Fn` |
| Smart OCR | `Fn + Shift`, select region |
| Describe screen | `Fn + Shift + Option`, select region |
| Cancel recording | `Control + Fn` |

### Customizing Hotkeys
Open **Settings > Keyboard Shortcuts** to change any hotkey. Click the modifier icons to add Option, Control, Shift, or Command.

---

## Troubleshooting

### "Fluency can't be opened because it is from an unidentified developer"
Right-click the app and select "Open", then click "Open" in the dialog.

### Dictation not working
1. Check microphone permission in System Settings > Privacy & Security > Microphone
2. Verify your OpenAI API key is entered correctly
3. Check your OpenAI account has credits

### Hotkeys not responding
1. Check accessibility permission in System Settings > Privacy & Security > Accessibility
2. Try toggling the permission off and on
3. Restart Fluency

### TTS sounds robotic or cuts off
- Try switching between OpenAI and Gemini providers
- Check your internet connection
- Longer text may take a moment to process

---

## Requirements

- macOS 13.0 (Ventura) or later
- Internet connection
- OpenAI API key (required)
- Google Gemini API key (optional)

---

## License

MIT License - see [LICENSE](LICENSE)

---

## Acknowledgments

Built with SwiftUI. Uses OpenAI and Google Gemini APIs.
