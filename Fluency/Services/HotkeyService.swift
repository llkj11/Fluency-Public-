import Cocoa
import Foundation
import Carbon.HIToolbox

class HotkeyService {
    private var flagsMonitor: Any?
    private var localMonitor: Any?
    private var isRecording = false
    private var fnPressed = false
    private var controlWasPressed = false
    private var retryTimer: Timer?

    private let onRecordingStart: () -> Void
    private let onRecordingStop: () -> Void
    private let onTTSTriggered: () -> Void

    init(onRecordingStart: @escaping () -> Void, onRecordingStop: @escaping () -> Void, onTTSTriggered: @escaping () -> Void = {}) {
        self.onRecordingStart = onRecordingStart
        self.onRecordingStop = onRecordingStop
        self.onTTSTriggered = onTTSTriggered
    }

    func start() {
        // Check accessibility permission (don't prompt automatically)
        let accessibilityEnabled = AXIsProcessTrusted()
        print("🔐 Accessibility enabled: \(accessibilityEnabled)")

        if !accessibilityEnabled {
            print("⚠️ Accessibility permission not granted. Please enable in System Settings.")
            promptForAccessibility()
            startRetryTimer()
        }
        
        // Always try to start monitors - the check can be unreliable after rebuilds
        // The monitors will simply not receive events if not trusted
        startMonitors()
    }
    
    private func startMonitors() {
        // Remove existing monitors first
        stop()
        
        // Monitor for Fn key using global event monitor
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event)
        }

        // Also add local monitor to catch events when app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event)
            return event
        }

        if flagsMonitor != nil {
            print("✅ Hotkey service started - Hold Fn key to record!")
            print("💡 Make sure System Settings → Keyboard → 'Press fn key to' is set to 'Do Nothing'")
        } else {
            print("❌ Failed to create global event monitor - Accessibility likely not granted")
        }
    }
    
    private func startRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            if AXIsProcessTrusted() {
                print("✅ Accessibility permission now granted!")
                self?.retryTimer?.invalidate()
                self?.retryTimer = nil
                self?.startMonitors()
            } else {
                print("⏳ Still waiting for Accessibility permission...")
            }
        }
    }

    func stop() {
        retryTimer?.invalidate()
        retryTimer = nil
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleFlagsChanged(event: NSEvent) {
        let flags = event.modifierFlags
        let keyCode = event.keyCode

        // The Fn key sets the "function" bit in modifier flags
        // NSEvent.ModifierFlags.function (aka secondaryFn) = 0x800000
        let fnIsPressed = flags.contains(.function)
        let controlIsPressed = flags.contains(.control)

        // Debug: print all flag changes
        print("🔑 Flags: keyCode=\(keyCode), fn=\(fnIsPressed), ctrl=\(controlIsPressed), raw=\(flags.rawValue)")

        // Check if ONLY Fn is pressed (no other modifiers)
        let fnOnly = fnIsPressed &&
                     !flags.contains(.command) &&
                     !flags.contains(.option) &&
                     !flags.contains(.shift) &&
                     !flags.contains(.control)
        
        // Check if Fn+Control is pressed (for TTS)
        let fnAndControl = fnIsPressed && controlIsPressed &&
                           !flags.contains(.command) &&
                           !flags.contains(.option) &&
                           !flags.contains(.shift)

        // Handle Fn+Control for TTS
        if fnAndControl && !controlWasPressed {
            controlWasPressed = true
            // If we were recording, stop it first
            if isRecording {
                print("⏹️ Stopping recording for TTS trigger")
                stopRecording()
            }
            print("🔊 Fn+Control pressed - triggering TTS!")
            DispatchQueue.main.async { [weak self] in
                self?.onTTSTriggered()
            }
        } else if !controlIsPressed && controlWasPressed {
            controlWasPressed = false
        }

        // Handle Fn-only for recording (STT)
        if fnOnly && !fnPressed && !controlWasPressed {
            fnPressed = true
            print("🎙️ Fn pressed - starting recording!")
            startRecording()
        } else if !fnIsPressed && fnPressed {
            fnPressed = false
            if isRecording {
                print("⏹️ Fn released - stopping recording!")
                stopRecording()
            }
        } else if !fnOnly && fnPressed && !fnIsPressed {
            // Fn was released
            fnPressed = false
            if isRecording {
                print("⏹️ Fn released - stopping recording!")
                stopRecording()
            }
        }
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        DispatchQueue.main.async { [weak self] in
            self?.onRecordingStart()
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        DispatchQueue.main.async { [weak self] in
            self?.onRecordingStop()
        }
    }

    private func promptForAccessibility() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            Fluency needs Accessibility permission to detect the Fn key.
            
            1. Click "Open System Settings"
            2. If Fluency is already listed, REMOVE it first (click -)
            3. Click + and add Fluency again
            4. Make sure the toggle is ON
            
            Note: Each rebuild requires re-adding the app.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
