import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager

    @State private var apiKey: String = ""
    @State private var geminiAPIKey: String = ""
    @State private var showingAPIKey = false
    @State private var showingGeminiAPIKey = false
    @State private var showingGroqAPIKey = false
    @State private var groqAPIKey: String = ""
    @State private var launchAtLogin = false
    @State private var showSaveConfirmation = false
    @State private var selectedProvider: TranscriptionProvider = .openAI
    @State private var selectedVoice: TTSVoice = TTSService.selectedVoice
    @State private var selectedTTSProvider: TTSProvider = TTSService.selectedProvider
    @State private var selectedPresetId: UUID = TTSService.selectedPresetId
    @State private var isPreviewingVoice = false
    @State private var customPresets: [VoicePreset] = TTSService.customPresets
    
    // API Verification states
    @State private var isVerifying = false
    @State private var isVerifyingGemini = false
    @State private var isVerifyingGroq = false
    @State private var verificationResult: VerificationResult?
    @State private var geminiVerificationResult: VerificationResult?
    @State private var groqVerificationResult: VerificationResult?
    
    // Lock States (Prevent accidental edits)
    @State private var isOpenAILocked = true
    @State private var isGeminiLocked = true
    
    // Server connection state
    @State private var isServerConnected = false
    @State private var isTestingConnection = false
    @State private var isGroqLocked = true
    
    enum VerificationResult {
        case success
        case failure(String)
    }
    
    enum TranscriptionProvider: String, CaseIterable {
        case openAI = "GPT-4o Mini Transcribe"
        case provider2 = "Provider 2 (Coming Soon)"
        case provider3 = "Provider 3 (Coming Soon)"
        case provider4 = "Provider 4 (Coming Soon)"
        case provider5 = "Provider 5 (Coming Soon)"
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
                                    autoSaveAPIKey(newValue, type: .openAI)
                                }
                                .disabled(isOpenAILocked)
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: apiKey) { _, newValue in
                                    autoSaveAPIKey(newValue, type: .openAI)
                                }
                                .disabled(isOpenAILocked)
                        }

                        Button {
                            showingAPIKey.toggle()
                        } label: {
                            Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            isOpenAILocked.toggle()
                        } label: {
                            Image(systemName: isOpenAILocked ? "lock.fill" : "lock.open.fill")
                                .foregroundColor(isOpenAILocked ? .secondary : .accentColor)
                        }
                        .buttonStyle(.borderless)
                        .help(isOpenAILocked ? "Unlock to edit" : "Lock to prevent changes")
                    }

                    HStack {
                        if !apiKey.isEmpty {
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text(isOpenAILocked ? "Unlock to enter API key" : "Enter your API key above")
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
                    
                    Divider()
                    
                    Text("Gemini API Key")
                        .font(.headline)

                    HStack {
                        if showingGeminiAPIKey {
                            TextField("Paste key...", text: $geminiAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: geminiAPIKey) { _, newValue in
                                    autoSaveAPIKey(newValue, type: .gemini)
                                }
                                .disabled(isGeminiLocked)
                        } else {
                            SecureField("Paste key...", text: $geminiAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: geminiAPIKey) { _, newValue in
                                    autoSaveAPIKey(newValue, type: .gemini)
                                }
                                .disabled(isGeminiLocked)
                        }

                        Button {
                            showingGeminiAPIKey.toggle()
                        } label: {
                            Image(systemName: showingGeminiAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            isGeminiLocked.toggle()
                        } label: {
                            Image(systemName: isGeminiLocked ? "lock.fill" : "lock.open.fill")
                                .foregroundColor(isGeminiLocked ? .secondary : .accentColor)
                        }
                        .buttonStyle(.borderless)
                        .help(isGeminiLocked ? "Unlock to edit" : "Lock to prevent changes")
                    }

                    HStack {
                        if !geminiAPIKey.isEmpty {
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text(isGeminiLocked ? "Unlock to enter API key" : "Enter your Google Gemini API key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Verify") {
                            verifyGeminiAPIKey()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(geminiAPIKey.isEmpty || isVerifyingGemini)
                        
                        if !geminiAPIKey.isEmpty {
                            Button("Clear", role: .destructive) {
                                clearAPIKey(type: .gemini)
                            }
                        }
                        
                        if isVerifyingGemini {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    
                    if let result = geminiVerificationResult {
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

                    Divider()
                    
                    Text("Groq API Key (for Auto Mode)")
                        .font(.headline)

                    HStack {
                        if showingGroqAPIKey {
                            TextField("gsk-...", text: $groqAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: groqAPIKey) { _, newValue in
                                    autoSaveAPIKey(newValue, type: .groq)
                                }
                                .disabled(isGroqLocked)
                        } else {
                            SecureField("gsk-...", text: $groqAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: groqAPIKey) { _, newValue in
                                    autoSaveAPIKey(newValue, type: .groq)
                                }
                                .disabled(isGroqLocked)
                        }

                        Button {
                            showingGroqAPIKey.toggle()
                        } label: {
                            Image(systemName: showingGroqAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            isGroqLocked.toggle()
                        } label: {
                            Image(systemName: isGroqLocked ? "lock.fill" : "lock.open.fill")
                                .foregroundColor(isGroqLocked ? .secondary : .accentColor)
                        }
                        .buttonStyle(.borderless)
                        .help(isGroqLocked ? "Unlock to edit" : "Lock to prevent changes")
                    }

                    HStack {
                        if !groqAPIKey.isEmpty {
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text(isGroqLocked ? "Unlock to enter API key" : "Enter your Groq API key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Verify") {
                            verifyGroqAPIKey()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(groqAPIKey.isEmpty || isVerifyingGroq)
                        
                        if !groqAPIKey.isEmpty {
                            Button("Clear", role: .destructive) {
                                clearAPIKey(type: .groq)
                            }
                        }
                        
                        if isVerifyingGroq {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    
                    if let result = groqVerificationResult {
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

                    if showSaveConfirmation {
                        Label("API key saved", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            } header: {
                Text("API Configuration")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Link("Get an OpenAI API key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    Link("Get a Gemini API key", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                    Link("Get a Groq API key", destination: URL(string: "https://console.groq.com/keys")!)
                }
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
                    ForEach(AppTheme.allCases) { theme in
                        ThemeRow(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme,
                            onSelect: { themeManager.currentTheme = theme }
                        )
                    }
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Theme affects colors, fonts, and styling across the app.")
                    .font(.caption)
            }
            
            // MARK: - Shortcuts Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(HotkeyAction.allCases, id: \.self) { action in
                        HotkeyRow(action: action, hotkeyConfig: FluencyApp.sharedHotkeyConfig)
                    }
                    
                    Divider()
                    
                    Button("Reset All to Defaults") {
                        FluencyApp.sharedHotkeyConfig.resetToDefaults()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.secondary)
                }
            } header: {
                Text("Keyboard Shortcuts")
            } footer: {
                Text("Configure global hotkeys for recording and TTS.")
                    .font(.caption)
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
                            // Reset voice to default for new provider
                            if let firstVoice = TTSVoice.allCases.first(where: { $0.provider == newValue }) {
                                selectedVoice = firstVoice
                                TTSService.selectedVoice = firstVoice
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Voice selection
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(TTSVoice.allCases.filter { $0.provider == selectedTTSProvider }, id: \.self) { voice in
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
                    
                    // Preview Button
                    HStack {
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
                                Text("Preview Voice")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(apiKey.isEmpty || isPreviewingVoice)
                    }
                    
                    Text("Shortcut: Hold Option + Press Fn")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Text-to-Speech")
            }

            Section {
                StatsView()
            } header: {
                Text("Your Stats")
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Home Server URL")
                        .font(.headline)
                    
                    TextField("10.69.1.250", text: Binding(
                        get: { SyncService.shared.serverURL },
                        set: { SyncService.shared.serverURL = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        StatusIndicator(
                            isOn: isServerConnected,
                            onText: "Connected to Server",
                            offText: "Server Disconnected"
                        )
                        
                        Spacer()
                        
                        Button(isTestingConnection ? "Testing..." : "Test Connection") {
                            isTestingConnection = true
                            Task {
                                let result = await SyncService.shared.testConnection()
                                await MainActor.run {
                                    isServerConnected = result
                                    isTestingConnection = false
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isTestingConnection)
                    }
                    .task {
                        // Check connection on view appear
                        isServerConnected = await SyncService.shared.testConnection()
                    }
                }
            } header: {
                Text("Server Sync")
            } footer: {
                Text("Transcriptions and stats sync to port 7006 on your home server.")
                    .font(.caption)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Use")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        InstructionRow(number: 1, text: "Set 'Press 🌐 key to' → 'Do Nothing' in System Settings → Keyboard")
                        InstructionRow(number: 2, text: "Click in any text field")
                        InstructionRow(number: 3, text: "Hold the Fn key and speak → release to transcribe (STT)")
                        InstructionRow(number: 4, text: "Hold Option, then press Fn → speaks selected text (TTS)")
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
    }

    private func loadSettings() {
        if let key = KeychainHelper.getAPIKey(for: .openAI) {
            apiKey = key
            isOpenAILocked = !key.isEmpty
        } else {
            isOpenAILocked = false
        }
        
        if let key = KeychainHelper.getAPIKey(for: .gemini) {
            geminiAPIKey = key
            isGeminiLocked = !key.isEmpty
        } else {
            isGeminiLocked = false
        }
        
        if let key = KeychainHelper.getAPIKey(for: .groq) {
            groqAPIKey = key
            isGroqLocked = !key.isEmpty
        } else {
            isGroqLocked = false
        }
        // Check launch at login status
        launchAtLogin = SMAppService.mainApp.status == .enabled
        // Load TTS settings
        selectedVoice = TTSService.selectedVoice
        selectedTTSProvider = TTSService.selectedProvider
        selectedPresetId = TTSService.selectedPresetId
        customPresets = TTSService.customPresets
    }
    
    private func autoSaveAPIKey(_ key: String, type: KeychainHelper.APIKeyType = .openAI) {
        // Auto-save when the key changes (debounced effectively by onChange)
        if !key.isEmpty {
            KeychainHelper.saveAPIKey(key, for: type)
        }
        if type == .openAI {
            verificationResult = nil
        } else if type == .gemini {
            geminiVerificationResult = nil
        } else if type == .groq {
            groqVerificationResult = nil
        }
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    verificationResult = nil
                }
            }
        }
    }
    
    private func verifyGeminiAPIKey() {
        isVerifyingGemini = true
        geminiVerificationResult = nil
        
        Task {
            let result = await TTSService.shared.verifyGeminiAPIKey(geminiAPIKey)
            
            await MainActor.run {
                isVerifyingGemini = false
                switch result {
                case .success:
                    geminiVerificationResult = .success
                case .failure(let error):
                    geminiVerificationResult = .failure(error.localizedDescription)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    geminiVerificationResult = nil
                }
            }
        }
    }
    
    private func verifyGroqAPIKey() {
        isVerifyingGroq = true
        groqVerificationResult = nil
        
        Task {
            let result = await GroqService.shared.verifyAPIKey(groqAPIKey)
            
            await MainActor.run {
                isVerifyingGroq = false
                switch result {
                case .success:
                    groqVerificationResult = .success
                case .failure(let error):
                    groqVerificationResult = .failure(error.localizedDescription)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    groqVerificationResult = nil
                }
            }
        }
    }

    private func clearAPIKey(type: KeychainHelper.APIKeyType = .openAI) {
        KeychainHelper.deleteAPIKey(for: type)
        if type == .openAI {
            apiKey = ""
        } else {
            geminiAPIKey = ""
        }
        if type == .groq {
            groqAPIKey = ""
        }
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

struct StatusIndicator: View {
    let isOn: Bool
    let onText: String
    let offText: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isOn ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isOn ? onText : offText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Color swatches
                HStack(spacing: 2) {
                    let colors = ThemeManager().currentTheme == theme ? 
                        ThemeManager().colors : getColorsForTheme(theme)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colors.gradientStart)
                        .frame(width: 16, height: 24)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colors.gradientMiddle)
                        .frame(width: 16, height: 24)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colors.gradientEnd)
                        .frame(width: 16, height: 24)
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: theme.icon)
                            .font(.caption)
                        Text(theme.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func getColorsForTheme(_ theme: AppTheme) -> ThemeColors {
        let tempManager = ThemeManager()
        let originalTheme = tempManager.currentTheme
        tempManager.currentTheme = theme
        let colors = tempManager.colors
        tempManager.currentTheme = originalTheme
        return colors
    }
}

// MARK: - Hotkey Row

struct HotkeyRow: View {
    let action: HotkeyAction
    let hotkeyConfig: HotkeyConfigurationManager
    
    @State private var isRecording = false
    @State private var selectedSecondary: Set<ModifierKey> = []
    
    var binding: HotkeyBinding {
        hotkeyConfig.binding(for: action)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(action.displayName)
                    .font(.system(size: 13, weight: .medium))
                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Current shortcut display
            Text(binding.displayString)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                )
            
            // Modifier picker for secondary modifiers
            Menu {
                ForEach(secondaryModifierOptions, id: \.self) { modifier in
                    Button {
                        toggleSecondaryModifier(modifier)
                    } label: {
                        HStack {
                            Text("\(modifier.symbol) \(modifier.displayName)")
                            if binding.secondaryModifiers.contains(modifier) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("Reset to Default") {
                    hotkeyConfig.resetToDefault(action: action)
                }
            } label: {
                Image(systemName: "keyboard")
                    .foregroundColor(.accentColor)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 30)
        }
        .padding(.vertical, 4)
    }
    
    private var secondaryModifierOptions: [ModifierKey] {
        // Don't show Fn as secondary - it's always primary for now
        ModifierKey.allCases.filter { $0 != .fn }
    }
    
    private func toggleSecondaryModifier(_ modifier: ModifierKey) {
        var newSecondary = binding.secondaryModifiers
        if newSecondary.contains(modifier) {
            newSecondary.remove(modifier)
        } else {
            newSecondary.insert(modifier)
        }
        
        let newBinding = HotkeyBinding(
            primaryModifier: binding.primaryModifier,
            secondaryModifiers: newSecondary,
            requiresHold: binding.requiresHold
        )
        hotkeyConfig.updateBinding(for: action, to: newBinding)
    }
}

#Preview {
    SettingsView()
}
