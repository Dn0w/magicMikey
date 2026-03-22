import UIKit

/// Shared input dispatch abstraction.
/// In the main app, closures route to KeyDispatcher.
/// In the keyboard extension, closures route to UITextDocumentProxy.
final class InputRouter: ObservableObject {
    var insertText: (String) -> Void = { _ in }
    var deleteBackward: () -> Void = {}
    var sendCommand: (String, UIKeyModifierFlags) -> Void = { _, _ in }
    var dismissKeyboard: () -> Void = {}

    /// Updated by the keyboard extension after every text operation.
    /// Empty in the main app (no text proxy access).
    @Published var currentContext: String = ""

    /// Last continuous letter run immediately before the cursor.
    /// Used for English word-completion predictions. Empty in the main app.
    @Published var wordFragment: String = ""

    /// Accumulates typed Pinyin letters when a Chinese IME variant is active.
    /// Empty when not in Chinese IME mode or after committing a candidate.
    @Published var pinyinBuffer: String = ""

    /// Maps a MacroSlot's HID keyCode + modifiers and fires sendCommand.
    func sendMacro(keyCode: Int, modifiers: Int) {
        guard let char = Self.letterForHIDCode(keyCode) else { return }
        sendCommand(char, UIKeyModifierFlags(rawValue: modifiers))
    }

    /// HID usage 4–29 = a–z (keyboard scan order matches ASCII a–z).
    static func letterForHIDCode(_ code: Int) -> String? {
        let idx = code - 4
        guard idx >= 0, idx <= 25 else { return nil }
        return String(UnicodeScalar(Int(("a" as UnicodeScalar).value) + idx)!)
    }
}
