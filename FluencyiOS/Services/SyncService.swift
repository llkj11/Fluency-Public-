import Foundation

/// Service for syncing transcriptions and stats to the server at 10.69.1.250
class SyncService {
    static let shared = SyncService()
    
    private let defaults: UserDefaults
    private let serverURLKey = "com.fluency.ios.serverURL"
    
    var isConnected = false
    
    var serverURL: String {
        get {
            defaults.string(forKey: serverURLKey) ?? "10.69.1.250"
        }
        set {
            defaults.set(newValue, forKey: serverURLKey)
        }
    }
    
    private var baseURL: String {
        "http://\(serverURL):8787/api/fluency"
    }
    
    init() {
        if let groupDefaults = UserDefaults(suiteName: "group.com.fluency.ios") {
            defaults = groupDefaults
        } else {
            defaults = UserDefaults.standard
        }
    }
    
    // MARK: - Connection Test
    
    func testConnection() async -> Bool {
        guard let url = URL(string: "\(baseURL)/ping") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
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
        guard await testConnection() else { return }
        
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
            "device": "ios"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // Parse server response for ID
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let serverID = json["id"] as? String {
                    transcription.serverID = serverID
                    transcription.isSynced = true
                    print("✅ Transcription synced: \(serverID)")
                }
            }
        } catch {
            print("Sync failed: \(error)")
        }
    }
    
    // MARK: - Sync All Transcriptions
    
    func syncAllTranscriptions(_ transcriptions: [Transcription]) async {
        for transcription in transcriptions where !transcription.isSynced {
            await syncTranscription(transcription)
        }
    }
    
    // MARK: - Fetch Stats from Server
    
    func fetchStats() async {
        guard await testConnection() else { return }
        
        guard let url = URL(string: "\(baseURL)/stats") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Update local stats if server has more
                    if let serverWords = json["totalWords"] as? Int,
                       serverWords > StatsService.shared.totalWords {
                        // Server has more data (from Mac), could merge here
                        print("📊 Server stats: \(serverWords) words")
                    }
                }
            }
        } catch {
            print("Fetch stats failed: \(error)")
        }
    }
    
    // MARK: - Sync Stats to Server
    
    func syncStats() async {
        guard await testConnection() else { return }
        
        guard let url = URL(string: "\(baseURL)/stats") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let stats = StatsService.shared
        let payload: [String: Any] = [
            "totalWords": stats.totalWords,
            "totalTranscriptions": stats.totalTranscriptions,
            "totalDuration": stats.totalDuration,
            "device": "ios"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Stats synced to server")
            }
        } catch {
            print("Stats sync failed: \(error)")
        }
    }
}
