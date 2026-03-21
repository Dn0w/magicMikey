import SwiftData
import Foundation

/// Bootstraps default macro slots on first launch.
final class MacroStore {
    static func seedDefaultsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<MacroSlot>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        MacroSlot.makeDefaults().forEach { context.insert($0) }
        try? context.save()
    }
}
