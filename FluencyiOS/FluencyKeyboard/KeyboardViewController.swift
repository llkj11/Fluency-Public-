import UIKit
import AVFoundation

/// Custom keyboard with two modes: Dictation and Standard Typing
class KeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    
    enum KeyboardMode {
        case dictation
        case standard
    }
    
    private var currentMode: KeyboardMode = .dictation
    private var audioRecorder: AudioRecorder?
    private var transcriptionService: TranscriptionService?
    private var isRecording = false
    private var recordingTimer: Timer?
    private var audioLevel: Float = 0
    
    // UI Elements
    private var containerView: UIStackView!
    private var modeToggleButton: UIButton!
    private var micButton: UIButton!
    private var statusLabel: UILabel!
    private var waveformView: WaveformView!
    private var keyboardView: StandardKeyboardView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioRecorder = AudioRecorder()
        transcriptionService = TranscriptionService()
        
        setupUI()
        updateModeUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Ensure proper height
        view.frame.size.height = currentMode == .dictation ? 280 : 260
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Main container
        containerView = UIStackView()
        containerView.axis = .vertical
        containerView.alignment = .fill
        containerView.distribution = .fill
        containerView.spacing = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        
        // Top bar with mode toggle and globe button
        let topBar = createTopBar()
        containerView.addArrangedSubview(topBar)
        
        // Dictation view
        let dictationContainer = createDictationView()
        containerView.addArrangedSubview(dictationContainer)
        
        // Standard keyboard view
        keyboardView = StandardKeyboardView(textDocumentProxy: textDocumentProxy)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.isHidden = true
        containerView.addArrangedSubview(keyboardView)
    }
    
    private func createTopBar() -> UIView {
        let topBar = UIStackView()
        topBar.axis = .horizontal
        topBar.distribution = .equalSpacing
        topBar.alignment = .center
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Globe button (switch keyboard)
        let globeButton = UIButton(type: .system)
        globeButton.setImage(UIImage(systemName: "globe"), for: .normal)
        globeButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globeButton.tintColor = .label
        
        // Mode toggle button
        modeToggleButton = UIButton(type: .system)
        modeToggleButton.setImage(UIImage(systemName: "keyboard"), for: .normal)
        modeToggleButton.setTitle(" Keyboard", for: .normal)
        modeToggleButton.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        modeToggleButton.tintColor = .label
        
        // Status label
        statusLabel = UILabel()
        statusLabel.text = "Tap mic to speak"
        statusLabel.font = .preferredFont(forTextStyle: .caption1)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        
        topBar.addArrangedSubview(globeButton)
        topBar.addArrangedSubview(statusLabel)
        topBar.addArrangedSubview(modeToggleButton)
        
        return topBar
    }
    
    private func createDictationView() -> UIView {
        let dictationContainer = UIView()
        dictationContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Waveform visualization
        waveformView = WaveformView()
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        dictationContainer.addSubview(waveformView)
        
        // Microphone button
        micButton = UIButton(type: .custom)
        micButton.backgroundColor = .systemBlue
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = .white
        micButton.layer.cornerRadius = 40
        micButton.translatesAutoresizingMaskIntoConstraints = false
        micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
        dictationContainer.addSubview(micButton)
        
        NSLayoutConstraint.activate([
            waveformView.topAnchor.constraint(equalTo: dictationContainer.topAnchor, constant: 8),
            waveformView.leadingAnchor.constraint(equalTo: dictationContainer.leadingAnchor, constant: 20),
            waveformView.trailingAnchor.constraint(equalTo: dictationContainer.trailingAnchor, constant: -20),
            waveformView.heightAnchor.constraint(equalToConstant: 60),
            
            micButton.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 16),
            micButton.centerXAnchor.constraint(equalTo: dictationContainer.centerXAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 80),
            micButton.heightAnchor.constraint(equalToConstant: 80),
            micButton.bottomAnchor.constraint(equalTo: dictationContainer.bottomAnchor, constant: -16)
        ])
        
        return dictationContainer
    }
    
    // MARK: - Mode Toggle
    
    @objc private func toggleMode() {
        currentMode = currentMode == .dictation ? .standard : .dictation
        updateModeUI()
    }
    
    private func updateModeUI() {
        let isDictation = currentMode == .dictation
        
        UIView.animate(withDuration: 0.2) {
            // Toggle visibility
            self.waveformView.superview?.isHidden = !isDictation
            self.keyboardView.isHidden = isDictation
            
            // Update toggle button
            if isDictation {
                self.modeToggleButton.setImage(UIImage(systemName: "keyboard"), for: .normal)
                self.modeToggleButton.setTitle(" Keyboard", for: .normal)
                self.statusLabel.text = "Tap mic to speak"
            } else {
                self.modeToggleButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
                self.modeToggleButton.setTitle(" Dictate", for: .normal)
                self.statusLabel.text = "Standard keyboard"
            }
        }
        
        view.setNeedsLayout()
    }
    
    // MARK: - Recording
    
    @objc private func micButtonTapped() {
        if isRecording {
            stopRecordingAndTranscribe()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Request microphone permission if needed
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.beginRecording()
                } else {
                    self?.statusLabel.text = "Microphone access denied"
                }
            }
        }
    }
    
    private func beginRecording() {
        isRecording = true
        audioRecorder?.startRecording()
        
        // Update UI
        micButton.backgroundColor = .systemRed
        micButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        statusLabel.text = "Listening..."
        
        // Update waveform
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.audioLevel = self.audioRecorder?.currentLevel ?? 0
            self.waveformView.updateLevel(self.audioLevel)
        }
        
        // Pulse animation
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse]) {
            self.micButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
    }
    
    private func stopRecordingAndTranscribe() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        
        // Reset UI
        micButton.layer.removeAllAnimations()
        micButton.transform = .identity
        micButton.backgroundColor = .systemBlue
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        statusLabel.text = "Transcribing..."
        waveformView.updateLevel(0)
        
        guard let audioURL = audioRecorder?.stopRecording() else {
            statusLabel.text = "Recording failed"
            return
        }
        
        let duration = audioRecorder?.recordingDuration ?? 0
        
        // Transcribe
        Task {
            do {
                let text = try await transcriptionService?.transcribe(audioURL: audioURL) ?? ""
                
                await MainActor.run {
                    // Insert transcribed text
                    self.textDocumentProxy.insertText(text)
                    self.statusLabel.text = "Tap mic to speak"
                    
                    // Record stats
                    let wordCount = text.split(separator: " ").count
                    StatsService.shared.recordTranscription(wordCount: wordCount, duration: duration)
                    
                    // Save to shared container for main app
                    self.saveTranscriptionToSharedContainer(text: text, duration: duration)
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveTranscriptionToSharedContainer(text: String, duration: TimeInterval) {
        // Save to shared UserDefaults for main app to pick up
        guard let defaults = UserDefaults(suiteName: "group.com.fluency.ios") else { return }
        
        var recentTranscriptions = defaults.array(forKey: "recentTranscriptions") as? [[String: Any]] ?? []
        
        let transcription: [String: Any] = [
            "id": UUID().uuidString,
            "text": text,
            "createdAt": Date().timeIntervalSince1970,
            "duration": duration,
            "wordCount": text.split(separator: " ").count
        ]
        
        recentTranscriptions.insert(transcription, at: 0)
        
        // Keep only last 100
        if recentTranscriptions.count > 100 {
            recentTranscriptions = Array(recentTranscriptions.prefix(100))
        }
        
        defaults.set(recentTranscriptions, forKey: "recentTranscriptions")
    }
}

// MARK: - Waveform View

class WaveformView: UIView {
    private var bars: [UIView] = []
    private let barCount = 30
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
    }
    
    private func setupBars() {
        for _ in 0..<barCount {
            let bar = UIView()
            bar.backgroundColor = .systemBlue
            bar.layer.cornerRadius = 2
            addSubview(bar)
            bars.append(bar)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let totalWidth = bounds.width
        let barWidth: CGFloat = 6
        let spacing = (totalWidth - CGFloat(barCount) * barWidth) / CGFloat(barCount - 1)
        
        for (index, bar) in bars.enumerated() {
            let x = CGFloat(index) * (barWidth + spacing)
            bar.frame = CGRect(x: x, y: bounds.height / 2 - 2, width: barWidth, height: 4)
        }
    }
    
    func updateLevel(_ level: Float) {
        let normalizedLevel = CGFloat(max(0, min(1, level)))
        
        for (index, bar) in bars.enumerated() {
            let indexFactor = sin(Double(index) / Double(barCount) * .pi)
            let randomFactor = Double.random(in: 0.5...1.0)
            let height = max(4, normalizedLevel * 50 * CGFloat(indexFactor * randomFactor))
            
            UIView.animate(withDuration: 0.05) {
                bar.frame = CGRect(
                    x: bar.frame.minX,
                    y: self.bounds.height / 2 - height / 2,
                    width: bar.frame.width,
                    height: height
                )
            }
        }
    }
}

// MARK: - Standard Keyboard View

class StandardKeyboardView: UIView {
    private var textDocumentProxy: UITextDocumentProxy
    private var isShifted = false
    
    private let letters = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    init(textDocumentProxy: UITextDocumentProxy) {
        self.textDocumentProxy = textDocumentProxy
        super.init(frame: .zero)
        setupKeyboard()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupKeyboard() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fillEqually
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Letter rows
        for row in letters {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4
            
            for letter in row {
                let button = createKeyButton(title: letter)
                button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(button)
            }
            
            mainStack.addArrangedSubview(rowStack)
        }
        
        // Bottom row with special keys
        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.distribution = .fill
        bottomRow.spacing = 4
        
        let shiftButton = createKeyButton(title: "⇧")
        shiftButton.addTarget(self, action: #selector(shiftTapped), for: .touchUpInside)
        shiftButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        let spaceButton = createKeyButton(title: "space")
        spaceButton.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        
        let deleteButton = createKeyButton(title: "⌫")
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        let returnButton = createKeyButton(title: "return")
        returnButton.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)
        returnButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        returnButton.backgroundColor = .systemBlue
        returnButton.setTitleColor(.white, for: .normal)
        
        bottomRow.addArrangedSubview(shiftButton)
        bottomRow.addArrangedSubview(spaceButton)
        bottomRow.addArrangedSubview(deleteButton)
        bottomRow.addArrangedSubview(returnButton)
        
        mainStack.addArrangedSubview(bottomRow)
    }
    
    private func createKeyButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 5
        button.setTitleColor(.label, for: .normal)
        return button
    }
    
    @objc private func letterTapped(_ sender: UIButton) {
        guard let letter = sender.title(for: .normal) else { return }
        let text = isShifted ? letter : letter.lowercased()
        textDocumentProxy.insertText(text)
        if isShifted {
            isShifted = false
        }
    }
    
    @objc private func shiftTapped() {
        isShifted.toggle()
    }
    
    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
    }
    
    @objc private func deleteTapped() {
        textDocumentProxy.deleteBackward()
    }
    
    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
    }
}
