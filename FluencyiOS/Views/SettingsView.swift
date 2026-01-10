import SwiftUI

struct SettingsView: View {
    @State private var openAIKey = ""
    @State private var geminiKey = ""
    @State private var groqKey = ""
    
    @State private var showingOpenAIKey = false
    @State private var showingGeminiKey = false
    @State private var showingGroqKey = false
    
    @State private var selectedVoice: TTSVoice = TTSService.selectedVoice
    @State private var selectedProvider: TTSProvider = TTSService.selectedProvider
    @State private var selectedPresetId: UUID = TTSService.selectedPresetId
    
    @State private var serverURL = SyncService.shared.serverURL
    @State private var isTestingServer = false
    @State private var serverTestResult: String?
    
    var body: some View {
        NavigationStack {
            Form {
                // API Keys Section
                Section {
                    APIKeyField(
                        title: "OpenAI",
                        placeholder: "sk-...",
                        key: $openAIKey,
                        isShowing: $showingOpenAIKey,
                        keyType: .openAI
                    )
                    
                    APIKeyField(
                        title: "Gemini",
                        placeholder: "AIza...",
                        key: $geminiKey,
                        isShowing: $showingGeminiKey,
                        keyType: .gemini
                    )
                    
                    APIKeyField(
                        title: "Groq (Auto Mode)",
                        placeholder: "gsk-...",
                        key: $groqKey,
                        isShowing: $showingGroqKey,
                        keyType: .groq
                    )
                } header: {
                    Text("API Keys")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Link("Get OpenAI Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        Link("Get Gemini Key", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                        Link("Get Groq Key", destination: URL(string: "https://console.groq.com/keys")!)
                    }
                    .font(.caption)
                }
                
                // TTS Settings
                Section {
                    Picker("Provider", selection: $selectedProvider) {
                        ForEach(TTSProvider.allCases.filter { $0.isAvailable }, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .onChange(of: selectedProvider) { _, newValue in
                        TTSService.selectedProvider = newValue
                        if let firstVoice = TTSVoice.allCases.first(where: { $0.provider == newValue }) {
                            selectedVoice = firstVoice
                            TTSService.selectedVoice = firstVoice
                        }
                    }
                    
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(TTSVoice.allCases.filter { $0.provider == selectedProvider }, id: \.self) { voice in
                            Text(voice.displayName).tag(voice)
                        }
                    }
                    .onChange(of: selectedVoice) { _, newValue in
                        TTSService.selectedVoice = newValue
                    }
                    
                    Picker("Style", selection: $selectedPresetId) {
                        ForEach(VoicePreset.builtInPresets, id: \.id) { preset in
                            Text(preset.name).tag(preset.id)
                        }
                    }
                    .onChange(of: selectedPresetId) { _, newValue in
                        TTSService.selectedPresetId = newValue
                    }
                } header: {
                    Text("Text-to-Speech")
                }
                
                // Server Sync
                Section {
                    HStack {
                        Text("Server IP")
                        Spacer()
                        TextField("10.69.1.250", text: $serverURL)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                            .onChange(of: serverURL) { _, newValue in
                                SyncService.shared.serverURL = newValue
                            }
                    }
                    
                    Button {
                        testServerConnection()
                    } label: {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if isTestingServer {
                                ProgressView()
                            } else if let result = serverTestResult {
                                Text(result)
                                    .foregroundColor(result == "Connected" ? .green : .red)
                            }
                        }
                    }
                } header: {
                    Text("Server Sync")
                } footer: {
                    Text("Sync your transcriptions and stats to your server at ~/servers/Fluency/")
                }
                
                // Keyboard Setup
                Section {
                    NavigationLink {
                        KeyboardSetupView()
                    } label: {
                        Label("Custom Keyboard Setup", systemImage: "keyboard")
                    }
                } header: {
                    Text("Keyboard Extension")
                } footer: {
                    Text("Enable the Fluency keyboard to dictate in any app")
                }
                
                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadSettings()
            }
        }
    }
    
    private func loadSettings() {
        openAIKey = KeychainHelper.getAPIKey(for: .openAI) ?? ""
        geminiKey = KeychainHelper.getAPIKey(for: .gemini) ?? ""
        groqKey = KeychainHelper.getAPIKey(for: .groq) ?? ""
        selectedVoice = TTSService.selectedVoice
        selectedProvider = TTSService.selectedProvider
        selectedPresetId = TTSService.selectedPresetId
        serverURL = SyncService.shared.serverURL
    }
    
    private func testServerConnection() {
        isTestingServer = true
        serverTestResult = nil
        
        Task {
            let connected = await SyncService.shared.testConnection()
            await MainActor.run {
                isTestingServer = false
                serverTestResult = connected ? "Connected" : "Failed"
            }
        }
    }
}

// MARK: - API Key Field

struct APIKeyField: View {
    let title: String
    let placeholder: String
    @Binding var key: String
    @Binding var isShowing: Bool
    let keyType: KeychainHelper.APIKeyType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                if isShowing {
                    TextField(placeholder, text: $key)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .font(.system(.body, design: .monospaced))
                } else {
                    SecureField(placeholder, text: $key)
                        .textContentType(.password)
                        .font(.system(.body, design: .monospaced))
                }
                
                Button {
                    isShowing.toggle()
                } label: {
                    Image(systemName: isShowing ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .onChange(of: key) { _, newValue in
                if !newValue.isEmpty {
                    KeychainHelper.saveAPIKey(newValue, for: keyType)
                }
            }
        }
    }
}

// MARK: - Keyboard Setup View

struct KeyboardSetupView: View {
    var body: some View {
        List {
            Section {
                InstructionRow(number: 1, text: "Open Settings → General → Keyboard")
                InstructionRow(number: 2, text: "Tap \"Keyboards\"")
                InstructionRow(number: 3, text: "Tap \"Add New Keyboard...\"")
                InstructionRow(number: 4, text: "Select \"Fluency\"")
                InstructionRow(number: 5, text: "Tap \"Fluency\" and enable \"Allow Full Access\"")
            } header: {
                Text("Setup Instructions")
            }
            
            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Use")
                        .font(.headline)
                    
                    Text("1. In any app, tap the 🌐 globe icon to switch keyboards")
                    Text("2. Tap the microphone button to start dictating")
                    Text("3. Tap ⌨️ to switch to standard keyboard mode")
                    Text("4. Your transcriptions sync to the main app")
                }
                .font(.subheadline)
            } header: {
                Text("Usage")
            }
        }
        .navigationTitle("Keyboard Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(.blue))
            
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    SettingsView()
}
