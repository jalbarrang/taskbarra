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
                                    Section(L10n.text("taskbar.context.section.window")) {
                                        Button(L10n.text("taskbar.context.close_window")) {
                                            interactionController.close(window: window)
                                        }
                                    }

                                    Section(L10n.text("taskbar.context.section.app")) {
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

}
