import Foundation
import AppKit

// MARK: - Hotkey Actions

/// The actions that can be triggered by global hotkeys
enum HotkeyAction: String, CaseIterable, Codable {
    case startRecording = "startRecording"
    case cancelRecording = "cancelRecording"
    case triggerTTS = "triggerTTS"
    
    var displayName: String {
        switch self {
        case .startRecording: return "Start Recording"
        case .cancelRecording: return "Cancel Recording"
        case .triggerTTS: return "Read Aloud (TTS)"
        }
    }
    
    var description: String {
        switch self {
        case .startRecording: return "Hold to record, release to transcribe"
        case .cancelRecording: return "Cancel current recording without transcribing"
        case .triggerTTS: return "Read selected text aloud"
        }
    }
}

// MARK: - Hotkey Binding

/// Represents a keyboard shortcut binding for a hotkey action
struct HotkeyBinding: Codable, Equatable {
    /// The primary modifier that triggers the action (usually Fn)
    var primaryModifier: ModifierKey
    
    /// Additional modifiers required (e.g., Option, Control)
    var secondaryModifiers: Set<ModifierKey>
    
    /// Whether this is a hold-to-activate action (like STT) or tap (like TTS)
    var requiresHold: Bool
    
    /// User-friendly display string
    var displayString: String {
        var parts: [String] = []
        
        // Add secondary modifiers first (alphabetically for consistency)
        let sortedSecondary = secondaryModifiers.sorted { $0.displayName < $1.displayName }
        for modifier in sortedSecondary {
            parts.append(modifier.symbol)
        }
        
        // Add primary modifier
        parts.append(primaryModifier.symbol)
        
        return parts.joined(separator: " + ")
    }
}

// MARK: - Modifier Keys

/// Supported modifier keys for hotkey bindings
enum ModifierKey: String, Codable, CaseIterable, Hashable {
    case fn = "fn"
    case option = "option"
    case control = "control"
    case shift = "shift"
    case command = "command"
    
    var displayName: String {
        switch self {
        case .fn: return "Fn"
        case .option: return "Option"
        case .control: return "Control"
        case .shift: return "Shift"
        case .command: return "Command"
        }
    }
    
    var symbol: String {
        switch self {
        case .fn: return "fn"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        case .command: return "⌘"
        }
    }
    
    var nsEventFlag: NSEvent.ModifierFlags {
        switch self {
        case .fn: return .function
        case .option: return .option
        case .control: return .control
        case .shift: return .shift
        case .command: return .command
        }
    }
}

// MARK: - Configuration Manager

/// Manages hotkey configuration persistence and access
@Observable
class HotkeyConfigurationManager {
    private let storage: UserDefaults
    private let storageKey = "hotkeyBindings"
    
    /// Current hotkey bindings for each action
    private(set) var bindings: [HotkeyAction: HotkeyBinding]
    
    /// Default bindings (matches current hardcoded behavior)
    static let defaultBindings: [HotkeyAction: HotkeyBinding] = [
        .startRecording: HotkeyBinding(
            primaryModifier: .fn,
            secondaryModifiers: [],
            requiresHold: true
        ),
        .cancelRecording: HotkeyBinding(
            primaryModifier: .fn,
            secondaryModifiers: [.control],
            requiresHold: false
        ),
        .triggerTTS: HotkeyBinding(
            primaryModifier: .fn,
            secondaryModifiers: [.option],
            requiresHold: false
        )
    ]
    
    init(storage: UserDefaults = .standard) {
        self.storage = storage
        self.bindings = Self.defaultBindings
        loadBindings()
    }
    
    /// Get the binding for a specific action
    func binding(for action: HotkeyAction) -> HotkeyBinding {
        bindings[action] ?? Self.defaultBindings[action]!
    }
    
    /// Update the binding for a specific action
    func updateBinding(for action: HotkeyAction, to binding: HotkeyBinding) {
        bindings[action] = binding
        saveBindings()
    }
    
    /// Reset all bindings to defaults
    func resetToDefaults() {
        bindings = Self.defaultBindings
        saveBindings()
    }
    
    /// Reset a specific action to its default binding
    func resetToDefault(action: HotkeyAction) {
        bindings[action] = Self.defaultBindings[action]
        saveBindings()
    }
    
    // MARK: - Persistence
    
    private func loadBindings() {
        guard let data = storage.data(forKey: storageKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode([String: HotkeyBinding].self, from: data)
            
            // Convert string keys back to enum
            for (rawValue, binding) in decoded {
                if let action = HotkeyAction(rawValue: rawValue) {
                    bindings[action] = binding
                }
            }
        } catch {
            print("⚠️ Failed to load hotkey bindings: \(error)")
        }
    }
    
    private func saveBindings() {
        do {
            // Convert enum keys to strings for Codable
            var stringKeyed: [String: HotkeyBinding] = [:]
            for (action, binding) in bindings {
                stringKeyed[action.rawValue] = binding
            }
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(stringKeyed)
            storage.set(data, forKey: storageKey)
        } catch {
            print("⚠️ Failed to save hotkey bindings: \(error)")
        }
    }
    
    // MARK: - Matching
    
    /// Check if the given modifier flags match a specific action's binding
    func matchesAction(_ action: HotkeyAction, flags: NSEvent.ModifierFlags) -> Bool {
        guard let binding = bindings[action] else { return false }
        
        // Check primary modifier is pressed
        if !flags.contains(binding.primaryModifier.nsEventFlag) {
            return false
        }
        
        // Check all secondary modifiers are pressed
        for modifier in binding.secondaryModifiers {
            if !flags.contains(modifier.nsEventFlag) {
                return false
            }
        }
        
        // Check that no EXTRA modifiers are pressed (except the ones we expect)
        var expectedFlags: NSEvent.ModifierFlags = binding.primaryModifier.nsEventFlag
        for modifier in binding.secondaryModifiers {
            expectedFlags.insert(modifier.nsEventFlag)
        }
        
        // Get only the relevant modifier bits
        let relevantFlags: NSEvent.ModifierFlags = [.function, .option, .control, .shift, .command]
        let pressedRelevant = flags.intersection(relevantFlags)
        
        return pressedRelevant == expectedFlags
    }
}
