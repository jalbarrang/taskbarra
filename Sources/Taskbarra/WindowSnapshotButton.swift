import AppKit
import SwiftUI
import TaskbarraCore

struct WindowSnapshotButton: View {
    let window: WindowInfo
    let appIcon: NSImage?
    let isActive: Bool
    let isMinimized: Bool
    let notificationCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .help("\(window.ownerName): \(window.title)")
    }

    private var content: some View {
        Group {
            if let appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
            } else {
                Image(systemName: "macwindow")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(width: 22, height: 22)
            }
        }
        .frame(width: 40, height: 34)
        .opacity(isMinimized ? 0.48 : 1)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 7))
        .overlay(alignment: .topTrailing) {
            if notificationCount > 0 {
                Text(notificationBadgeText)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Color.red, in: Capsule())
                    .offset(x: 5, y: -5)
            }
        }
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(indicatorColor)
                .frame(height: isActive ? 4 : 1.5)
                .padding(.horizontal, 8)
                .animation(.easeInOut(duration: 0.12), value: isActive)
        }
    }

    private var backgroundStyle: Color {
        isActive ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.08)
    }

    private var indicatorColor: Color {
        isActive ? Color.accentColor : Color.white.opacity(0.28)
    }

    private var notificationBadgeText: String {
        notificationCount > 99 ? "99+" : String(notificationCount)
    }

    private var accessibilityLabel: String {
        var parts = [window.ownerName, window.displayTitle]
        if isActive { parts.append(L10n.text("window.state.active")) }
        if isMinimized { parts.append(L10n.text("window.state.minimized")) }
        return parts.joined(separator: ", ")
    }
}
