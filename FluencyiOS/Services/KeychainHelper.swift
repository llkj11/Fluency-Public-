import Foundation

class KeychainHelper {
    enum APIKeyType {
        case openAI
        case gemini
        case groq
        
        var storageKey: String {
            switch self {
            case .openAI: return "com.fluency.ios.openai-api-key"
            case .gemini: return "com.fluency.ios.gemini-api-key"
            case .groq: return "com.fluency.ios.groq-api-key"
            }
        }
    }
    
    private static let defaults: UserDefaults = {
        // Use App Group for sharing with keyboard extension
        if let groupDefaults = UserDefaults(suiteName: "group.com.fluency.ios") {
            return groupDefaults
        }
        return UserDefaults.standard
    }()
    
    static func saveAPIKey(_ key: String, for type: APIKeyType = .openAI) {
        defaults.set(key, forKey: type.storageKey)
        defaults.synchronize()
        print("✅ API key saved for \(type)")
    }
    
    static func getAPIKey(for type: APIKeyType = .openAI) -> String? {
        return defaults.string(forKey: type.storageKey)
    }
    
    static func deleteAPIKey(for type: APIKeyType = .openAI) {
        defaults.removeObject(forKey: type.storageKey)
        defaults.synchronize()
    }
}
