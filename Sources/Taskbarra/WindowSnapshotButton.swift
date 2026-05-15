import SwiftUI
import TaskbarraCore

struct WindowSnapshotButton: View {
    let window: WindowInfo

    var body: some View {
        Text(window.displayTitle)
            .font(.system(size: 12, weight: .medium))
            .lineLimit(1)
            .foregroundStyle(.white.opacity(0.90))
            .padding(.horizontal, 10)
            .frame(height: 34)
            .frame(maxWidth: 220, alignment: .leading)
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
