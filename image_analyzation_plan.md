# Feature Plan: Screen Intelligence (OCR & Scene Analysis)

## Overview
This feature allows Fluency to "see" the user's screen and interpret it verbally. It introduces two distinct modes of operation triggered by separate global hotkeys.

## User Experience

### 1. Smart OCR Mode
*   **Trigger**: `Fn` + `Shift` + `Z`
*   **Goal**: Read text from the screen naturally.
*   **Behavior**:
    *   User activates hotkey.
    *   **System triggers region selection** (crosshair cursor).
    *   User selects area and releases mouse.
    *   Model extracts text from the *selected region* and formats it for listening.
    *   **TTS** reads the clean text immediately.

### 2. Scene Description Mode
*   **Trigger**: `Fn` + `Shift` + `X`
*   **Goal**: Describe what is happening in the image.
*   **Behavior**:
    *   User activates hotkey.
    *   **System triggers region selection** (crosshair cursor).
    *   User selects area and releases mouse.
    *   Model analyzes the visual context of the selection.
    *   **TTS** provides a concise, descriptive summary of the visual content.

## Architectural Components

### 1. Hotkey Management
*   Update `HotkeyService` to register and distinguish the two new key combinations.
*   Ensure these do not conflict with existing `Fn` double-tap or `Control` + `Fn` logic.

### 2. Screen Capture (`ScreenCaptureService`)
*   **Responsibility**: Interactive region capture.
*   **Method**: Use the built-in macOS screenshot utility in interactive mode: `/usr/sbin/screencapture -i <path>`.
    *   This provides the native macOS crosshair selection UI automatically.
    *   Wait for the process to exit (user completed selection).
    *   Read the resulting image from the temporary path.
*   **Privacy**: Relies on standard screen recording permissions (already handled by macOS UI).

### 3. Vision Provider (`VisionService`)
*   **Responsibility**: Interface with the API (Gemini or OpenAI).
*   **Dual Prompts**:
    *   *OCR Prompt*: "Extract the main content text from this image. Ignore UI chrome, menus, and navigation bars. Format for natural speech."
    *   *Analysis Prompt*: "Describe the visual content of this image. If it's a chart, summarize the trend. If it's a photo, describe the scene. Be concise."
*   **Abstraction**: Keep this service generic so the model provider stays swappable (Gemini 3 Flash recommended for speed/cost).

### 4. Integration
*   The workflow should be: `Hotkey` -> `Capture` -> `API` -> `TTSService.speak()`.
*   Connect the output of the vision service directly to the existing TTS `speak` method to leverage current voice settings.

## Technical Considerations
*   **Latency**: Use Gemini 3 Flash models to keep analysis time low (`<2s`).
*   **Image Optimization**: Resize/compress screenshots before API transmission to reduce latency and bandwidth.
*   **Feedback**: Play a distinct "shutter" sound or "analyzing" sound (reuse `AudioFeedbackService`) so the user knows capture worked.
*   **Documentation**: Use the skill to check documentation on my server for knowledge of the gemini and openai models. Make sure to use low-thinking mode on gemini 3 flash for speed of analyzation. 