import AppKit
import Foundation

@MainActor
final class AppCoordinator {
    private let permission: AccessibilityPermission
    private var taskbarWindowController: TaskbarWindowController?
    private var onboardingWindowController: AccessibilityOnboardingWindowController?
    private var statusItemController: StatusItemController?
    private var permissionMonitorTask: Task<Void, Never>?
    private var hasAccessibilityPermission = false

    init(permission: AccessibilityPermission = AccessibilityPermission()) {
        self.permission = permission
    }

    func start() {
        statusItemController = StatusItemController()
        hasAccessibilityPermission = permission.isTrusted()
        applyCurrentPermissionState()
        startMonitoringPermission()
    }

    func stop() {
        permissionMonitorTask?.cancel()
        permissionMonitorTask = nil
        statusItemController?.stop()
        statusItemController = nil
    }

    private func startMonitoringPermission() {
        permissionMonitorTask?.cancel()
        permissionMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    self?.refreshPermissionState()
                }
            }
        }
    }

    private func refreshPermissionState() {
        let isTrusted = permission.isTrusted()
        guard isTrusted != hasAccessibilityPermission else { return }

        hasAccessibilityPermission = isTrusted
        applyCurrentPermissionState()
    }

    private func applyCurrentPermissionState() {
        if hasAccessibilityPermission {
            showTaskbar()
        } else {
            showOnboarding()
        }
    }

    private func showTaskbar() {
        onboardingWindowController?.close()
        onboardingWindowController = nil

        if taskbarWindowController == nil {
            taskbarWindowController = TaskbarWindowController()
        }
        taskbarWindowController?.showWindow(nil)
    }

    private func showOnboarding() {
        taskbarWindowController?.close()
        taskbarWindowController = nil

        if onboardingWindowController == nil {
            onboardingWindowController = AccessibilityOnboardingWindowController(
                openSystemSettings: { [weak self] in
                    self?.openAccessibilitySettings()
                },
                quit: {
                    NSApp.terminate(nil)
                }
            )
        }
        onboardingWindowController?.showWindow(nil)
    }

    private func openAccessibilitySettings() {
        permission.promptForTrust()

        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }
}
