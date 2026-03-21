import Foundation

enum LayoutMode: String, CaseIterable, Identifiable {
    case full         = "Full"
    case keyboardOnly = "Keyboard Only"
    case trackpadOnly = "Trackpad Only"
    case macroPad     = "Macro Pad"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .full:         return "rectangle.split.3x1"
        case .keyboardOnly: return "keyboard"
        case .trackpadOnly: return "hand.point.up.left"
        case .macroPad:     return "grid"
        }
    }
}
