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
    case elevenlabs = "ElevenLabs (Coming Soon)"
    case azure = "Azure TTS (Coming Soon)"
    case google = "Google Cloud TTS (Coming Soon)"
    case amazon = "Amazon Polly (Coming Soon)"
    
    var isAvailable: Bool {
        switch self {
        case .openAI: return true
        default: return false
        }
    }
}

// MARK: - Voice

enum TTSVoice: String, CaseIterable {
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
    
    var displayName: String {
        switch self {
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
        instructions: "Speak in a clear, neutral, and natural tone.",
        isBuiltIn: true
    )
    
    static let cheerful = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Cheerful",
        instructions: "Speak in a cheerful, upbeat, and positive tone with enthusiasm.",
        isBuiltIn: true
    )
    
    static let calm = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Calm & Soothing",
        instructions: "Speak in a calm, soothing, and relaxed tone. Slow pace, gentle delivery.",
        isBuiltIn: true
    )
    
    static let professional = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Professional",
        instructions: "Speak in a professional, authoritative, and confident tone suitable for business.",
        isBuiltIn: true
    )
    
    static let storyteller = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "Storyteller",
        instructions: "Speak like a captivating storyteller with expressive intonation, varied pacing, and emotional engagement.",
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
        guard let apiKey = KeychainHelper.getAPIKey(), !apiKey.isEmpty else {
            throw TTSError.noAPIKey
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TTSError.noTextSelected
        }
        
        let selectedVoice = voice ?? TTSService.selectedVoice
        let selectedPreset = preset ?? TTSService.selectedPreset
        
        // Build request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var requestBody: [String: Any] = [
            "model": model,
            "input": text,
            "voice": selectedVoice.rawValue,
            "response_format": "wav" // Low latency format
        ]
        
        // Add instructions from preset if not empty
        if !selectedPreset.instructions.isEmpty {
            requestBody["instructions"] = selectedPreset.instructions
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TTSError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                // Play the audio
                try await playAudio(data: data, onComplete: onComplete)
            } else {
                // Try to parse error
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
