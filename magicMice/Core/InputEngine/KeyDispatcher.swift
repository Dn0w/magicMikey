import UIKit

/// Dispatches key input to the current first responder.
final class KeyDispatcher {
    static let shared = KeyDispatcher()
    private init() {}

    /// Insert a text string into the first responder.
    func insertText(_ text: String) {
        guard let responder = findFirstResponder() else { return }
        if let textInput = responder as? UIKeyInput {
            textInput.insertText(text)
        }
    }

    /// Delete backwards in the first responder.
    func deleteBackward() {
        guard let responder = findFirstResponder(),
              let textInput = responder as? UIKeyInput else { return }
        textInput.deleteBackward()
    }

    /// Send a key command via the responder chain, using the correct UIResponder selector
    /// for well-known shortcuts and falling back to a UIKeyCommand dispatch for others.
    func sendKeyCommand(input: String, modifiers: UIKeyModifierFlags) {
        // Map well-known ⌘ shortcuts to their standard UIResponder actions
        if modifiers == .command || modifiers == [.command, .shift] {
            switch input.lowercased() {
            case "c":
                UIApplication.shared.sendAction(#selector(UIResponder.copy(_:)), to: nil, from: nil, for: nil)
                return
            case "x":
                UIApplication.shared.sendAction(#selector(UIResponder.cut(_:)), to: nil, from: nil, for: nil)
                return
            case "v":
                UIApplication.shared.sendAction(#selector(UIResponder.paste(_:)), to: nil, from: nil, for: nil)
                return
            case "a":
                UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                return
            case "b":
                UIApplication.shared.sendAction(#selector(UIResponder.toggleBoldface(_:)), to: nil, from: nil, for: nil)
                return
            case "i":
                UIApplication.shared.sendAction(#selector(UIResponder.toggleItalics(_:)), to: nil, from: nil, for: nil)
                return
            case "u":
                UIApplication.shared.sendAction(#selector(UIResponder.toggleUnderline(_:)), to: nil, from: nil, for: nil)
                return
            default:
                break
            }
        }
        // General fallback: send via UIKeyCommand through the responder chain.
        // The receiving app must have registered a UIKeyCommand matching this input+modifiers.
        let action = #selector(UIResponder.copy(_:))
        let command = UIKeyCommand(input: input, modifierFlags: modifiers, action: action)
        UIApplication.shared.sendAction(action, to: nil, from: command, for: nil)
    }

    /// Send a macro slot's keypress.
    func sendMacro(keyCode: Int, modifiers: Int) {
        guard let hidUsage = UIKeyboardHIDUsage(rawValue: keyCode),
              let character = hidUsage.character else { return }
        let modifierFlags = UIKeyModifierFlags(rawValue: modifiers)
        sendKeyCommand(input: character, modifiers: modifierFlags)
    }

    // MARK: - Private

    private func findFirstResponder() -> UIResponder? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .compactMap { window in
                guard let root = window.rootViewController else { return nil }
                return findFirstResponder(in: root.view)
            }
            .first
    }

    private func findFirstResponder(in view: UIView) -> UIResponder? {
        if view.isFirstResponder { return view }
        for sub in view.subviews {
            if let fr = findFirstResponder(in: sub) { return fr }
        }
        return nil
    }
}

// MARK: - UIKeyboardHIDUsage + character

private extension UIKeyboardHIDUsage {
    var character: String? {
        switch self {
        case .keyboardA: return "a"
        case .keyboardB: return "b"
        case .keyboardC: return "c"
        case .keyboardD: return "d"
        case .keyboardE: return "e"
        case .keyboardF: return "f"
        case .keyboardG: return "g"
        case .keyboardH: return "h"
        case .keyboardI: return "i"
        case .keyboardJ: return "j"
        case .keyboardK: return "k"
        case .keyboardL: return "l"
        case .keyboardM: return "m"
        case .keyboardN: return "n"
        case .keyboardO: return "o"
        case .keyboardP: return "p"
        case .keyboardQ: return "q"
        case .keyboardR: return "r"
        case .keyboardS: return "s"
        case .keyboardT: return "t"
        case .keyboardU: return "u"
        case .keyboardV: return "v"
        case .keyboardW: return "w"
        case .keyboardX: return "x"
        case .keyboardY: return "y"
        case .keyboardZ: return "z"
        default: return nil
        }
    }
}

