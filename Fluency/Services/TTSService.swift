import Foundation
import AVFoundation

enum TTSError: LocalizedError {
    case noAPIKey
    case noTextSelected
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    case audioPlaybackFailed
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your OpenAI API key in Settings."
        case .noTextSelected:
            return "No text selected. Please select some text first."
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .audioPlaybackFailed:
            return "Failed to play audio"
        }
    }
}

// MARK: - TTS Provider

enum TTSProvider: String, CaseIterable {
    case openAI = "OpenAI"
    case gemini = "Google Gemini"
    case provider3 = "Provider 3 (Coming Soon)"
    case provider4 = "Provider 4 (Coming Soon)"
    case provider5 = "Provider 5 (Coming Soon)"
    
    var isAvailable: Bool {
        switch self {
        case .openAI, .gemini: return true
        default: return false
        }
    }
}

// MARK: - Voice

enum TTSVoice: String, CaseIterable {
    // OpenAI Voices
    case alloy = "alloy"
    case ash = "ash"
    case ballad = "ballad"
    case coral = "coral"
    case echo = "echo"
    case fable = "fable"
    case marin = "marin"
    case cedar = "cedar"
    case nova = "nova"
    case onyx = "onyx"
    case sage = "sage"
    case shimmer = "shimmer"
    case verse = "verse"
    
    // Gemini Voices
    case zephyr = "Zephyr"
    case puck = "Puck"
    case charon = "Charon"
    case kore = "Kore"
    case fenrir = "Fenrir"
    case leda = "Leda"
    case orus = "Orus"
    case aoede = "Aoede"
    case callirrhoe = "Callirrhoe"
    case autonoe = "Autonoe"
    case enceladus = "Enceladus"
    case iapetus = "Iapetus"
    case umbriel = "Umbriel"
    case algieba = "Algieba"
    case despina = "Despina"
    case erinome = "Erinome"
    case algenib = "Algenib"
    case rasalgethi = "Rasalgethi"
    case laomedeia = "Laomedeia"
    case achernar = "Achernar"
    case alnilam = "Alnilam"
    case schedar = "Schedar"
    case gacrux = "Gacrux"
    case pulcherrima = "Pulcherrima"
    case achird = "Achird"
    case zubenelgenubi = "Zubenelgenubi"
    case vindemiatrix = "Vindemiatrix"
    case sadachbia = "Sadachbia"
    case sadaltager = "Sadaltager"
    case sulafat = "Sulafat"
    
    var displayName: String {
        switch self {
        // OpenAI
        case .alloy: return "Alloy"
        case .ash: return "Ash"
        case .ballad: return "Ballad"
        case .coral: return "Coral"
        case .echo: return "Echo"
        case .fable: return "Fable"
        case .marin: return "Marin ⭐"
        case .cedar: return "Cedar ⭐"
        case .nova: return "Nova"
        case .onyx: return "Onyx"
        case .sage: return "Sage"
        case .shimmer: return "Shimmer"
        case .verse: return "Verse"
            
        // Gemini
        default: return self.rawValue
        }
    }
    
    var provider: TTSProvider {
        switch self {
        case .alloy, .ash, .ballad, .coral, .echo, .fable, .marin, .cedar, .nova, .onyx, .sage, .shimmer, .verse:
            return .openAI
        default:
            return .gemini
        }
    }
}

// MARK: - Voice Preset

struct VoicePreset: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var instructions: String
    var isBuiltIn: Bool
    
    init(id: UUID = UUID(), name: String, instructions: String, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.isBuiltIn = isBuiltIn
    }
    
    // Built-in presets
    static let neutral = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Neutral",
        instructions: "Style: Neutral. Speak in a clear, natural, and balanced tone. Maintain an even pace and steady volume. The delivery should be straightforward and uncolored by strong emotion.",
        isBuiltIn: true
    )
    
    static let cheerful = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Cheerful",
        instructions: "Style: The 'Vocal Smile'. You must hear the grin in the audio. The soft palate is always raised to keep the tone bright, sunny, and explicitly inviting. Dynamics: High projection without shouting. Punchy consonants and elongated vowels on excitement words.",
        isBuiltIn: true
    )
    
    static let calm = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Calm & Soothing",
        instructions: "Style: Calm and Soothing. Warm, gentle, and reassuring. Use a soft, breathy vocal quality. Pace: Slow and measured, with slightly longer pauses between phrases to create a sense of relaxation and ease.",
        isBuiltIn: true
    )
    
    static let professional = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Professional",
        instructions: "Style: Professional. Corporate, authoritative, and knowledgeable. The tone should be confident and polished, suitable for a business presentation or news broadcast. Articulation should be crisp and precise. Maintain a steady, informative pace.",
        isBuiltIn: true
    )
    
    static let storyteller = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "Storyteller",
        instructions: "Style: The Captivating Narrator. Use a rich, expressive tone that draws the listener in. Vary the pacing and pitch to highlight dramatic moments and build tension. Use deeper resonance for serious parts and lighter tones for brighter moments. Emotional engagement should be high, making the text feel alive and immersive.",
        isBuiltIn: true
    )
    
    static var builtInPresets: [VoicePreset] {
        [.neutral, .cheerful, .calm, .professional, .storyteller]
    }
}

