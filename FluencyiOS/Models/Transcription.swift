import Foundation
import SwiftData

@Model
final class Transcription {
    var id: UUID
    var text: String
    var createdAt: Date
    var duration: TimeInterval
    var wordCount: Int
    
    // Sync metadata
    var isSynced: Bool
    var serverID: String?
    
    init(text: String, duration: TimeInterval) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.duration = duration
        self.wordCount = text.split(separator: " ").count
        self.isSynced = false
        self.serverID = nil
    }
}
