import UIKit

/// Translates raw gesture recognizer events into scroll events and key commands.
final class GestureTranslator {
    static let shared = GestureTranslator()
    private init() {}

    var scrollSensitivity: CGFloat = 3.0   // 1–5 scale, multiplied onto delta
    var naturalScrolling: Bool = true

    // MARK: - Scroll

    /// Convert a pan gesture translation delta into a synthetic scroll event.
    /// Returns the adjusted delta after applying sensitivity + direction.
    func scrollDelta(from rawDelta: CGPoint) -> CGPoint {
        let direction: CGFloat = naturalScrolling ? 1 : -1
        return CGPoint(
            x: rawDelta.x * scrollSensitivity * direction,
            y: rawDelta.y * scrollSensitivity * direction
        )
    }

    // MARK: - Pinch → Zoom

    func handlePinch(scale: CGFloat, velocity: CGFloat) {
        guard abs(velocity) > 0.1 else { return }
        let input = scale > 1 ? "+" : "-"
        KeyDispatcher.shared.sendKeyCommand(input: input, modifiers: .command)
    }

    // MARK: - Multi-finger swipes

    func handleThreeFingerSwipe(direction: UISwipeGestureRecognizer.Direction) {
        switch direction {
        case .left:
            KeyDispatcher.shared.sendKeyCommand(input: "[", modifiers: .command)
        case .right:
            KeyDispatcher.shared.sendKeyCommand(input: "]", modifiers: .command)
        case .up:
            KeyDispatcher.shared.sendKeyCommand(input: UIKeyCommand.inputUpArrow, modifiers: .command)
        default:
            break
        }
    }
}
