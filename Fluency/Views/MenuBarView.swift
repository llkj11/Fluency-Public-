import SwiftUI
import SwiftData

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    var openSettingsAction: (() -> Void)? = nil
    @Query(sort: \Transcription.createdAt, order: .reverse) private var transcriptions: [Transcription]

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header with status and settings
            header
            
            Divider()
            
            // Tab content
            TabView(selection: $selectedTab) {
                // Dashboard tab
                dashboardTab
                    .tag(0)
                
                // History tab
                historyTab
                    .tag(1)
            }
            .tabViewStyle(.automatic)
            
            // Tab bar
            tabBar
        }
        .frame(width: 320, height: 400)
        .onReceive(NotificationCenter.default.publisher(for: .newTranscription)) { notification in
            if let userInfo = notification.userInfo,
               let text = userInfo["text"] as? String,
               let duration = userInfo["duration"] as? TimeInterval {
                let transcription = Transcription(text: text, duration: duration)
                modelContext.insert(transcription)
                try? modelContext.save()
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(appState.isRecording ? "Recording..." : appState.isTranscribing ? "Transcribing..." : "Ready")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Settings button
            Button {
                openSettingsAction?()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Dashboard Tab
    
    private var dashboardTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats cards
                statsSection
                
                Divider()
                    .padding(.horizontal)
                
                // Quick tip
                quickTip
                
                // Recent (preview)
                if !transcriptions.isEmpty {
                    Divider()
                        .padding(.horizontal)
                    
                    recentPreview
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MiniStatCard(
                    value: "\(StatsService.shared.totalWords)",
                    label: "Words",
                    icon: "text.word.spacing",
                    color: .blue
                )
                
                MiniStatCard(
                    value: "\(StatsService.shared.totalTranscriptions)",
                    label: "Transcriptions",
                    icon: "waveform",
                    color: .purple
                )
            }
            
            HStack(spacing: 12) {
                MiniStatCard(
                    value: formatTime(StatsService.shared.totalDuration),
                    label: "Recorded",
                    icon: "clock",
                    color: .orange
                )
                
                MiniStatCard(
                    value: formatTime(StatsService.shared.estimatedTimeSaved),
                    label: "Time Saved",
                    icon: "bolt.fill",
                    color: .green
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var quickTip: some View {
        HStack(spacing: 10) {
            Text("fn")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.15))
                .cornerRadius(6)
            
            Text("Hold to record, release to transcribe")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private var recentPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("See All") {
                    selectedTab = 1
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            
            ForEach(transcriptions.prefix(2)) { transcription in
                CompactTranscriptionRow(transcription: transcription)
            }
        }
    }
    
    // MARK: - History Tab
    
    private var historyTab: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if transcriptions.isEmpty {
                    emptyHistoryView
                } else {
                    ForEach(transcriptions) { transcription in
                        TranscriptionRow(transcription: transcription)
                    }
                }
            }
            .padding(12)
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No transcriptions yet")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Text("Hold fn to start recording")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "Dashboard", icon: "square.grid.2x2", tag: 0)
            tabButton(title: "History", icon: "clock.arrow.circlepath", tag: 1)
            
            Spacer()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
        }
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03))
    }
    
    private func tabButton(title: String, icon: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: selectedTab == tag ? .medium : .regular))
            }
            .foregroundColor(selectedTab == tag ? .accentColor : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == tag ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        if appState.isRecording { return .red }
        else if appState.isTranscribing { return .orange }
        else { return .green }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            return "\(Int(seconds) / 60)m"
        } else {
            return "\(Int(seconds) / 3600)h"
        }
    }
}

// MARK: - Supporting Views

struct MiniStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }
}

struct CompactTranscriptionRow: View {
    let transcription: Transcription
    
    var body: some View {
        HStack {
            Text(transcription.text)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            Text(transcription.createdAt, style: .relative)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(transcription.text, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

struct TranscriptionRow: View {
    let transcription: Transcription
    @State private var isHovering = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(transcription.text)
                    .font(.system(size: 12))
                    .lineLimit(2)
                    .truncationMode(.tail)

                Text(transcription.createdAt, style: .relative)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isHovering {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(transcription.text, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState())
}
