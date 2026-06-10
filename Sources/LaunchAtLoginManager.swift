import Foundation
import ServiceManagement

enum LaunchAtLoginManager {

    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return legacyPlistExists()
        }
    }

    static func enable() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.register()
        } else {
            installLegacyAgent()
        }
    }

    static func disable() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.unregister()
        } else {
            removeLegacyAgent()
        }
    }

    static func toggle() {
        isEnabled ? disable() : enable()
    }

    // MARK: - Legacy LaunchAgent (macOS < 13)

    private static var agentPlistURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        return dir.appendingPathComponent("com.thaiswitcher.app.plist")
    }

    private static func legacyPlistExists() -> Bool {
        FileManager.default.fileExists(atPath: agentPlistURL.path)
    }

    private static func installLegacyAgent() {
        guard let bundlePath = Bundle.main.executablePath else { return }
        let plist: [String: Any] = [
            "Label": "com.thaiswitcher.app",
            "ProgramArguments": [bundlePath],
            "RunAtLoad": true,
            "KeepAlive": false,
        ]
        let dir = agentPlistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? (plist as NSDictionary).write(to: agentPlistURL)
        Process.launchedProcess(launchPath: "/bin/launchctl",
                                arguments: ["load", agentPlistURL.path])
    }

    private static func removeLegacyAgent() {
        Process.launchedProcess(launchPath: "/bin/launchctl",
                                arguments: ["unload", agentPlistURL.path])
        try? FileManager.default.removeItem(at: agentPlistURL)
    }
}
