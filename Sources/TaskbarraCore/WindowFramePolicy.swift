import CoreGraphics
import Foundation

public struct WindowFramePolicy: Sendable {
    public let tolerance: CGFloat

    public init(tolerance: CGFloat = 8) {
        self.tolerance = tolerance
    }

    public func shouldMoveMaximizedWindow(
        windowFrame: CGRect,
        screenFrame: CGRect,
        usableFrame: CGRect,
        lastAppliedFrame: CGRect? = nil
    ) -> Bool {
        guard !windowFrame.isNull, !screenFrame.isNull, !usableFrame.isNull else { return false }
        guard windowFrame.width > 0, windowFrame.height > 0 else { return false }
        guard screenFrame.contains(windowFrame.center, tolerance: tolerance) else { return false }

        if isApproximatelyEqual(windowFrame, usableFrame) {
            return false
        }

        if let lastAppliedFrame, isApproximatelyEqual(windowFrame, lastAppliedFrame) {
            return !isApproximatelyEqual(lastAppliedFrame, usableFrame)
        }

        return isMaximizedLike(windowFrame: windowFrame, screenFrame: screenFrame, usableFrame: usableFrame)
    }

    public func isMaximizedLike(windowFrame: CGRect, screenFrame: CGRect, usableFrame: CGRect) -> Bool {
        let fillsScreen = isApproximatelyEqual(windowFrame, screenFrame)
        let spansScreenWidth =
            approximatelyEqual(windowFrame.minX, screenFrame.minX)
            && approximatelyEqual(windowFrame.width, screenFrame.width)
        let touchesTopAndBottom =
            approximatelyEqual(windowFrame.minY, screenFrame.minY)
            && approximatelyEqual(windowFrame.maxY, screenFrame.maxY)
        let overlapsReservedTaskbar = windowFrame.minY < usableFrame.minY - tolerance
        let fillsUsableHeight = windowFrame.height >= usableFrame.height - tolerance
        let reachesVerticalBounds = touchesTopAndBottom || fillsUsableHeight
        let isFullWidthMaximized = spansScreenWidth && overlapsReservedTaskbar && reachesVerticalBounds
        return fillsScreen || isFullWidthMaximized
    }

    public func isApproximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        approximatelyEqual(lhs.minX, rhs.minX)
            && approximatelyEqual(lhs.minY, rhs.minY)
            && approximatelyEqual(lhs.width, rhs.width)
            && approximatelyEqual(lhs.height, rhs.height)
    }

    private func approximatelyEqual(_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}

extension CGRect {
    fileprivate var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    fileprivate func contains(_ point: CGPoint, tolerance: CGFloat) -> Bool {
        point.x >= minX - tolerance
            && point.x <= maxX + tolerance
            && point.y >= minY - tolerance
            && point.y <= maxY + tolerance
    }
}
