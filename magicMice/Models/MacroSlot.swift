import Foundation
import SwiftData

@Model
final class MacroSlot {
    var id: UUID
    var label: String
    var systemImage: String?
    /// UIKeyboardHIDUsage raw value
    var keyCode: Int
    /// UIKeyModifierFlags raw value
    var modifiers: Int
    var sortOrder: Int
    var colorHex: String?

    init(id: UUID = UUID(),
         label: String,
         systemImage: String? = nil,
         keyCode: Int,
         modifiers: Int,
         sortOrder: Int,
         colorHex: String? = nil) {
        self.id = id
        self.label = label
        self.systemImage = systemImage
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.sortOrder = sortOrder
        self.colorHex = colorHex
    }
}

extension MacroSlot {
    // UIKeyModifierFlags.command.rawValue == 1 << 20
    private static let command = 1 << 20

    static func makeDefaults() -> [MacroSlot] {
        // HID usage codes: A=4 C=6 S=22 T=23 V=25 W=26 X=27 Z=29
        let entries: [(String, String, Int)] = [
            ("⌘Z", "arrow.uturn.backward",  29),
            ("⌘X", "scissors",              27),
            ("⌘C", "doc.on.doc",             6),
            ("⌘V", "clipboard",             25),
            ("⌘S", "square.and.arrow.down", 22),
            ("⌘A", "a.square",               4),
            ("⌘W", "xmark",                 26),
            ("⌘T", "plus.square",           23),
        ]
        return entries.enumerated().map { index, entry in
            MacroSlot(label: entry.0, systemImage: entry.1,
                      keyCode: entry.2, modifiers: command, sortOrder: index)
        }
    }
}
