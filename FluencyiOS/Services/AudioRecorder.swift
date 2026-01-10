import Foundation
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    private var recordingURL: URL?
    private var recordingStartTime: Date?
    
    var currentLevel: Float = 0
    var recordingDuration: TimeInterval = 0
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startRecording() {
        // Create temp file URL
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent("fluency_recording_\(UUID().uuidString).m4a")
        
        guard let url = recordingURL else { return }
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            recordingStartTime = Date()
            
            // Start metering updates
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
                guard let self = self, let recorder = self.audioRecorder else {
                    timer.invalidate()
                    return
                }
                
                if recorder.isRecording {
                    recorder.updateMeters()
                    // Normalize metering level (typically -160 to 0 dB)
                    let level = recorder.averagePower(forChannel: 0)
                    self.currentLevel = max(0, (level + 50) / 50) // Normalize to 0-1
                } else {
                    timer.invalidate()
                }
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder, recorder.isRecording else { return nil }
        
        recorder.stop()
        
        if let startTime = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(startTime)
        }
        
        currentLevel = 0
        return recordingURL
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Encoding error: \(error)")
        }
    }
}
