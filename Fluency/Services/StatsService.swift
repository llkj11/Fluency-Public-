import Foundation

/// Service for fetching stats from the remote server (single source of truth)
class StatsService {
    static let shared = StatsService()
    
    private let serverURLKey = "com.fluency.serverURL"
    
    var serverURL: String {
        get { UserDefaults.standard.string(forKey: serverURLKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: serverURLKey) }
    }

    /// Returns true if sync is enabled (server URL is configured)
    var isSyncEnabled: Bool {
        !serverURL.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var baseURL: String {
        "http://\(serverURL):7006/api/fluency"
    }
    
    // MARK: - Cached Values (for UI responsiveness)
    
    private var cachedStats: ServerStats?
    private var cacheTime: Date?
    private let cacheTTL: TimeInterval = 5 // 5 seconds
    
    // MARK: - Data Models
    
    struct ServerStats: Codable {
        let totalWords: Int
        let totalTranscriptions: Int
        let totalDuration: Double
    }
    
    struct ServerTranscription: Codable, Identifiable {
        let id: String
        let text: String
        let createdAt: String
        let duration: Double
        let wordCount: Int
        let device: String?
    }
    
    struct WordStats: Codable {
        let totalWords: Int
        let uniqueWords: Int
        let topWords: [WordEntry]
        let allWords: [WordEntry]
    }
    
    struct WordEntry: Codable, Identifiable {
        let word: String
        let count: Int
        var id: String { word }
    }
    
    // MARK: - Computed Properties (for backward compatibility)
    
    var totalWords: Int {
        cachedStats?.totalWords ?? 0
    }
    
    var totalTranscriptions: Int {
        cachedStats?.totalTranscriptions ?? 0
    }
    
    var totalDuration: TimeInterval {
        cachedStats?.totalDuration ?? 0
    }
    
    var estimatedTimeSaved: TimeInterval {
        let typingWPM = 40.0
        let speakingWPM = 150.0
        let wordsPerMinute = Double(totalWords)
        
        let typingTime = wordsPerMinute / typingWPM * 60
        let speakingTime = wordsPerMinute / speakingWPM * 60
        
        return max(0, typingTime - speakingTime)
    }
    
    // MARK: - Fetch Stats from Server
    
    func fetchStats() async -> ServerStats? {
        // Return cached if fresh
        if let cached = cachedStats, let time = cacheTime,
           Date().timeIntervalSince(time) < cacheTTL {
            return cached
        }
        
        guard let url = URL(string: "\(baseURL)/stats") else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }
            
            let stats = try JSONDecoder().decode(ServerStats.self, from: data)
            cachedStats = stats
            cacheTime = Date()
            return stats
        } catch {
            print("Failed to fetch stats: \(error)")
            return nil
        }
    }
    
    // MARK: - Fetch Transcriptions
    
    func fetchTranscriptions() async -> [ServerTranscription] {
        guard let url = URL(string: "\(baseURL)/transcriptions") else { return [] }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return [] }
            
            let transcriptions = try JSONDecoder().decode([ServerTranscription].self, from: data)
            return transcriptions
        } catch {
            print("Failed to fetch transcriptions: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Word Stats
    
    func fetchWordStats() async -> WordStats? {
        guard let url = URL(string: "\(baseURL)/words") else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }
            
            let wordStats = try JSONDecoder().decode(WordStats.self, from: data)
            return wordStats
        } catch {
            print("Failed to fetch word stats: \(error)")
            return nil
        }
    }
    
    // MARK: - Record Transcription (sends to server)
    
    func recordTranscription(wordCount: Int, duration: TimeInterval) {
        // Stats are now derived from transcriptions on the server
        // This method is kept for backward compatibility but does nothing locally
        // The actual sync happens in SyncService.syncTranscription()
        
        // Invalidate cache so next fetch gets fresh data
        cachedStats = nil
        cacheTime = nil
    }
    
    // MARK: - Refresh Cache
    
    func refreshCache() async {
        _ = await fetchStats()
    }
}
