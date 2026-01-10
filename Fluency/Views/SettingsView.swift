import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var showingAPIKey = false
    @State private var launchAtLogin = false
    @State private var showSaveConfirmation = false
    @State private var selectedProvider: TranscriptionProvider = .openAI
    @State private var selectedVoice: TTSVoice = TTSService.selectedVoice
    @State private var selectedTTSProvider: TTSProvider = TTSService.selectedProvider
    @State private var selectedPresetId: UUID = TTSService.selectedPresetId
    @State private var isPreviewingVoice = false
    @State private var showingPresetMaker = false
    @State private var customPresets: [VoicePreset] = TTSService.customPresets
    
    // API Verification states
    @State private var isVerifying = false
    @State private var verificationResult: VerificationResult?
    
    enum VerificationResult {
        case success
        case failure(String)
    }
    
    enum TranscriptionProvider: String, CaseIterable {
        case openAI = "OpenAI"
        case placeholder1 = "Provider 2 (Coming Soon)"
        case placeholder2 = "Provider 3 (Coming Soon)"
        case placeholder3 = "Provider 4 (Coming Soon)"
        case placeholder4 = "Provider 5 (Coming Soon)"
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Key")
                        .font(.headline)

                    HStack {
                        if showingAPIKey {
                            TextField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: apiKey) { _, newValue in
                                    autoSaveAPIKey(newValue)
                                }
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: apiKey) { _, newValue in
                                    autoSaveAPIKey(newValue)
                                }
                        }

                        Button {
                            showingAPIKey.toggle()
                        } label: {
                            Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }

                    HStack {
                        if !apiKey.isEmpty {
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("Enter your API key above")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Verify") {
                            verifyAPIKey()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(apiKey.isEmpty || isVerifying)

                        if !apiKey.isEmpty {
                            Button("Clear", role: .destructive) {
                                clearAPIKey()
                            }
                        }
                        
                        if isVerifying {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    if showSaveConfirmation {
                        Label("API key saved", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    if let result = verificationResult {
                        switch result {
                        case .success:
                            Label("API key is valid!", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        case .failure(let error):
                            Label(error, systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            } header: {
                Text("API Configuration")
            } footer: {
                Link("Get an API key from OpenAI", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .font(.caption)
            }
            
            Section {
                Picker("Transcription Provider", selection: $selectedProvider) {
                    ForEach(TranscriptionProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue)
                            .tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .disabled(selectedProvider != .openAI) // Only OpenAI works for now
            } header: {
                Text("Provider")
            } footer: {
                Text("More providers coming soon!")
                    .font(.caption)
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            } header: {
                Text("General")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // TTS Provider
                    Picker("Provider", selection: $selectedTTSProvider) {
                        ForEach(TTSProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue)
                                .tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!selectedTTSProvider.isAvailable)
                    .onChange(of: selectedTTSProvider) { _, newValue in
                        if newValue.isAvailable {
                            TTSService.selectedProvider = newValue
                        }
                    }
                    
                    Divider()
                    
                    // Voice selection
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(TTSVoice.allCases, id: \.self) { voice in
                            Text(voice.displayName)
                                .tag(voice)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedVoice) { _, newValue in
                        TTSService.selectedVoice = newValue
                    }
                    
                    // Voice Preset
                    HStack {
                        Text("Style")
                        Spacer()
                        Picker("", selection: $selectedPresetId) {
                            ForEach(VoicePreset.builtInPresets, id: \.id) { preset in
                                Text(preset.name).tag(preset.id)
                            }
                            if !customPresets.isEmpty {
                                Divider()
                                ForEach(customPresets, id: \.id) { preset in
                                    Text("\(preset.name) ✎").tag(preset.id)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 180)
                        .onChange(of: selectedPresetId) { _, newValue in
                            TTSService.selectedPresetId = newValue
                        }
                    }
                    
                    // Current preset info
                    let currentPreset = (VoicePreset.builtInPresets + customPresets).first { $0.id == selectedPresetId } ?? .neutral
                    Text(currentPreset.instructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Divider()
                    
                    // Actions row
                    HStack {
                        Button {
                            showingPresetMaker = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("New Style")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        // Delete custom preset button
                        if !currentPreset.isBuiltIn {
                            Button(role: .destructive) {
                                deletePreset(currentPreset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        Spacer()
                        
                        Button {
                            previewVoice()
                        } label: {
                            HStack(spacing: 4) {
                                if isPreviewingVoice {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text("Preview")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(apiKey.isEmpty || isPreviewingVoice)
                    }
                    
                    Text("Shortcut: Hold Fn + Press Control")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Text-to-Speech")
            } footer: {
                Text("⭐ Marin and Cedar are recommended. Styles control tone, speed, and emotion.")
                    .font(.caption)
            }
            
            Section {
                StatsView()
            } header: {
                Text("Your Stats")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Use")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        InstructionRow(number: 1, text: "Set 'Press 🌐 key to' → 'Do Nothing' in System Settings → Keyboard")
                        InstructionRow(number: 2, text: "Click in any text field")
                        InstructionRow(number: 3, text: "Hold the Fn key and speak → release to transcribe (STT)")
                        InstructionRow(number: 4, text: "Select text anywhere, then Fn + Control → speaks text (TTS)")
                    }
                }
            } header: {
                Text("Instructions")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    PermissionRow(
                        title: "Microphone",
                        description: "Required to record your voice",
                        systemImage: "mic",
                        action: openMicrophoneSettings
                    )

                    PermissionRow(
                        title: "Accessibility",
                        description: "Required for hotkey detection and text paste",
                        systemImage: "accessibility",
                        action: openAccessibilitySettings
                    )
                }
            } header: {
                Text("Permissions")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 550)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadSettings()
        }
        .sheet(isPresented: $showingPresetMaker) {
            PresetMakerView { newPreset in
                TTSService.addCustomPreset(newPreset)
                customPresets = TTSService.customPresets
                selectedPresetId = newPreset.id
                TTSService.selectedPresetId = newPreset.id
            }
        }
    }

    private func loadSettings() {
        if let key = KeychainHelper.getAPIKey() {
            apiKey = key
        }
        // Check launch at login status
        launchAtLogin = SMAppService.mainApp.status == .enabled
        // Load TTS settings
        selectedVoice = TTSService.selectedVoice
        selectedTTSProvider = TTSService.selectedProvider
        selectedPresetId = TTSService.selectedPresetId
        customPresets = TTSService.customPresets
    }
    
    private func autoSaveAPIKey(_ key: String) {
        // Auto-save when the key changes (debounced effectively by onChange)
        if !key.isEmpty {
            KeychainHelper.saveAPIKey(key)
        }
        verificationResult = nil
    }

    private func saveAPIKey() {
        KeychainHelper.saveAPIKey(apiKey)
        showSaveConfirmation = true
        verificationResult = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSaveConfirmation = false
        }
    }
    
    private func verifyAPIKey() {
        isVerifying = true
        verificationResult = nil
        
        Task {
            let service = TranscriptionService()
            let result = await service.verifyAPIKey(apiKey)
            
            await MainActor.run {
                isVerifying = false
                switch result {
                case .success:
                    verificationResult = .success
                case .failure(let error):
                    verificationResult = .failure(error.localizedDescription)
                }
                
                // Auto-hide result after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    verificationResult = nil
                }
            }
        }
    }

    private func clearAPIKey() {
        KeychainHelper.deleteAPIKey()
        apiKey = ""
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }

    private func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func previewVoice() {
        isPreviewingVoice = true
        
        let currentPreset = (VoicePreset.builtInPresets + customPresets).first { $0.id == selectedPresetId } ?? .neutral
        
        Task {
            do {
                try await TTSService.shared.speak(
                    text: "Hello! This is how I sound with this style. I'm ready to read text for you.",
                    voice: selectedVoice,
                    preset: currentPreset
                ) {
                    Task { @MainActor in
                        isPreviewingVoice = false
                    }
                }
            } catch {
                await MainActor.run {
                    isPreviewingVoice = false
                }
                print("Voice preview failed: \(error)")
            }
        }
    }
    
    private func deletePreset(_ preset: VoicePreset) {
        TTSService.deleteCustomPreset(preset)
        customPresets = TTSService.customPresets
        selectedPresetId = TTSService.selectedPresetId
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 12))
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Open Settings") {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preset Maker View

struct PresetMakerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var presetName: String = ""
    @State private var instructions: String = ""
    
    let onSave: (VoicePreset) -> Void
    
    private let exampleInstructions = [
        "Speak slowly and calmly, with a gentle tone.",
        "Speak with excitement and high energy!",
        "Speak in a whisper, very softly.",
        "Speak like a news anchor, professional and clear.",
        "Speak with a British accent, formal and refined.",
        "Speak quickly with urgency.",
        "Speak warmly, like talking to a close friend."
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Voice Style")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("My Custom Style", text: $presetName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Voice Instructions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $instructions)
                    .font(.body)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text("Describe how the voice should sound: tone, speed, accent, emotion, etc.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Examples (tap to use)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                FlowLayout(spacing: 6) {
                    ForEach(exampleInstructions, id: \.self) { example in
                        Button {
                            instructions = example
                        } label: {
                            Text(example)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save") {
                    let preset = VoicePreset(
                        name: presetName.isEmpty ? "Custom Style" : presetName,
                        instructions: instructions
                    )
                    onSave(preset)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(instructions.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 380)
    }
}

// Simple flow layout for example buttons
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), frames)
    }
}

#Preview {
    SettingsView()
}
