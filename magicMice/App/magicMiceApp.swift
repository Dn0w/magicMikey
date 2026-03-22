import SwiftUI
import SwiftData

@main
struct magicMiceApp: App {
    @StateObject private var router: InputRouter = {
        let r = InputRouter()
        r.insertText   = { KeyDispatcher.shared.insertText($0) }
        r.deleteBackward = { KeyDispatcher.shared.deleteBackward() }
        r.sendCommand  = { KeyDispatcher.shared.sendKeyCommand(input: $0, modifiers: $1) }
        return r
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .modelContainer(for: MacroSlot.self)
        }
    }
}
