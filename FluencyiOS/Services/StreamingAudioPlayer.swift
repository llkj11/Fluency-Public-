import Foundation
import AVFoundation

/// A streaming audio player that uses AVAudioEngine to play PCM audio chunks
/// as they arrive from an HTTP stream.
class StreamingAudioPlayer {
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    // OpenAI TTS outputs 24kHz, 16-bit signed PCM, mono
    private let sampleRate: Double = 24000
    private let channels: AVAudioChannelCount = 1
    
    private var audioFormat: AVAudioFormat!
    private var isStarted = false
    private var onComplete: (() -> Void)?
    private var pendingBuffers = 0
    private let bufferLock = NSLock()
    
    /// Minimum bytes before starting playback (allows beep to complete + reduces choppy start)
    private let minBufferBytes = 24000 // ~500ms at 24kHz 16-bit mono
    private var initialBuffer = Data()
    private var hasStartedPlayback = false
    
    var isPlaying: Bool {
        playerNode.isPlaying
    }
    
    init() {
        audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: true
        )
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
    }
    
    /// Prepare the audio engine for playback
    func prepare() throws {
        guard !isStarted else { return }
        
        try audioEngine.start()
        playerNode.play()
        isStarted = true
    }
    
    /// Schedule a chunk of PCM audio data for playback
    func scheduleChunk(_ data: Data) {
        guard !data.isEmpty else { return }
        
        // Buffer initial audio to prevent choppy playback
        if !hasStartedPlayback {
            initialBuffer.append(data)
            if initialBuffer.count >= minBufferBytes {
                hasStartedPlayback = true
                scheduleBuffer(initialBuffer)
                initialBuffer = Data()
            }
            return
        }
        
        scheduleBuffer(data)
    }
    
    private func scheduleBuffer(_ data: Data) {
        // 16-bit audio = 2 bytes per sample
        let frameCount = AVAudioFrameCount(data.count / 2)
        guard frameCount > 0 else { return }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return
        }
        buffer.frameLength = frameCount
        
        // Copy PCM data into the buffer
        data.withUnsafeBytes { rawBufferPointer in
            if let baseAddress = rawBufferPointer.baseAddress {
                memcpy(buffer.int16ChannelData![0], baseAddress, data.count)
            }
        }
        
        bufferLock.lock()
        pendingBuffers += 1
        bufferLock.unlock()
        
        playerNode.scheduleBuffer(buffer) { [weak self] in
            self?.bufferLock.lock()
            self?.pendingBuffers -= 1
            let remaining = self?.pendingBuffers ?? 0
            self?.bufferLock.unlock()
            
            // All buffers played
            if remaining == 0 {
                DispatchQueue.main.async {
                    self?.onComplete?()
                }
            }
        }
    }
    
    /// Signal that all data has been received
    func finishStreaming(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        
        // If we have buffered data that never hit threshold, play it now
        if !initialBuffer.isEmpty {
            hasStartedPlayback = true
            scheduleBuffer(initialBuffer)
            initialBuffer = Data()
        }
        
        // If no buffers were scheduled, complete immediately
        bufferLock.lock()
        let remaining = pendingBuffers
        bufferLock.unlock()
        
        if remaining == 0 {
            DispatchQueue.main.async {
                onComplete()
            }
        }
    }
    
    /// Stop playback and clean up
    func stop() {
        playerNode.stop()
        audioEngine.stop()
        isStarted = false
        hasStartedPlayback = false
        initialBuffer = Data()
        pendingBuffers = 0
    }
}
