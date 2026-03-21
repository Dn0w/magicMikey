import UIKit
import Combine

/// Observes external display connection/disconnection.
final class DisplayMonitor: ObservableObject {
    @Published var isExternalDisplayConnected: Bool = false

    static let shared = DisplayMonitor()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        update()
        NotificationCenter.default.publisher(for: UIScreen.didConnectNotification)
            .sink { [weak self] _ in self?.update() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: UIScreen.didDisconnectNotification)
            .sink { [weak self] _ in self?.update() }
            .store(in: &cancellables)
    }

    private func update() {
        isExternalDisplayConnected = UIScreen.screens.count > 1
    }
}
