import CoreGraphics
import Foundation

public struct PassiveAXWindowSnapshot: Equatable, Sendable {
    public let ownerPID: pid_t
    public let ownerName: String
    public let title: String
    public let frame: CGRect
    public let isMinimized: Bool

    public init(ownerPID: pid_t, ownerName: String, title: String, frame: CGRect, isMinimized: Bool) {
        self.ownerPID = ownerPID
        self.ownerName = ownerName
        self.title = title
        self.frame = frame
        self.isMinimized = isMinimized
    }

    public var syntheticWindowID: CGWindowID {
        let keyParts = [
            String(ownerPID),
            ownerName,
            title,
            String(Int(frame.origin.x)),
            String(Int(frame.origin.y)),
            String(Int(frame.width)),
            String(Int(frame.height)),
        ]
        let key = keyParts.joined(separator: "|")
        return CGWindowID(Self.fnv1a32(key) | 0x8000_0000)
    }

    public func windowInfo() -> WindowInfo {
        WindowInfo(
            id: syntheticWindowID,
            ownerPID: ownerPID,
            ownerName: ownerName,
            title: title,
            bounds: frame,
            layer: 0,
            isOnScreen: false
        )
    }

    private static func fnv1a32(_ string: String) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for byte in string.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return hash
    }
}
