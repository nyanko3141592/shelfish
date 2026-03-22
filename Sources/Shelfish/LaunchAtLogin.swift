import Foundation
import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func enable() {
        try? SMAppService.mainApp.register()
    }

    static func disable() {
        try? SMAppService.mainApp.unregister()
    }

    static func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}
