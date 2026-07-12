import AppKit
import CoreGraphics
import SwiftUI
import TaskbarraCore

struct TaskbarView: View {
    let displayID: CGDirectDisplayID
    let windowStore: WindowStore
    let windowDisplayStore: WindowDisplayStore
    let notificationStore: NotificationStore
    let interactionController: WindowInteractionController

    private let deepLinkPolicy = NotificationDeepLinkPolicy()

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if displayedWindows.isEmpty {
                    Text(L10n.text("taskbar.empty"))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.68))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 6) {
                            ForEach(displayedWindows) { window in
                                WindowSnapshotButton(
                                    window: window,
                                    appIcon: windowStore.appIconsByWindowID[window.id],
                                    isActive: window.id == windowStore.activeWindowID,
                                    isMinimized: windowStore.minimizedWindowIDs.contains(window.id),
                                    notificationCount: notificationStore.notificationCount(forOwnerPID: window.ownerPID)
                                ) {
                                    notificationStore.markSeen(ownerPID: window.ownerPID)
                                    interactionController.toggle(
                                        window: window,
                                        isActive: window.id == windowStore.activeWindowID
                                    )
                                }
                                .contextMenu {
                                    Section(L10n.text("taskbar.context.section.windows")) {
                                        ForEach(windows(forSameApplicationAs: window)) { appWindow in
                                            Button {
                                                notificationStore.markSeen(ownerPID: appWindow.ownerPID)
                                                interactionController.activate(window: appWindow)
                                            } label: {
                                                if appWindow.id == windowStore.activeWindowID {
                                                    Label(appWindow.displayTitle, systemImage: "checkmark")
                                                } else if windowStore.minimizedWindowIDs.contains(appWindow.id) {
                                                    Label(appWindow.displayTitle, systemImage: "minus.square")
                                                } else {
                                                    Text(appWindow.displayTitle)
                                                }
                                            }
                                        }
                                    }

                                    let notifications = notificationStore.notifications(forOwnerPID: window.ownerPID)
                                    if !notifications.isEmpty {
                                        Section(L10n.text("taskbar.context.section.notifications")) {
                                            ForEach(notifications) { notification in
                                                if let deepLink = notification.deepLink {
                                                    Button(notificationMenuTitle(notification, deepLink: deepLink)) {
                                                        openNotificationDeepLink(deepLink)
                                                    }
                                                    .disabled(deepLinkPolicy.decision(for: deepLink) == .block)
                                                } else {
                                                    Button(notificationMenuTitle(notification)) {}
                                                        .disabled(true)
                                                }
                                            }
                                            Button(L10n.text("taskbar.context.mark_notifications_seen")) {
                                                notificationStore.markSeen(ownerPID: window.ownerPID)
                                            }
                                        }
                                    }

                                    Section(L10n.text("taskbar.context.section.window")) {
                                        Button(L10n.text("taskbar.context.close_window")) {
                                            interactionController.close(window: window)
                                        }
                                    }

                                    Section(L10n.text("taskbar.context.section.app")) {
                                        Button(L10n.text("taskbar.context.show_all_windows")) {
                                            notificationStore.markSeen(ownerPID: window.ownerPID)
                                            interactionController.showAllWindows(forOwnerPID: window.ownerPID)
                                        }
                                        Button(L10n.text("taskbar.context.hide")) {
                                            interactionController.hideApplication(ownerPID: window.ownerPID)
                                        }
                                        Button(L10n.text("taskbar.context.quit")) {
                                            interactionController.quitApplication(ownerPID: window.ownerPID)
                                        }
                                        Button(L10n.text("taskbar.context.force_quit")) {
                                            interactionController.forceQuitApplication(ownerPID: window.ownerPID)
                                        }
                                        Button(L10n.text("taskbar.context.relaunch")) {
                                            interactionController.relaunchApplication(ownerPID: window.ownerPID)
                                        }
                                        .disabled(!interactionController.supportsRelaunch(ownerPID: window.ownerPID))
                                        Button(L10n.text("taskbar.context.open_in_finder")) {
                                            interactionController.openApplicationInFinder(ownerPID: window.ownerPID)
                                        }
                                        .disabled(
                                            !interactionController.supportsOpenInFinder(ownerPID: window.ownerPID)
                                        )
                                        Button(L10n.text("taskbar.context.copy_bundle_id")) {
                                            interactionController.copyBundleIdentifier(ownerPID: window.ownerPID)
                                        }
                                        .disabled(
                                            !interactionController.supportsCopyBundleIdentifier(
                                                ownerPID: window.ownerPID
                                            )
                                        )
                                        Button(L10n.text("taskbar.context.copy_pid")) {
                                            interactionController.copyProcessIdentifier(ownerPID: window.ownerPID)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Rectangle()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.12))
                        .frame(height: 1)
                }
        )
    }

    private var displayedWindows: [WindowInfo] {
        windowDisplayStore.windows(for: displayID, from: windowStore.windows)
    }

    private func windows(forSameApplicationAs window: WindowInfo) -> [WindowInfo] {
        displayedWindows.filter { $0.ownerPID == window.ownerPID }
    }

    private func notificationMenuTitle(_ notification: AppNotification) -> String {
        let title = NotificationPrivacyFilter.displayTitle(
            for: notification,
            configuration: notificationStore.privacyConfiguration
        ) ?? L10n.text("taskbar.context.notification_hidden")
        guard
            let body = NotificationPrivacyFilter.displayBody(
                for: notification,
                configuration: notificationStore.privacyConfiguration
            ),
            !body.isEmpty
        else { return title }
        return "\(title) — \(body)"
    }

    private func notificationMenuTitle(_ notification: AppNotification, deepLink: URL) -> String {
        let scheme = deepLinkPolicy.schemeDescription(for: deepLink)
        let destination = deepLink.absoluteString
        return String(
            format: L10n.text("taskbar.context.notification_open_destination"),
            notificationMenuTitle(notification),
            scheme,
            destination
        )
    }

    private func openNotificationDeepLink(_ deepLink: URL) {
        switch deepLinkPolicy.decision(for: deepLink) {
        case .allow:
            NSWorkspace.shared.open(deepLink)
        case .confirm:
            if confirmOpeningNotificationDeepLink(deepLink) {
                NSWorkspace.shared.open(deepLink)
            }
        case .block:
            showBlockedNotificationDeepLinkAlert(deepLink)
        }
    }

    private func confirmOpeningNotificationDeepLink(_ deepLink: URL) -> Bool {
        let scheme = deepLinkPolicy.schemeDescription(for: deepLink)
        let alert = NSAlert()
        alert.messageText = L10n.text("notification.deep_link.confirm.title")
        alert.informativeText = String(
            format: L10n.text("notification.deep_link.confirm.message"),
            scheme,
            deepLink.absoluteString
        )
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.text("notification.deep_link.confirm.open"))
        alert.addButton(withTitle: L10n.text("notification.deep_link.confirm.cancel"))
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func showBlockedNotificationDeepLinkAlert(_ deepLink: URL) {
        let scheme = deepLinkPolicy.schemeDescription(for: deepLink)
        let alert = NSAlert()
        alert.messageText = L10n.text("notification.deep_link.blocked.title")
        alert.informativeText = String(
            format: L10n.text("notification.deep_link.blocked.message"),
            scheme,
            deepLink.absoluteString
        )
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.text("common.ok"))
        alert.runModal()
    }
}
