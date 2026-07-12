import CoreGraphics

public struct DisplayDescriptor: Equatable, Sendable {
    public let id: UInt32
    public let frame: CGRect

    public init(id: UInt32, frame: CGRect) {
        self.id = id
        self.frame = frame
    }
}

public struct WindowScreenAssigner: Sendable {
    public init() {}

    public func displayID(for window: WindowInfo, among displays: [DisplayDescriptor]) -> UInt32? {
        displayID(for: window.bounds, among: displays)
    }

    public func displayID(for bounds: CGRect, among displays: [DisplayDescriptor]) -> UInt32? {
        displays
            .compactMap { display -> (id: UInt32, area: CGFloat)? in
                let intersection = bounds.intersection(display.frame)
                guard !intersection.isNull, !intersection.isEmpty else { return nil }
                return (display.id, intersection.width * intersection.height)
            }
            .filter { $0.area > 0 }
            .max { lhs, rhs in
                if lhs.area == rhs.area {
                    return lhs.id > rhs.id
                }
                return lhs.area < rhs.area
            }?
            .id
    }

    public func assignments(
        for windows: [WindowInfo],
        among displays: [DisplayDescriptor],
        fallbackDisplayID: UInt32? = nil
    ) -> [WindowInfo.ID: UInt32] {
        Dictionary(
            uniqueKeysWithValues: windows.compactMap { window in
                let assignedDisplayID = displayID(for: window, among: displays) ?? fallbackDisplayID
                return assignedDisplayID.map { (window.id, $0) }
            }
        )
    }
}
