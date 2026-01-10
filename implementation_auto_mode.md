# Implementation Plan: Auto-Style TTS (Dynamic Tone Analysis)

## Goal
Implement an "Auto" voice preset that dynamically analyzes the user's text using a fast LLM (Groq) to generate custom "Director's Notes" on the fly, tailoring the TTS delivery (tone, pace, style) to the specific content.

## Architecture

### 1. New Logic Flow
When the user triggers TTS with the **"Auto"** preset:
1.  **Intercept**: Pause the TTS request.
2.  **Analyze (Groq/Kimi)**: Send text to Groq. **Kimi K2 only returns the raw style description** (e.g., "Style: Urgent and excited."). It does *not* format the prompt for specific providers.
3.  **Application Logic (Swift)**: The app takes this raw string and applies the correct strategy:
    -   **OpenAI**: Pass string to `instructions` API parameter.
    -   **Gemini**: Inject string into `### DIRECTOR'S NOTES` prompt template.

### 2. New Service: `GroqService.swift`
A lightweight service to handle the LLM call.

-   **Endpoint**: `https://api.groq.com/openai/v1/chat/completions`
-   **Model**: `moonshotai/kimi-k2-instruct-0905` (Fast & capable)
-   **System Prompt**:
    ```text
    You are an expert audio director. Analyze the following text and provide concise "Director's Notes" for a TTS AI to read it aloud.
    Focus on: Style, Pace, and Tone.
    Format your response as a single concise string.
    Example: "Style: Joyful and upbeat. Pace: Brisk. Tone: Warm."
    Do NOT output anything else.
    ```

### 3. Settings Updates
-   Add **Groq API Key** field in `SettingsView`.
    -   Store in Keychain (`com.fluency.groq-api-key`).

### 4. Code Changes

#### `VoicePreset`
-   Add an `auto` case/preset:
    ```swift
    static let auto = VoicePreset(id: ..., name: "✨ Auto (Smart)", instructions: "")
    ```

#### `TTSService`
-   Modify `speak` method:
    ```swift
    if preset.id == VoicePreset.auto.id {
        let dynamicInstructions = try await GroqService.shared.analyzeTone(text: text)
        // Create a temporary preset with these instructions
        let tempPreset = VoicePreset(..., instructions: dynamicInstructions)
        // Proceed with speakOpenAI or speakGemini using tempPreset
    }
    ```

## Implementation Steps

1.  **Settings**: Add Groq API Key UI and storage.
2.  **GroqService**: Implement the API call to Groq.
3.  **UI**: Add "Auto (Smart)" to the preset list.
4.  **Integration**: Wire up `TTSService` to call Groq when "Auto" is selected.
5.  **Testing**: Verify latency and style appropriateness.

## Success Criteria
-   The "Auto" preset automatically detects if text is sad/happy/professional/etc.
-   The TTS output reflects this style.
-   Latency is minimal (< 1s extra).

## Resources
-   **Documentation**: Check the `Documents/DOCS` folder for API documentation (Groq, OpenAI, Gemini) if needed.
