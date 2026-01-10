import SwiftUI
import AVFoundation

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Status Text
                    VStack(spacing: 8) {
                        Text(viewModel.statusTitle)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(viewModel.statusSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Waveform Visualization
                    WaveformView(audioLevel: viewModel.audioLevel, isRecording: viewModel.isRecording)
                        .frame(height: 100)
                        .padding(.horizontal, 40)
                    
                    // Record Button
                    Button {
                        viewModel.toggleRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? .red : .blue)
                                .frame(width: 100, height: 100)
                                .shadow(color: viewModel.isRecording ? .red.opacity(0.5) : .blue.opacity(0.5), radius: 20)
                            
                            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
                    
                    // Last Transcription Preview
                    if let lastTranscription = viewModel.lastTranscription {
                        VStack(spacing: 8) {
                            Text("Last Transcription")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(lastTranscription)
                                .font(.body)
                                .lineLimit(3)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            
                            Button {
                                UIPasteboard.general.string = lastTranscription
                                viewModel.showCopiedFeedback()
                            } label: {
                                Label(viewModel.justCopied ? "Copied!" : "Copy to Clipboard", systemImage: viewModel.justCopied ? "checkmark" : "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.justCopied ? .green : .blue)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Fluency")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
    }
}

// MARK: - ViewModel

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var audioLevel: Float = 0
    @Published var lastTranscription: String?
    @Published var justCopied = false
    
    var modelContext: ModelContext?
    
    private var audioRecorder: AudioRecorder?
    private var transcriptionService: TranscriptionService?
    private var recordingTimer: Timer?
    
    var statusTitle: String {
        if isTranscribing {
            return "Transcribing..."
        } else if isRecording {
            return "Listening..."
        } else {
            return "Ready to Dictate"
        }
    }
    
    var statusSubtitle: String {
        if isTranscribing {
            return "Processing your speech"
        } else if isRecording {
            return "Tap again to stop"
        } else {
            return "Tap the microphone to start"
        }
    }
    
    init() {
        audioRecorder = AudioRecorder()
        transcriptionService = TranscriptionService()
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecordingAndTranscribe()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        audioRecorder?.startRecording()
        
        // Update audio level periodically
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.audioLevel = self?.audioRecorder?.currentLevel ?? 0
            }
        }
    }
    
    private func stopRecordingAndTranscribe() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        isTranscribing = true
        
        guard let audioURL = audioRecorder?.stopRecording() else {
            isTranscribing = false
            return
        }
        
        let duration = audioRecorder?.recordingDuration ?? 0
        
        Task {
            do {
                let text = try await transcriptionService?.transcribe(audioURL: audioURL) ?? ""
                
                await MainActor.run {
                    self.lastTranscription = text
                    self.isTranscribing = false
                    
                    // Save to history
                    if let modelContext = self.modelContext {
                        let transcription = Transcription(text: text, duration: duration)
                        modelContext.insert(transcription)
                        
                        // Record stats
                        StatsService.shared.recordTranscription(wordCount: transcription.wordCount, duration: duration)
                        
                        // Sync to server
                        Task {
                            await SyncService.shared.syncTranscription(transcription)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isTranscribing = false
                    self.lastTranscription = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func showCopiedFeedback() {
        justCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.justCopied = false
        }
    }
}

// MARK: - Waveform Visualization

struct WaveformView: View {
    var audioLevel: Float
    var isRecording: Bool
    
    private let barCount = 30
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    height: barHeight(for: index),
                    isRecording: isRecording
                )
            }
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        guard isRecording else { return 0.1 }
        
        let normalizedLevel = CGFloat(max(0, min(1, audioLevel + 0.5)))
        let indexFactor = sin(Double(index) / Double(barCount) * .pi)
        let randomFactor = Double.random(in: 0.5...1.0)
        
        return normalizedLevel * CGFloat(indexFactor * randomFactor)
    }
}

struct WaveformBar: View {
    var height: CGFloat
    var isRecording: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 6, height: max(4, height * 80))
            .animation(.easeInOut(duration: 0.1), value: height)
    }
}

#Preview {
    HomeView()
}
