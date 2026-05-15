import SwiftUI

struct TaskbarView: View {
    let windowStore: WindowStore
    let interactionController: WindowInteractionController

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if windowStore.windows.isEmpty {
                    Text(L10n.text("taskbar.empty"))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.68))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 6) {
                            ForEach(windowStore.windows) { window in
                                WindowSnapshotButton(
                                    window: window,
                                    appIcon: windowStore.appIconsByWindowID[window.id],
                                    isActive: window.id == windowStore.activeWindowID,
                                    isMinimized: windowStore.minimizedWindowIDs.contains(window.id)
                                ) {
                                    interactionController.toggle(
                                        window: window,
                                        isActive: window.id == windowStore.activeWindowID
                                    )
                                }
                                .contextMenu {
                                    Button(
                                        windowStore.minimizedWindowIDs.contains(window.id)
                                            ? L10n.text("taskbar.context.restore")
                                            : L10n.text("taskbar.context.minimize")
                                    ) {
                                        interactionController.minimizeOrRestore(window: window)
                                    }
                                    Button(L10n.text("taskbar.context.close_window")) {
                                        interactionController.close(window: window)
                                    }
                                    Divider()
                                    Text(window.ownerName)
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
}
