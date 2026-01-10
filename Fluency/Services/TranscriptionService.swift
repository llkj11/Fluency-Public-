import Foundation
import Security

enum TranscriptionError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case apiError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your OpenAI API key in Settings."
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class TranscriptionService {
    private let endpoint = "https://api.openai.com/v1/audio/transcriptions"
    private let model = "gpt-4o-mini-transcribe"

    func transcribe(audioURL: URL) async throws -> String {
        guard let apiKey = KeychainHelper.getAPIKey(), !apiKey.isEmpty else {
            throw TranscriptionError.noAPIKey
        }

        let audioData = try Data(contentsOf: audioURL)
        let boundary = UUID().uuidString

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)

        // Add response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("text\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranscriptionError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                let text = String(data: data, encoding: .utf8) ?? ""
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                // Try to parse error
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw TranscriptionError.apiError(message)
                }
                throw TranscriptionError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as TranscriptionError {
            throw error
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
}

// MARK: - API Key Verification

extension TranscriptionService {
    /// Verifies the API key is valid by making a lightweight API call
    func verifyAPIKey(_ apiKey: String) async -> Result<Void, TranscriptionError> {
        let endpoint = "https://api.openai.com/v1/models"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            if httpResponse.statusCode == 200 {
                return .success(())
            } else if httpResponse.statusCode == 401 {
                return .failure(.apiError("Invalid API key"))
            } else {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return .failure(.apiError(message))
                }
                return .failure(.apiError("HTTP \(httpResponse.statusCode)"))
            }
        } catch {
            return .failure(.networkError(error))
        }
    }
}

// MARK: - API Key Storage (UserDefaults - persists with stable bundle ID)

class KeychainHelper {
    enum APIKeyType {
        case openAI
        case gemini
        
        var storageKey: String {
            switch self {
            case .openAI: return "com.fluency.openai-api-key"
            case .gemini: return "com.fluency.gemini-api-key"
            }
        }
    }
    
    static func saveAPIKey(_ key: String, for type: APIKeyType = .openAI) {
        UserDefaults.standard.set(key, forKey: type.storageKey)
        UserDefaults.standard.synchronize()
        print("✅ API key saved for \(type)")
    }
    
    static func getAPIKey(for type: APIKeyType = .openAI) -> String? {
        return UserDefaults.standard.string(forKey: type.storageKey)
    }
    
    static func deleteAPIKey(for type: APIKeyType = .openAI) {
        UserDefaults.standard.removeObject(forKey: type.storageKey)
        UserDefaults.standard.synchronize()
    }
}

