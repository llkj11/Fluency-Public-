import SwiftUI
import SwiftData

@main
struct FluencyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Transcription.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }

        MenuBarExtra {
            MenuBarView(openSettingsAction: {
                appDelegate.openSettings()
            })
                .modelContainer(sharedModelContainer)
                .environmentObject(appDelegate.appState)
        } label: {
            Image(systemName: appDelegate.appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var overlayWindow: NSWindow?
    var overlayHostingView: NSHostingView<AnyView>?
    var speakingOverlayWindow: NSWindow?
    var speakingOverlayHostingView: NSHostingView<AnyView>?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupOverlayWindow()
        setupSpeakingOverlayWindow()
        appState.onRecordingStateChanged = { [weak self] isRecording in
            self?.updateOverlay(isRecording: isRecording)
        }
        appState.onSpeakingStateChanged = { [weak self] isSpeaking in
            self?.updateSpeakingOverlay(isSpeaking: isSpeaking)
        }
        appState.startServices()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.stopServices()
    }

    func openSettings() {
        if settingsWindow == nil {
            setupSettingsWindow()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupSettingsWindow() {
        let settingsView = SettingsView()
            .environmentObject(appState)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Fluency Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.isReleasedWhenClosed = false
        self.settingsWindow = window
    }

    private func setupOverlayWindow() {
        let overlay = AnyView(
            RecordingOverlay()
                .environmentObject(appState)
        )

        let hostingView = NSHostingView(rootView: overlay)
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 70)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 70),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        window.hasShadow = false // The overlay has its own shadow

        // Position at bottom center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.minY + 80
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.overlayWindow = window
        self.overlayHostingView = hostingView
    }
    
    private func setupSpeakingOverlayWindow() {
        let overlay = AnyView(
            SpeakingOverlay()
                .environmentObject(appState)
        )

        let hostingView = NSHostingView(rootView: overlay)
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 70)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 70),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        window.hasShadow = false

        // Position at bottom center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.minY + 80
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.speakingOverlayWindow = window
        self.speakingOverlayHostingView = hostingView
    }

    private func updateOverlay(isRecording: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.overlayWindow else { return }

            if isRecording || self?.appState.isTranscribing == true {
                window.orderFront(nil)
                window.alphaValue = 0
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    window.animator().alphaValue = 1
                }
            } else if !isRecording && self?.appState.isTranscribing == false {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    window.animator().alphaValue = 0
                }, completionHandler: {
                    window.orderOut(nil)
                })
            }
        }
    }
    
    private func updateSpeakingOverlay(isSpeaking: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.speakingOverlayWindow else { return }

            if isSpeaking {
                window.orderFront(nil)
                window.alphaValue = 0
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    window.animator().alphaValue = 1
                }
            } else {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    window.animator().alphaValue = 0
                }, completionHandler: {
                    window.orderOut(nil)
                })
            }
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var isSpeaking = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var statusMessage = "Ready"
    @Published var lastTranscription: String?
    @Published var audioLevel: Float = 0

    var onRecordingStateChanged: ((Bool) -> Void)?
    var onSpeakingStateChanged: ((Bool) -> Void)?

    private var hotkeyService: HotkeyService?
    private var audioRecorder: AudioRecorder?
    private var transcriptionService: TranscriptionService?
    private var pasteService: PasteService?
    private var textCaptureService: TextCaptureService?
    private var recordingTimer: Timer?

    func startServices() {
        audioRecorder = AudioRecorder()
        transcriptionService = TranscriptionService()
        pasteService = PasteService()
        textCaptureService = TextCaptureService()

        hotkeyService = HotkeyService(
            onRecordingStart: { [weak self] in
                Task { @MainActor in
                    self?.startRecording()
                }
            },
            onRecordingStop: { [weak self] in
                Task { @MainActor in
                    self?.stopRecordingAndTranscribe()
                }
            },
            onTTSTriggered: { [weak self] in
                Task { @MainActor in
                    self?.triggerTTS()
                }
            }
        )
        hotkeyService?.start()
    }

    func stopServices() {
        hotkeyService?.stop()
        _ = audioRecorder?.stopRecording()
        TTSService.shared.stopSpeaking()
    }
    
    // MARK: - TTS Methods
    
    private func triggerTTS() {
        guard !isSpeaking else {
            // If already speaking, stop
            stopTTS()
            return
        }
        
        // Capture selected text
        guard let selectedText = textCaptureService?.getSelectedText(),
              !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "No text selected"
            AudioFeedbackService.shared.playErrorSound()
            return
        }
        
        isSpeaking = true
        statusMessage = "Speaking..."
        onSpeakingStateChanged?(true)
        
        Task {
            do {
                try await TTSService.shared.speak(text: selectedText) { [weak self] in
                    Task { @MainActor in
                        self?.isSpeaking = false
                        self?.statusMessage = "Ready"
                        self?.onSpeakingStateChanged?(false)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSpeaking = false
                    self.statusMessage = "TTS Error: \(error.localizedDescription)"
                    self.onSpeakingStateChanged?(false)
                    AudioFeedbackService.shared.playErrorSound()
                }
            }
        }
    }
    
    func stopTTS() {
        TTSService.shared.stopSpeaking()
        isSpeaking = false
        statusMessage = "Ready"
        onSpeakingStateChanged?(false)
    }

    private func startRecording() {
        guard !isRecording else { return }

        isRecording = true
        recordingDuration = 0
        statusMessage = "Listening..."
        onRecordingStateChanged?(true)
        
        // Play start sound
        AudioFeedbackService.shared.playStartSound()

        audioRecorder?.startRecording()

        // Start duration timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 0.1
                self?.audioLevel = self?.audioRecorder?.currentLevel ?? 0
            }
        }
    }

    private func stopRecordingAndTranscribe() {
        guard isRecording else { return }

        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        isTranscribing = true
        statusMessage = "Transcribing..."
        onRecordingStateChanged?(false)
        
        // Play stop sound
        AudioFeedbackService.shared.playStopSound()

        guard let audioURL = audioRecorder?.stopRecording() else {
            isTranscribing = false
            statusMessage = "No audio recorded"
            onRecordingStateChanged?(false) // Trigger overlay dismiss
            return
        }

        Task {
            do {
                let text = try await transcriptionService?.transcribe(audioURL: audioURL) ?? ""
                await MainActor.run {
                    self.lastTranscription = text
                    self.statusMessage = "Done"
                    self.isTranscribing = false
                    self.onRecordingStateChanged?(false) // Trigger overlay dismiss

                    if !text.isEmpty {
                        self.pasteService?.paste(text: text)
                        self.saveTranscription(text: text, duration: self.recordingDuration)
                        AudioFeedbackService.shared.playSuccessSound()
                        
                        // Update stats
                        StatsService.shared.recordTranscription(
                            wordCount: text.split(separator: " ").count,
                            duration: self.recordingDuration
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    self.isTranscribing = false
                    self.onRecordingStateChanged?(false) // Trigger overlay dismiss
                    AudioFeedbackService.shared.playErrorSound()
                }
            }

            // Clean up temp file
            try? FileManager.default.removeItem(at: audioURL)
        }
    }

    private func saveTranscription(text: String, duration: TimeInterval) {
        // SwiftData save handled by the view's modelContext
        NotificationCenter.default.post(
            name: .newTranscription,
            object: nil,
            userInfo: ["text": text, "duration": duration]
        )
    }
}

extension Notification.Name {
    static let newTranscription = Notification.Name("newTranscription")
}
