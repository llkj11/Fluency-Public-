import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transcription.createdAt, order: .reverse) private var transcriptions: [Transcription]
    
    @State private var searchText = ""
    @State private var selectedTranscription: Transcription?
    @State private var showingDetail = false
    
    var filteredTranscriptions: [Transcription] {
        if searchText.isEmpty {
            return transcriptions
        }
        return transcriptions.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTranscriptions) { transcription in
                    HistoryRow(transcription: transcription)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTranscription = transcription
                            showingDetail = true
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTranscription(transcription)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                UIPasteboard.general.string = transcription.text
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .tint(.blue)
                        }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search transcriptions")
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !transcriptions.isEmpty {
                        Menu {
                            Button(role: .destructive) {
                                deleteAllTranscriptions()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                            
                            Button {
                                Task {
                                    await SyncService.shared.syncAllTranscriptions(transcriptions)
                                }
                            } label: {
                                Label("Sync to Server", systemImage: "arrow.triangle.2.circlepath")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .overlay {
                if transcriptions.isEmpty {
                    ContentUnavailableView(
                        "No Transcriptions Yet",
                        systemImage: "text.bubble",
                        description: Text("Your transcriptions will appear here")
                    )
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let transcription = selectedTranscription {
                    TranscriptionDetailView(transcription: transcription)
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    private func deleteTranscription(_ transcription: Transcription) {
        modelContext.delete(transcription)
    }
    
    private func deleteAllTranscriptions() {
        for transcription in transcriptions {
            modelContext.delete(transcription)
        }
    }
}

struct HistoryRow: View {
    let transcription: Transcription
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(transcription.text)
                .font(.body)
                .lineLimit(2)
            
            HStack(spacing: 12) {
                Label(transcription.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                Label("\(transcription.wordCount) words", systemImage: "textformat.abc")
                
                if transcription.isSynced {
                    Image(systemName: "checkmark.icloud")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "icloud.slash")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TranscriptionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let transcription: Transcription
    @State private var isPlayingTTS = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Metadata
                    HStack(spacing: 20) {
                        MetadataItem(
                            icon: "clock",
                            title: "Created",
                            value: transcription.createdAt.formatted(date: .long, time: .shortened)
                        )
                        
                        MetadataItem(
                            icon: "textformat.abc",
                            title: "Words",
                            value: "\(transcription.wordCount)"
                        )
                        
                        MetadataItem(
                            icon: "waveform",
                            title: "Duration",
                            value: formatDuration(transcription.duration)
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // Transcription Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcription")
                            .font(.headline)
                        
                        Text(transcription.text)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = transcription.text
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            speakText()
                        } label: {
                            Label(isPlayingTTS ? "Stop" : "Listen", systemImage: isPlayingTTS ? "stop.fill" : "speaker.wave.2")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isPlayingTTS)
                    }
                    
                    // Share
                    ShareLink(item: transcription.text) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)m \(remainingSeconds)s"
    }
    
    private func speakText() {
        isPlayingTTS = true
        Task {
            do {
                try await TTSService.shared.speak(text: transcription.text)
                await MainActor.run {
                    isPlayingTTS = false
                }
            } catch {
                await MainActor.run {
                    isPlayingTTS = false
                }
            }
        }
    }
}

struct MetadataItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    HistoryView()
}
