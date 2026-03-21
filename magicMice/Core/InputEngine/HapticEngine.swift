import UIKit

final class HapticEngine {
    static let shared = HapticEngine()

    private let light   = UIImpactFeedbackGenerator(style: .light)
    private let medium  = UIImpactFeedbackGenerator(style: .medium)
    private let heavy   = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid   = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        [light, medium, heavy, rigid].forEach { $0.prepare() }
    }

    enum Intensity { case light, medium, heavy }

    var intensity: Intensity = .medium
    var isEnabled: Bool = true

    func keyTap() {
        guard isEnabled else { return }
        switch intensity {
        case .light:  light.impactOccurred()
        case .medium: medium.impactOccurred()
        case .heavy:  heavy.impactOccurred()
        }
    }

    func macroTap() {
        guard isEnabled else { return }
        rigid.impactOccurred(intensity: 0.9)
    }

    func modifierArmed() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.6)
    }

    func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }
}
