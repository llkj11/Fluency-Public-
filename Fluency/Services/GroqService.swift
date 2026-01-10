import Foundation

enum GroqError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No Groq API key configured. Please add it in Settings."
        case .invalidResponse:
            return "Invalid response from Groq API"
        case .apiError(let message):
            return "Groq API Error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class GroqService {
    static let shared = GroqService()
    
    private let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    private let model = "moonshotai/kimi-k2-instruct-0905" // Fast, capable model
    
    // System prompt designed to produce concise style instructions
    private let systemPrompt = """
You are an expert audio director. Analyze the following text and provide concise "Director's Notes" for a TTS AI to read it aloud.
Focus on: Style, Pace, and Tone.
Format your response as a single concise string.
Example: "Style: Joyful and upbeat. Pace: Brisk. Tone: Warm."
Do NOT output anything else.
"""
    
    func analyzeTone(text: String) async throws -> String {
        guard let apiKey = KeychainHelper.getAPIKey(for: .groq), !apiKey.isEmpty else {
            throw GroqError.noAPIKey
        }
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3, // Lower temperature for consistent formatting
            "max_tokens": 100
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GroqError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                // Parse response
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    throw GroqError.invalidResponse
                }
                
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
                
            } else {
                // Try to parse error
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw GroqError.apiError(message)
                }
                throw GroqError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as GroqError {
            throw error
        } catch {
            throw GroqError.networkError(error)
        }
    }
    
    // MARK: - API Key Verification
    
    func verifyAPIKey(_ apiKey: String) async -> Result<Void, GroqError> {
        // Use the models endpoint to verify the key
        let modelsEndpoint = "https://api.groq.com/openai/v1/models"
        
        var request = URLRequest(url: URL(string: modelsEndpoint)!)
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
