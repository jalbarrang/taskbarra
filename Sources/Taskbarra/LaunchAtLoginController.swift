import Foundation
import ServiceManagement

enum LaunchAtLoginError: LocalizedError {
    case unsupportedStatus(SMAppService.Status)

    var errorDescription: String? {
        switch self {
        case .unsupportedStatus(let status):
            "Launch at login cannot be changed while the service status is \(status.description)."
        }
    }
}

protocol LaunchAtLoginControlling: AnyObject {
    var isEnabled: Bool { get }

    func setEnabled(_ isEnabled: Bool) throws
}

final class LaunchAtLoginController: LaunchAtLoginControlling {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ isEnabled: Bool) throws {
        let service = SMAppService.mainApp

        switch (isEnabled, service.status) {
        case (true, .enabled), (false, .notRegistered):
            return
        case (true, .notRegistered):
            try service.register()
        case (false, .enabled):
            try service.unregister()
        case (_, let status):
            throw LaunchAtLoginError.unsupportedStatus(status)
        }
    }
}

extension SMAppService.Status {
    fileprivate var description: String {
        switch self {
        case .notRegistered:
            "not registered"
        case .enabled:
            "enabled"
        case .requiresApproval:
            "requires approval"
        case .notFound:
            "not found"
        @unknown default:
            "unknown"
        }
    }
}
