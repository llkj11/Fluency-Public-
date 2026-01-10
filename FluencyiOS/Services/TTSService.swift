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
            return "No text selected."
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
    
    var isAvailable: Bool {
        switch self {
        case .openAI, .gemini: return true
        }
    }
}

// MARK: - Voice

enum TTSVoice: String, CaseIterable {
    // OpenAI Voices
    case alloy = "alloy"
    case ash = "ash"
    case coral = "coral"
    case echo = "echo"
    case marin = "marin"
    case cedar = "cedar"
    case nova = "nova"
    case sage = "sage"
    case shimmer = "shimmer"
    
    // Gemini Voices
    case zephyr = "Zephyr"
    case puck = "Puck"
    case kore = "Kore"
    case aoede = "Aoede"
    
    var displayName: String {
        switch self {
        case .alloy: return "Alloy"
        case .ash: return "Ash"
        case .coral: return "Coral"
        case .echo: return "Echo"
        case .marin: return "Marin ⭐"
        case .cedar: return "Cedar ⭐"
        case .nova: return "Nova"
        case .sage: return "Sage"
        case .shimmer: return "Shimmer"
        default: return self.rawValue
        }
    }
    
    var provider: TTSProvider {
        switch self {
        case .alloy, .ash, .coral, .echo, .marin, .cedar, .nova, .sage, .shimmer:
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
    
    static let neutral = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Neutral",
        instructions: "Speak in a clear, natural, and balanced tone.",
        isBuiltIn: true
    )
    
    static let cheerful = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Cheerful",
        instructions: "Speak with a bright, sunny tone. High energy and inviting.",
        isBuiltIn: true
    )
    
    static let calm = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Calm",
        instructions: "Warm, gentle, and reassuring. Slow and measured pace.",
        isBuiltIn: true
    )
    
    static let professional = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Professional",
        instructions: "Corporate, authoritative. Crisp articulation, steady pace.",
        isBuiltIn: true
    )
    
    static let auto = VoicePreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000099")!,
        name: "✨ Auto",
        instructions: "",
        isBuiltIn: true
    )
    
    static var builtInPresets: [VoicePreset] {
        [.neutral, .cheerful, .calm, .professional, .auto]
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
    private static let voiceKey = "com.fluency.ios.tts-voice"
    private static let providerKey = "com.fluency.ios.tts-provider"
    private static let presetIdKey = "com.fluency.ios.tts-preset-id"
    
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
    
    static var selectedVoice: TTSVoice {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: voiceKey),
               let voice = TTSVoice(rawValue: rawValue) {
                return voice
            }
            return .coral
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: voiceKey)
        }
    }
    
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
    
    func speak(text: String, voice: TTSVoice? = nil, preset: VoicePreset? = nil, onComplete: (() -> Void)? = nil) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TTSError.noTextSelected
        }
        
        let selectedVoice = voice ?? TTSService.selectedVoice
        let selectedPreset = preset ?? VoicePreset.builtInPresets.first { $0.id == TTSService.selectedPresetId } ?? .neutral
        
        if selectedVoice.provider == .gemini {
            try await speakGemini(text: text, voice: selectedVoice, preset: selectedPreset, onComplete: onComplete)
        } else {
            try await speakOpenAI(text: text, voice: selectedVoice, preset: selectedPreset, onComplete: onComplete)
        }
    }
    
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
            "response_format": "mp3"
        ]
        
        if !preset.instructions.isEmpty {
            requestBody["instructions"] = preset.instructions
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TTSError.invalidResponse
        }
        
        try await playAudio(data: data, onComplete: onComplete)
    }
    
    private func speakGemini(text: String, voice: TTSVoice, preset: VoicePreset, onComplete: (() -> Void)?) async throws {
        guard let apiKey = KeychainHelper.getAPIKey(for: .gemini), !apiKey.isEmpty else {
            throw TTSError.apiError("No Gemini API key")
        }
        
        let geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent"
        
        var promptText = text
        if !preset.instructions.isEmpty {
            promptText = "### DIRECTOR'S NOTES\n\(preset.instructions)\n\n### TRANSCRIPT\n\(text)"
        }
        
        var request = URLRequest(url: URL(string: geminiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": promptText]]]],
            "generationConfig": [
                "responseModalities": ["AUDIO"],
                "speechConfig": [
                    "voiceConfig": ["prebuiltVoiceConfig": ["voiceName": voice.rawValue]]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TTSError.invalidResponse
        }
        
        // Parse Gemini response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let inlineData = firstPart["inlineData"] as? [String: Any],
              let base64String = inlineData["data"] as? String,
              let audioData = Data(base64Encoded: base64String) else {
            throw TTSError.invalidResponse
        }
        
        // Wrap PCM in WAV
        let wavData = createWavData(from: audioData)
        try await playAudio(data: wavData, onComplete: onComplete)
    }
    
    private func createWavData(from pcmData: Data) -> Data {
        let sampleRate: Int32 = 24000
        let channels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = sampleRate * Int32(channels * bitsPerSample / 8)
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = Int32(pcmData.count)
        let chunkSize = 36 + dataSize
        
        var header = Data()
        header.append("RIFF".data(using: .ascii)!)
        withUnsafeBytes(of: chunkSize.littleEndian) { header.append(contentsOf: $0) }
        header.append("WAVE".data(using: .ascii)!)
        header.append("fmt ".data(using: .ascii)!)
        withUnsafeBytes(of: Int32(16).littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: Int16(1).littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: channels.littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: sampleRate.littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: byteRate.littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: blockAlign.littleEndian) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: bitsPerSample.littleEndian) { header.append(contentsOf: $0) }
        header.append("data".data(using: .ascii)!)
        withUnsafeBytes(of: dataSize.littleEndian) { header.append(contentsOf: $0) }
        
        return header + pcmData
    }
    
    private func playAudio(data: Data, onComplete: (() -> Void)?) async throws {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            self.onPlaybackComplete = onComplete
            
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
}
