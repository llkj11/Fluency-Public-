import SwiftUI

struct StatsView: View {
    @State private var stats = StatsService.shared
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatRow(
                        icon: "textformat.abc",
                        title: "Total Words",
                        value: "\(stats.totalWords)",
                        color: .blue
                    )
                    
                    StatRow(
                        icon: "waveform",
                        title: "Transcriptions",
                        value: "\(stats.totalTranscriptions)",
                        color: .purple
                    )
                    
                    StatRow(
                        icon: "clock",
                        title: "Recording Time",
                        value: formatDuration(stats.totalDuration),
                        color: .orange
                    )
                } header: {
                    Text("Usage")
                }
                
                Section {
                    StatRow(
                        icon: "calendar",
                        title: "Days Active",
                        value: "\(stats.daysActive)",
                        color: .green
                    )
                    
                    StatRow(
                        icon: "timer",
                        title: "Time Saved",
                        value: formatDuration(stats.estimatedTimeSaved),
                        color: .mint
                    )
                    
                    if let firstUse = stats.firstUseDate {
                        StatRow(
                            icon: "star",
                            title: "First Use",
                            value: firstUse.formatted(date: .abbreviated, time: .omitted),
                            color: .yellow
                        )
                    }
                } header: {
                    Text("Insights")
                }
                
                Section {
                    // Server sync status
                    HStack {
                        Label("Server", systemImage: "server.rack")
                        Spacer()
                        Text(SyncService.shared.isConnected ? "Connected" : "Disconnected")
                            .foregroundColor(SyncService.shared.isConnected ? .green : .secondary)
                        Circle()
                            .fill(SyncService.shared.isConnected ? .green : .orange)
                            .frame(width: 8, height: 8)
                    }
                    
                    Button {
                        Task {
                            await SyncService.shared.fetchStats()
                            refreshTrigger.toggle()
                        }
                    } label: {
                        Label("Sync Stats", systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text("Sync")
                }
                
                Section {
                    Button(role: .destructive) {
                        stats.resetStats()
                        refreshTrigger.toggle()
                    } label: {
                        Label("Reset Stats", systemImage: "trash")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Stats")
            .refreshable {
                await SyncService.shared.fetchStats()
                refreshTrigger.toggle()
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StatsView()
}
