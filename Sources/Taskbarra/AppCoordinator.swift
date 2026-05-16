import AppKit
import Foundation

@MainActor
final class AppCoordinator {
    private let accessibilityPermission: AccessibilityPermission
    private let fullDiskAccessPermission: FullDiskAccessPermission
    private var taskbarWindowController: TaskbarWindowController?
    private var onboardingWindowController: PermissionsOnboardingWindowController?
    private var statusItemController: StatusItemController?
    private var permissionMonitorTask: Task<Void, Never>?
    private var hasAccessibilityPermission = false
    private var hasFullDiskAccess = false

    init(
        accessibilityPermission: AccessibilityPermission = AccessibilityPermission(),
        fullDiskAccessPermission: FullDiskAccessPermission = FullDiskAccessPermission()
    ) {
        self.accessibilityPermission = accessibilityPermission
        self.fullDiskAccessPermission = fullDiskAccessPermission
    }

    func start() {
        statusItemController = StatusItemController()
        hasAccessibilityPermission = accessibilityPermission.isTrusted()
        hasFullDiskAccess = fullDiskAccessPermission.isGranted()
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
        let isTrusted = accessibilityPermission.isTrusted()
        let hasFullDiskAccess = fullDiskAccessPermission.isGranted()
        guard isTrusted != hasAccessibilityPermission || hasFullDiskAccess != self.hasFullDiskAccess else { return }

        hasAccessibilityPermission = isTrusted
        self.hasFullDiskAccess = hasFullDiskAccess
        applyCurrentPermissionState()
    }

    private func applyCurrentPermissionState() {
        if hasAccessibilityPermission && hasFullDiskAccess {
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
            onboardingWindowController = PermissionsOnboardingWindowController(
                hasAccessibilityPermission: hasAccessibilityPermission,
                hasFullDiskAccess: hasFullDiskAccess,
                openAccessibilitySettings: { [weak self] in
                    self?.openAccessibilitySettings()
                },
                openFullDiskAccessSettings: { [weak self] in
                    self?.openFullDiskAccessSettings()
                },
                quit: {
                    NSApp.terminate(nil)
                }
            )
        } else {
            onboardingWindowController?.update(
                hasAccessibilityPermission: hasAccessibilityPermission,
                hasFullDiskAccess: hasFullDiskAccess
            )
        }
        onboardingWindowController?.showWindow(nil)
    }

    private func openAccessibilitySettings() {
        accessibilityPermission.promptForTrust()
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    private func openFullDiskAccessSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }
}
