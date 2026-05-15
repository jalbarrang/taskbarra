import CoreGraphics
import Foundation

public struct WindowInfo: Identifiable, Equatable, Sendable {
    public let id: CGWindowID
    public let ownerPID: pid_t
    public let ownerName: String
    public let title: String
    public let bounds: CGRect
    public let layer: Int
    public let isOnScreen: Bool

    public init(
        id: CGWindowID,
        ownerPID: pid_t,
        ownerName: String,
        title: String,
        bounds: CGRect,
        layer: Int,
        isOnScreen: Bool
    ) {
        self.id = id
        self.ownerPID = ownerPID
        self.ownerName = ownerName
        self.title = title
        self.bounds = bounds
        self.layer = layer
        self.isOnScreen = isOnScreen
    }

    public var displayTitle: String {
        title.isEmpty ? ownerName : title
    }

    public func replacingTitle(_ title: String) -> WindowInfo {
        WindowInfo(
            id: id,
            ownerPID: ownerPID,
            ownerName: ownerName,
            title: title,
            bounds: bounds,
            layer: layer,
            isOnScreen: isOnScreen
        )
    }
}
