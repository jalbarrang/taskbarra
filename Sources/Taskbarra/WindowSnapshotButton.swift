import AppKit
import SwiftUI
import TaskbarraCore

struct WindowSnapshotButton: View {
    let window: WindowInfo
    let appIcon: NSImage?

    var body: some View {
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
        .frame(maxWidth: 240, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.28))
                .frame(height: 1)
                .padding(.horizontal, 8)
        }
        .help("\(window.ownerName): \(window.title)")
    }
}
