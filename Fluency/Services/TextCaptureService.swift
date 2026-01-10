import AppKit
import ApplicationServices

class TextCaptureService {
    
    /// Captures the currently selected text system-wide by simulating Cmd+C
    /// Returns the selected text, or nil if nothing is selected
    func getSelectedText() -> String? {
        let pasteboard = NSPasteboard.general
        
        // Save current pasteboard content
        let previousContent = pasteboard.string(forType: .string)
        let previousChangeCount = pasteboard.changeCount
        
        // Clear and prepare for new content
        pasteboard.clearContents()
        
        // Simulate Cmd+C to copy selection
        simulateCopy()
        
        // Small delay to allow the copy to complete
        Thread.sleep(forTimeInterval: 0.05)
        
        // Check if pasteboard changed (meaning something was copied)
        let newChangeCount = pasteboard.changeCount
        let selectedText: String?
        
        if newChangeCount != previousChangeCount {
            selectedText = pasteboard.string(forType: .string)
        } else {
            selectedText = nil
        }
        
        // Restore previous pasteboard content
        if let previous = previousContent {
            // Delay restoration to not interfere with the read
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
            }
        }
        
        return selectedText
    }
    
    private func simulateCopy() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key code 8 = C
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
