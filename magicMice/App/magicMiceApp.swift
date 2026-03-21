import SwiftUI
import SwiftData

@main
struct magicMiceApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: MacroSlot.self)
        }
    }
}
