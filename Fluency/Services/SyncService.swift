import Foundation

/// Service for syncing transcriptions and stats to a local server
/// Server sync is disabled by default. Configure a server URL in Settings to enable.
class SyncService {
    static let shared = SyncService()

    private let serverURLKey = "com.fluency.serverURL"
    var isConnected = false

    var serverURL: String {
        get {
            UserDefaults.standard.string(forKey: serverURLKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: serverURLKey)
        }
    }

    /// Returns true if sync is enabled (server URL is configured)
    var isSyncEnabled: Bool {
        !serverURL.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var baseURL: String {
        "http://\(serverURL):7006/api/fluency"
    }
    
    // MARK: - Connection Test

    func testConnection() async -> Bool {
        guard isSyncEnabled else { return false }
        guard let url = URL(string: "\(baseURL)/ping") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                isConnected = httpResponse.statusCode == 200
                return isConnected
            }
        } catch {
            print("Server connection failed: \(error)")
        }
        
        isConnected = false
        return false
    }
    
    // MARK: - Sync Transcription

    func syncTranscription(_ transcription: Transcription) async {
        guard isSyncEnabled, await testConnection() else { return }
        
        guard let url = URL(string: "\(baseURL)/transcriptions") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "id": transcription.id.uuidString,
            "text": transcription.text,
            "createdAt": ISO8601DateFormatter().string(from: transcription.createdAt),
            "duration": transcription.duration,
            "wordCount": transcription.wordCount,
            "device": "mac"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let serverID = json["id"] as? String {
                    transcription.serverID = serverID
                    transcription.isSynced = true
                    print("✅ macOS Transcription synced: \(serverID)")
                }
            }
        } catch {
            print("macOS Sync failed: \(error)")
        }
    }
    
    // MARK: - Sync Stats

    func syncStats() async {
        guard isSyncEnabled, await testConnection() else { return }
        
        guard let url = URL(string: "\(baseURL)/stats") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let stats = StatsService.shared
        let payload: [String: Any] = [
            "totalWords": stats.totalWords,
            "totalTranscriptions": stats.totalTranscriptions,
            "totalDuration": stats.totalDuration,
            "device": "mac"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ macOS Stats synced to server")
            }
        } catch {
            print("macOS Stats sync failed: \(error)")
        }
    }
}
