import AppKit
import SwiftUI

@MainActor
final class PermissionsOnboardingWindowController: NSWindowController {
    private let openAccessibilitySettings: () -> Void
    private let openFullDiskAccessSettings: () -> Void
    private let quit: () -> Void

    init(
        hasAccessibilityPermission: Bool,
        hasFullDiskAccess: Bool,
        openAccessibilitySettings: @escaping () -> Void,
        openFullDiskAccessSettings: @escaping () -> Void,
        quit: @escaping () -> Void
    ) {
        self.openAccessibilitySettings = openAccessibilitySettings
        self.openFullDiskAccessSettings = openFullDiskAccessSettings
        self.quit = quit

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text("permissions.onboarding.window_title")
        window.isReleasedWhenClosed = false
        window.center()
        window.appearance = NSAppearance(named: .darkAqua)

        super.init(window: window)
        update(hasAccessibilityPermission: hasAccessibilityPermission, hasFullDiskAccess: hasFullDiskAccess)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func update(hasAccessibilityPermission: Bool, hasFullDiskAccess: Bool) {
        let view = PermissionsOnboardingView(
            hasAccessibilityPermission: hasAccessibilityPermission,
            hasFullDiskAccess: hasFullDiskAccess,
            openAccessibilitySettings: openAccessibilitySettings,
            openFullDiskAccessSettings: openFullDiskAccessSettings,
            quit: quit
        )
        .preferredColorScheme(.dark)

        window?.contentView = NSHostingView(rootView: view)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}
