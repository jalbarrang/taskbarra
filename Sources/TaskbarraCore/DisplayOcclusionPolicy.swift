import CoreGraphics

public struct DisplayOcclusionPolicy: Sendable {
    public let tolerance: CGFloat

    public init(tolerance: CGFloat = 4) {
        self.tolerance = tolerance
    }

    public func occludedDisplayIDs(
        windows: [WindowInfo],
        displays: [DisplayDescriptor]
    ) -> Set<UInt32> {
        Set(displays.compactMap { display in
            windows.contains { window in
                window.layer == 0
                    && window.isOnScreen
                    && encloses(window.bounds, display.frame)
            } ? display.id : nil
        })
    }

    private func encloses(_ windowFrame: CGRect, _ displayFrame: CGRect) -> Bool {
        guard !windowFrame.isNull, !windowFrame.isEmpty, !displayFrame.isNull, !displayFrame.isEmpty else {
            return false
        }
        return windowFrame.minX <= displayFrame.minX + tolerance
            && windowFrame.minY <= displayFrame.minY + tolerance
            && windowFrame.maxX >= displayFrame.maxX - tolerance
            && windowFrame.maxY >= displayFrame.maxY - tolerance
    }
}
