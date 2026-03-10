import Foundation

enum LaunchAtLogin {
    private static let label = "com.shelfish.app"

    private static var plistURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func enable() {
        let executablePath = ProcessInfo.processInfo.arguments[0]

        // Resolve to .app path if running inside a bundle
        let appPath: String
        if let range = executablePath.range(of: ".app/") {
            appPath = String(executablePath[..<range.upperBound])
            // Use open -a for .app bundles
        } else {
            appPath = executablePath
        }

        let plist: [String: Any]
        if executablePath.contains(".app/") {
            plist = [
                "Label": label,
                "ProgramArguments": ["/usr/bin/open", "-a", appPath],
                "RunAtLoad": true,
            ]
        } else {
            plist = [
                "Label": label,
                "ProgramArguments": [executablePath],
                "RunAtLoad": true,
            ]
        }

        // Ensure LaunchAgents directory exists
        let dir = plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let data = try? PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try? data?.write(to: plistURL, options: .atomic)
    }

    static func disable() {
        try? FileManager.default.removeItem(at: plistURL)
    }

    static func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}
