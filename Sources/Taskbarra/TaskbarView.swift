import SwiftUI

struct TaskbarView: View {
    let windowStore: WindowStore

    var body: some View {
        HStack(spacing: 8) {
            Text("Taskbarra")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))

            Divider()
                .frame(height: 24)
                .overlay(.white.opacity(0.18))

            Group {
                if windowStore.windows.isEmpty {
                    Text("Sin ventanas detectadas")
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
                                )
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
