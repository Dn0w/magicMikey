import UIKit
import Combine

/// Tracks sticky modifier key state (tap to arm, tap again to release).
final class ModifierState: ObservableObject {
    @Published var activeModifiers: UIKeyModifierFlags = []

    /// Toggle a modifier on/off (sticky behaviour).
    func toggle(_ modifier: UIKeyModifierFlags) {
        if activeModifiers.contains(modifier) {
            activeModifiers.remove(modifier)
        } else {
            activeModifiers.insert(modifier)
        }
    }

    /// Consume modifiers after a keypress (except caps lock which is permanent).
    func consumeAfterKeypress() {
        activeModifiers = activeModifiers.intersection(.alphaShift)
    }

    var isShiftArmed:   Bool { activeModifiers.contains(.shift) }
    var isCommandArmed: Bool { activeModifiers.contains(.command) }
    var isOptionArmed:  Bool { activeModifiers.contains(.alternate) }
    var isControlArmed: Bool { activeModifiers.contains(.control) }
    var isCapsLockOn:   Bool { activeModifiers.contains(.alphaShift) }
}
