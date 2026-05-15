import CoreGraphics
import Foundation

struct WindowInfo: Identifiable, Equatable, Sendable {
    let id: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let title: String
    let bounds: CGRect
    let layer: Int
    let isOnScreen: Bool

    var displayTitle: String {
        title.isEmpty ? ownerName : title
    }
}
