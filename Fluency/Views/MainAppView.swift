import SwiftUI
import SwiftData

struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transcription.createdAt, order: .reverse) private var transcriptions: [Transcription]
    
    @State private var serverStats: StatsService.ServerStats?
    @State private var wordStats: StatsService.WordStats?
    @State private var selectedTab = 0
    @State private var showingWordsDetail = false
    @State private var showingTranscriptionsDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Stylized Header
            header
            
            Divider()
            
            // Main Content
            TabView(selection: $selectedTab) {
                dashboardView
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    .tag(0)
                
                historyView
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(1)
                
                wordsView
                    .tabItem {
                        Label("Words", systemImage: "textformat.abc")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
        }
        .frame(minWidth: 650, minHeight: 550)
        .task {
            serverStats = await StatsService.shared.fetchStats()
            wordStats = await StatsService.shared.fetchWordStats()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Spacer()
            
            // Stylized "Fluency" title
            HStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Fluency")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Spacer()
        }
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Dashboard View
    
    private var dashboardView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Stats Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    Button {
                        showingWordsDetail = true
                    } label: {
                        MainStatCard(
                            title: "Words Dictated",
                            value: "\(serverStats?.totalWords ?? 0)",
                            icon: "text.word.spacing",
                            color: .blue
                        )
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingWordsDetail) {
                        WordsDetailView()
                    }
                    
                    Button {
                        showingTranscriptionsDetail = true
                    } label: {
                        MainStatCard(
                            title: "Transcriptions",
                            value: "\(serverStats?.totalTranscriptions ?? 0)",
                            icon: "waveform",
                            color: .purple
                        )
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingTranscriptionsDetail) {
                        TranscriptionsDetailView()
                    }
                    
                    MainStatCard(
                        title: "Time Recorded",
                        value: formatDuration(serverStats?.totalDuration ?? 0),
                        icon: "clock",
                        color: .orange
                    )
                    
                    MainStatCard(
                        title: "Time Saved",
                        value: formatDuration(StatsService.shared.estimatedTimeSaved),
                        icon: "bolt.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Recent Transcriptions Preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Transcriptions")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("See All") {
                            selectedTab = 1
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal)
                    
                    if transcriptions.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(transcriptions.prefix(5)) { transcription in
                            TranscriptionCard(transcription: transcription)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - History View
    
    private var historyView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if transcriptions.isEmpty {
                    emptyStateView
                } else {
                    ForEach(transcriptions) { transcription in
                        TranscriptionCard(transcription: transcription)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Words View
    
    private var wordsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Word stats header
                HStack(spacing: 24) {
                    VStack(alignment: .leading) {
                        Text("\(wordStats?.totalWords ?? 0)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Total Words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(wordStats?.uniqueWords ?? 0)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Unique Words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Divider()
                
                Text("Top Words")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(wordStats?.topWords.prefix(50) ?? []) { word in
                        WordBubble(word: word.word, count: word.count)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No transcriptions yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Hold fn to start recording")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(mins)m \(secs)s"
        } else {
            let hours = Int(seconds) / 3600
            let mins = (Int(seconds) % 3600) / 60
            return "\(hours)h \(mins)m"
        }
    }
}

// MARK: - Supporting Views

struct MainStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TranscriptionCard: View {
    let transcription: Transcription
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transcription.text)
                    .font(.body)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(transcription.createdAt, style: .relative)
                    Text("•")
                    Text("\(transcription.wordCount) words")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isHovering {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(transcription.text, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovering ? Color.primary.opacity(0.05) : Color.primary.opacity(0.02))
        )
        .padding(.horizontal)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct WordBubble: View {
    let word: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(word)
                .font(.system(size: 12, weight: .medium))
            
            Text("\(count)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
}

#Preview {
    MainAppView()
}
