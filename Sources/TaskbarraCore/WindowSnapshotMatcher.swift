import CoreGraphics
import Foundation

public struct WindowSnapshotMatcher: Sendable {
    private let frameTolerance: CGFloat

    public init(frameTolerance: CGFloat = 24) {
        self.frameTolerance = frameTolerance
    }

    public func visibleCounterpart(
        for snapshot: PassiveAXWindowSnapshot,
        in windows: [WindowInfo]
    ) -> WindowInfo? {
        windows.first { isCounterpart(snapshot, of: $0, requireFrameMatch: true) }
            ?? windows.only { isCounterpart(snapshot, of: $0, requireFrameMatch: false) }
    }

    public func isCounterpart(
        _ snapshot: PassiveAXWindowSnapshot,
        of window: WindowInfo,
        requireFrameMatch: Bool = true
    ) -> Bool {
        guard window.ownerPID == snapshot.ownerPID else { return false }
        guard titlesAreCompatible(snapshot.title, window.title) else { return false }
        guard requireFrameMatch else { return true }
        return framesAreCompatible(snapshot.frame, window.bounds)
    }

    private func titlesAreCompatible(_ lhs: String, _ rhs: String) -> Bool {
        let lhs = lhs.trimmingCharacters(in: .whitespacesAndNewlines)
        let rhs = rhs.trimmingCharacters(in: .whitespacesAndNewlines)
        return lhs.isEmpty || rhs.isEmpty || lhs == rhs
    }

    private func framesAreCompatible(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        guard !lhs.isEmpty, !rhs.isEmpty else { return false }
        return abs(lhs.origin.x - rhs.origin.x) <= frameTolerance
            && abs(lhs.origin.y - rhs.origin.y) <= frameTolerance
            && abs(lhs.width - rhs.width) <= frameTolerance
            && abs(lhs.height - rhs.height) <= frameTolerance
    }
}

private extension Array {
    func only(where predicate: (Element) -> Bool) -> Element? {
        var result: Element?
        for element in self where predicate(element) {
            guard result == nil else { return nil }
            result = element
        }
        return result
    }
}
