import CoreGraphics

public struct DisplayWorkArea: Equatable, Sendable {
    public let displayID: UInt32
    public let screenFrame: CGRect
    public let usableFrame: CGRect

    public init(displayID: UInt32, screenFrame: CGRect, usableFrame: CGRect) {
        self.displayID = displayID
        self.screenFrame = screenFrame
        self.usableFrame = usableFrame
    }
}

public struct WindowWorkAreaResolver: Sendable {
    private let screenAssigner: WindowScreenAssigner

    public init(screenAssigner: WindowScreenAssigner = WindowScreenAssigner()) {
        self.screenAssigner = screenAssigner
    }

    public func workArea(for window: WindowInfo, among workAreas: [DisplayWorkArea]) -> DisplayWorkArea? {
        let displays = workAreas.map { DisplayDescriptor(id: $0.displayID, frame: $0.screenFrame) }
        guard let displayID = screenAssigner.displayID(for: window, among: displays) else { return nil }
        return workAreas.first { $0.displayID == displayID }
    }
}