// MARK: - TTS Service

class TTSService: NSObject, AVAudioPlayerDelegate {
    static let shared = TTSService()
    
    private let endpoint = "https://api.openai.com/v1/audio/speech"
    private let model = "gpt-4o-mini-tts"
    
    private var audioPlayer: AVAudioPlayer?
    private var onPlaybackComplete: (() -> Void)?
    
    private(set) var isSpeaking = false
    
    // Settings keys
    private static let voiceKey = "com.fluency.tts-voice"
    private static let providerKey = "com.fluency.tts-provider"
    private static let presetIdKey = "com.fluency.tts-preset-id"
    private static let customPresetsKey = "com.fluency.tts-custom-presets"
    
    override init() {
        super.init()
    }
    
    // MARK: - Provider Settings
    
    static var selectedProvider: TTSProvider {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: providerKey),
               let provider = TTSProvider(rawValue: rawValue) {
                return provider
            }
            return .openAI
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: providerKey)
        }
    }
    
    // MARK: - Voice Settings
    
    static var selectedVoice: TTSVoice {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: voiceKey),
               let voice = TTSVoice(rawValue: rawValue) {
                return voice
            }
            return .coral // Default voice
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: voiceKey)
        }
    }
    
    // MARK: - Preset Settings
    
    static var selectedPresetId: UUID {
        get {
            if let uuidString = UserDefaults.standard.string(forKey: presetIdKey),
               let uuid = UUID(uuidString: uuidString) {
                return uuid
            }
            return VoicePreset.neutral.id
        }
        set {
            UserDefaults.standard.set(newValue.uuidString, forKey: presetIdKey)
        }
    }
    
    static var selectedPreset: VoicePreset {
        let allPresets = VoicePreset.builtInPresets + customPresets
        return allPresets.first { $0.id == selectedPresetId } ?? .neutral
    }
    
    static var customPresets: [VoicePreset] {
        get {
            guard let data = UserDefaults.standard.data(forKey: customPresetsKey),
                  let presets = try? JSONDecoder().decode([VoicePreset].self, from: data) else {
                return []
            }
            return presets
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: customPresetsKey)
            }
        }
    }
    
    static func addCustomPreset(_ preset: VoicePreset) {
        var presets = customPresets
        presets.append(preset)
        customPresets = presets
    }
    
    static func deleteCustomPreset(_ preset: VoicePreset) {
        var presets = customPresets
        presets.removeAll { $0.id == preset.id }
        customPresets = presets
        
        // If deleted preset was selected, reset to neutral
        if selectedPresetId == preset.id {
            selectedPresetId = VoicePreset.neutral.id
        }
    }
    
    static func updateCustomPreset(_ preset: VoicePreset) {
        var presets = customPresets
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            customPresets = presets
        }
    }
    
    // MARK: - TTS Methods
    
    func speak(text: String, voice: TTSVoice? = nil, preset: VoicePreset? = nil, onComplete: (() -> Void)? = nil) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TTSError.noTextSelected
        }
        
        let selectedVoice = voice ?? TTSService.selectedVoice
        let selectedPreset = preset ?? TTSService.selectedPreset
        
        if selectedVoice.provider == .gemini {
            try await speakGemini(text: text, voice: selectedVoice, preset: selectedPreset, onComplete: onComplete)
        } else {
            try await speakOpenAI(text: text, voice: selectedVoice, preset: selectedPreset, onComplete: onComplete)
        }
    }
    
    // MARK: - OpenAI Implementation
    
    private func speakOpenAI(text: String, voice: TTSVoice, preset: VoicePreset, onComplete: (() -> Void)?) async throws {
        guard let apiKey = KeychainHelper.getAPIKey(for: .openAI), !apiKey.isEmpty else {
            throw TTSError.noAPIKey
        }
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var requestBody: [String: Any] = [
            "model": model,
            "input": text,
            "voice": voice.rawValue,
            "response_format": "wav"
        ]
        
        if !preset.instructions.isEmpty {
            requestBody["instructions"] = preset.instructions
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        try await performRequest(request, onComplete: onComplete)
    }
    
    // MARK: - Gemini Implementation
    
    private func speakGemini(text: String, voice: TTSVoice, preset: VoicePreset, onComplete: (() -> Void)?) async throws {
        guard let apiKey = KeychainHelper.getAPIKey(for: .gemini), !apiKey.isEmpty else {
            throw TTSError.apiError("No Gemini API key configured. Please add it in Settings.")
        }
        
        let geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent"
        
        // Construct prompt with Director's Notes style instructions
        var promptText = text
        if !preset.instructions.isEmpty {
            promptText = """
### DIRECTOR'S NOTES
\(preset.instructions)

### TRANSCRIPT
\(text)
"""
        }
        
        var request = URLRequest(url: URL(string: geminiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": promptText]]]
            ],
            "generationConfig": [
                "responseModalities": ["AUDIO"],
                "speechConfig": [
                    "voiceConfig": [
                        "prebuiltVoiceConfig": [
                            "voiceName": voice.rawValue
                        ]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            // Parse generic generation response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let inlineData = firstPart["inlineData"] as? [String: Any],
                  let base64String = inlineData["data"] as? String,
                  let pcmData = Data(base64Encoded: base64String) else {
                throw TTSError.apiError("Failed to parse audio data from Gemini response")
            }
            
            // Wrap PCM in WAV container
            let wavData = createWavData(from: pcmData)
            try await playAudio(data: wavData, onComplete: onComplete)
            
        } else {
            // Try to parse error
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw TTSError.apiError(message)
            }
            throw TTSError.apiError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    private func performRequest(_ request: URLRequest, onComplete: (() -> Void)?) async throws {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TTSError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                try await playAudio(data: data, onComplete: onComplete)
            } else {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw TTSError.apiError(message)
                }
                throw TTSError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as TTSError {
            throw error
        } catch {
            throw TTSError.networkError(error)
        }
    }
    
    // MARK: - Audio Helpers
    
    private func createWavData(from pcmData: Data) -> Data {
        let sampleRate: Int32 = 24000
        let channels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = sampleRate * Int32(channels * bitsPerSample / 8)
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = Int32(pcmData.count)
        let chunkSize = 36 + dataSize
        
        var header = Data()
        
        // RIFF chunk
        header.append("RIFF".data(using: .ascii)!)
        withUnsafeBytes(of: chunkSize.littleEndian) { header.append(contentsOf: $0) }
        header.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        header.append("fmt ".data(using: .ascii)!)
        withUnsafeBytes(of: Int32(16).littleEndian) { header.append(contentsOf: $0) } // Subchunk1Size
        withUnsafeBytes(of: Int16(1).littleEndian) { header.append(contentsOf: $0) } // AudioFormat (1 = PCM)
        withUnsafeBytes(of: channels.littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: sampleRate.littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: byteRate.littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: blockAlign.littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: bitsPerSample.littleEndian) { header.append(contentsOf: $0) }
        
        // data chunk
        header.append("data".data(using: .ascii)!)
        withUnsafeBytes(of: dataSize.littleEndian) { header.append(contentsOf: $0) }
        
        return header + pcmData
    }
    
    @MainActor
    private func playAudio(data: Data, onComplete: (() -> Void)?) async throws {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            onPlaybackComplete = onComplete
            
            if audioPlayer?.play() == true {
                isSpeaking = true
            } else {
                throw TTSError.audioPlaybackFailed
            }
        } catch {
            throw TTSError.audioPlaybackFailed
        }
    }
    
    func stopSpeaking() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
        onPlaybackComplete?()
        onPlaybackComplete = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            self?.onPlaybackComplete?()
            self?.onPlaybackComplete = nil
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            self?.onPlaybackComplete?()
            self?.onPlaybackComplete = nil
        }
    }
}
