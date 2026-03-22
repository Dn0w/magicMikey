import Foundation

/// Minimal plugin protocol. Conform to this to create a removable feature plugin.
protocol MagicMicePlugin: AnyObject {
    /// Unique reverse-DNS identifier for the plugin.
    static var id: String { get }
    /// Called once when the plugin is registered. Set up observers, windows, etc.
    func activate()
    /// Called to fully tear down the plugin. Must undo everything in activate().
    func deactivate()
}

/// Registers and owns all active plugins.
/// To add a plugin: PluginManager.shared.register(MyPlugin())
/// To remove a plugin: delete its files and the register() call.
final class PluginManager {
    static let shared = PluginManager()
    private var plugins: [any MagicMicePlugin] = []
    private init() {}

    func register(_ plugin: any MagicMicePlugin) {
        plugins.append(plugin)
        plugin.activate()
    }
}
