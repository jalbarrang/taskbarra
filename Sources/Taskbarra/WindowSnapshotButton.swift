import AppKit
import SwiftUI
import TaskbarraCore

struct WindowSnapshotButton: View {
    let window: WindowInfo
    let appIcon: NSImage?
    let isActive: Bool
    let isMinimized: Bool
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
        HStack(spacing: 7) {
            if let appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            } else {
                Image(systemName: "macwindow")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(width: 18, height: 18)
            }

            Text(window.displayTitle)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.90))
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .frame(minWidth: 120, maxWidth: 240, alignment: .leading)
        .opacity(isMinimized ? 0.48 : 1)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 7))
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

    private var accessibilityLabel: String {
        var parts = [window.ownerName, window.displayTitle]
        if isActive { parts.append(L10n.text("window.state.active")) }
        if isMinimized { parts.append(L10n.text("window.state.minimized")) }
        return parts.joined(separator: ", ")
    }
}
