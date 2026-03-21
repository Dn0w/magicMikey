import Foundation

struct Key: Identifiable {
    let id = UUID()
    let label: String
    let secondaryLabel: String?
    /// Text inserted by this key; nil for action/modifier keys.
    let character: String?
    /// Character inserted when Shift is active (e.g. "1" → "!"). Nil for letter keys.
    let shiftedCharacter: String?
    /// Relative width multiplier (1.0 = standard key).
    let width: CGFloat
    let type: KeyType

    enum KeyType {
        case character
        case modifier
        case action
        case space
        case function
    }

    init(_ label: String,
         secondary: String? = nil,
         character: String? = nil,
         shifted: String? = nil,
         width: CGFloat = 1.0,
         type: KeyType = .character) {
        self.label = label
        self.secondaryLabel = secondary
        self.character = character ?? (label.count == 1 ? label.lowercased() : nil)
        self.shiftedCharacter = shifted
        self.width = width
        self.type = type
    }
}
