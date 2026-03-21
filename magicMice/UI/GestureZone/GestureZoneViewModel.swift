import SwiftUI
import Combine

final class GestureZoneViewModel: ObservableObject {
    @Published var rippleLocation: CGPoint = .zero
    @Published var showRipple: Bool = false

    private let translator = GestureTranslator.shared

    func handlePan(translation: CGSize, velocity: CGSize, state: UIGestureRecognizer.State) {
        guard state == .changed else { return }
        let delta = translator.scrollDelta(from: CGPoint(x: translation.width, y: translation.height))
        // Post synthetic scroll — limited by public APIs; best effort via accessibility
        postScroll(delta: delta)
    }

    func handlePinch(scale: CGFloat, velocity: CGFloat) {
        translator.handlePinch(scale: scale, velocity: velocity)
    }

    func handleThreeFingerSwipe(direction: UISwipeGestureRecognizer.Direction) {
        HapticEngine.shared.keyTap()
        translator.handleThreeFingerSwipe(direction: direction)
    }

    func triggerRipple(at location: CGPoint) {
        rippleLocation = location
        showRipple = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.showRipple = false
        }
    }

    private func postScroll(delta: CGPoint) {
        // Synthetic scroll via UIScrollView is only possible when we own the scroll view.
        // For external-display apps we rely on accessibility scroll actions or
        // UIApplication.shared.sendEvent with a synthetic UIEvent (private API — skipped).
        // Real implementation requires the focused app's scroll view reference.
        _ = delta  // delta computed & ready for future scroll injection
    }
}
