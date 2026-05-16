import CoreGraphics
import TaskbarraCore
import XCTest

final class PassiveAXWindowSnapshotTests: XCTestCase {
    func testSyntheticWindowIDIsDeterministicAndMarkedSynthetic() {
        let snapshot = PassiveAXWindowSnapshot(
            ownerPID: 123,
            ownerName: "Example",
            title: "Minimized",
            frame: CGRect(x: 10, y: 20, width: 300, height: 200),
            isMinimized: true
        )

        XCTAssertEqual(snapshot.syntheticWindowID, snapshot.syntheticWindowID)
        XCTAssertTrue(snapshot.syntheticWindowID & 0x8000_0000 != 0)
    }

    func testWindowInfoPreservesPassiveSnapshotMetadata() {
        let snapshot = PassiveAXWindowSnapshot(
            ownerPID: 123,
            ownerName: "Example",
            title: "Minimized",
            frame: CGRect(x: 10, y: 20, width: 300, height: 200),
            isMinimized: true
        )

        let window = snapshot.windowInfo()

        XCTAssertEqual(window.id, snapshot.syntheticWindowID)
        XCTAssertEqual(window.ownerPID, 123)
        XCTAssertEqual(window.ownerName, "Example")
        XCTAssertEqual(window.title, "Minimized")
        XCTAssertEqual(window.bounds, CGRect(x: 10, y: 20, width: 300, height: 200))
        XCTAssertFalse(window.isOnScreen)
    }
}
