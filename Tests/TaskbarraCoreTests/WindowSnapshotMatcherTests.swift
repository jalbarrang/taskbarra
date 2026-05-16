import CoreGraphics
import TaskbarraCore
import XCTest

final class WindowSnapshotMatcherTests: XCTestCase {
    func testMatchesByPIDTitleAndNearbyFrame() {
        let matcher = WindowSnapshotMatcher(frameTolerance: 10)
        let window = makeWindow(
            ownerPID: 42,
            title: "Inbox",
            bounds: CGRect(x: 100, y: 100, width: 800, height: 600)
        )
        let snapshot = makeSnapshot(
            ownerPID: 42,
            title: "Inbox",
            frame: CGRect(x: 104, y: 96, width: 804, height: 596)
        )

        XCTAssertTrue(matcher.isCounterpart(snapshot, of: window))
        XCTAssertEqual(matcher.visibleCounterpart(for: snapshot, in: [window]), window)
    }

    func testRejectsDifferentPIDAndIncompatibleTitle() {
        let matcher = WindowSnapshotMatcher()
        let window = makeWindow(ownerPID: 42, title: "Inbox")

        XCTAssertFalse(matcher.isCounterpart(makeSnapshot(ownerPID: 99, title: "Inbox"), of: window))
        XCTAssertFalse(matcher.isCounterpart(makeSnapshot(ownerPID: 42, title: "Calendar"), of: window))
    }

    func testAllowsMissingTitlesButRequiresUniqueFallbackMatch() {
        let matcher = WindowSnapshotMatcher()
        let first = makeWindow(id: 1, ownerPID: 42, title: "")
        let second = makeWindow(id: 2, ownerPID: 42, title: "")
        let snapshot = makeSnapshot(ownerPID: 42, title: "", frame: .zero)

        XCTAssertEqual(matcher.visibleCounterpart(for: snapshot, in: [first]), first)
        XCTAssertNil(matcher.visibleCounterpart(for: snapshot, in: [first, second]))
    }

    private func makeWindow(
        id: CGWindowID = 1,
        ownerPID: pid_t,
        title: String,
        bounds: CGRect = CGRect(x: 10, y: 20, width: 300, height: 200)
    ) -> WindowInfo {
        WindowInfo(
            id: id,
            ownerPID: ownerPID,
            ownerName: "Example",
            title: title,
            bounds: bounds,
            layer: 0,
            isOnScreen: true
        )
    }

    private func makeSnapshot(
        ownerPID: pid_t,
        title: String,
        frame: CGRect = CGRect(x: 10, y: 20, width: 300, height: 200)
    ) -> PassiveAXWindowSnapshot {
        PassiveAXWindowSnapshot(
            ownerPID: ownerPID,
            ownerName: "Example",
            title: title,
            frame: frame,
            isMinimized: true
        )
    }
}
