import UIKit
import SwiftUI
import SwiftData

/// UIInputViewController — the keyboard extension entry point.
/// Hosts ExtensionKeyboardView and routes all input through UITextDocumentProxy,
/// giving full compatibility with every app that accepts keyboard input.
class KeyboardViewController: UIInputViewController {

    private let router = InputRouter()
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Wire InputRouter → textDocumentProxy (the system keyboard bridge)
        router.insertText = { [weak self] text in
            self?.textDocumentProxy.insertText(text)
        }
        router.deleteBackward = { [weak self] in
            self?.textDocumentProxy.deleteBackward()
        }
        router.sendCommand = { [weak self] input, modifiers in
            self?.handleCommand(input: input, modifiers: modifiers)
        }

        // Build SwiftUI view tree
        let container = try? ModelContainer(for: MacroSlot.self)
        let rootView = AnyView(
            Group {
                if let container {
                    ExtensionKeyboardView()
                        .environmentObject(router)
                        .modelContainer(container)
                } else {
                    ExtensionKeyboardView()
                        .environmentObject(router)
                }
            }
        )

        let hostVC = UIHostingController(rootView: rootView)
        hostVC.view.backgroundColor = .clear
        addChild(hostVC)
        view.addSubview(hostVC.view)
        hostVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostVC.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            hostVC.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            hostVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostVC.didMove(toParent: self)

        // Explicit height constraint — more reliable than preferredContentSize alone
        let hc = NSLayoutConstraint(item: view!, attribute: .height,
                                    relatedBy: .equal,
                                    toItem: nil, attribute: .notAnAttribute,
                                    multiplier: 1, constant: keyboardHeight())
        hc.priority = UILayoutPriority(999)
        view.addConstraint(hc)
        heightConstraint = hc
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let h = keyboardHeight()
        heightConstraint?.constant = h
        preferredContentSize = CGSize(width: 0, height: h)
    }

    private func keyboardHeight() -> CGFloat {
        let screen = UIScreen.main.bounds.size
        let isPortrait = screen.height > screen.width
        return isPortrait ? screen.height * 0.35 : screen.height * 0.45
    }

    // MARK: - Command routing

    private func handleCommand(input: String, modifiers: UIKeyModifierFlags) {
        // Cursor movement — textDocumentProxy has direct support
        switch input {
        case UIKeyCommand.inputLeftArrow:
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
        case UIKeyCommand.inputRightArrow:
            textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
        case UIKeyCommand.inputUpArrow:
            // Move to beginning of line (approximate)
            for _ in 0..<80 { textDocumentProxy.adjustTextPosition(byCharacterOffset: -1) }
        case UIKeyCommand.inputDownArrow:
            for _ in 0..<80 { textDocumentProxy.adjustTextPosition(byCharacterOffset: 1) }
        default:
            // Modifier shortcuts (⌘C, ⌘V, etc.) cannot cross the extension sandbox.
            // Plain text with no modifiers: insert directly.
            if modifiers.isEmpty || modifiers == .alphaShift {
                textDocumentProxy.insertText(input)
            }
            // TODO: ⌘-shortcuts require a companion app or Accessibility API (future v2)
        }
    }
}
