import Foundation
import ServiceManagement

enum LaunchAtLoginError: LocalizedError {
    case unsupportedStatus(SMAppService.Status)

    var errorDescription: String? {
        switch self {
        case .unsupportedStatus(let status):
            String(
                format: L10n.text("launch_at_login.error.unsupported_status"),
                status.description
            )
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
            L10n.text("launch_at_login.status.not_registered")
        case .enabled:
            L10n.text("launch_at_login.status.enabled")
        case .requiresApproval:
            L10n.text("launch_at_login.status.requires_approval")
        case .notFound:
            L10n.text("launch_at_login.status.not_found")
        @unknown default:
            L10n.text("launch_at_login.status.unknown")
        }
    }
}
