import CoreGraphics
import TaskbarraCore
import XCTest

final class WindowScreenAssignerTests: XCTestCase {
    private let assigner = WindowScreenAssigner()
    private let displays = [
        DisplayDescriptor(id: 10, frame: CGRect(x: 0, y: 0, width: 1000, height: 800)),
        DisplayDescriptor(id: 20, frame: CGRect(x: 1000, y: 0, width: 1000, height: 800)),
    ]

    func testAssignsWindowFullyInsideDisplay() {
        let window = makeWindow(id: 1, bounds: CGRect(x: 100, y: 100, width: 600, height: 500))

        XCTAssertEqual(assigner.displayID(for: window, among: displays), 10)
    }

    func testAssignsStraddlingWindowToLargestIntersection() {
        let window = makeWindow(id: 2, bounds: CGRect(x: 700, y: 100, width: 500, height: 500))

        XCTAssertEqual(assigner.displayID(for: window, among: displays), 10)
    }

    func testReturnsNilForWindowOutsideAllDisplays() {
        let window = makeWindow(id: 3, bounds: CGRect(x: 3000, y: 100, width: 500, height: 500))

        XCTAssertNil(assigner.displayID(for: window, among: displays))
    }

    func testBreaksEqualIntersectionTieWithLowerDisplayID() {
        let reversedDisplays = Array(displays.reversed())
        let window = makeWindow(id: 4, bounds: CGRect(x: 750, y: 100, width: 500, height: 500))

        XCTAssertEqual(assigner.displayID(for: window, among: displays), 10)
        XCTAssertEqual(assigner.displayID(for: window, among: reversedDisplays), 10)
    }

    func testReturnsAssignmentsOnlyForIntersectingWindows() {
        let windows = [
            makeWindow(id: 5, bounds: CGRect(x: 100, y: 100, width: 500, height: 500)),
            makeWindow(id: 6, bounds: CGRect(x: 1100, y: 100, width: 500, height: 500)),
            makeWindow(id: 7, bounds: CGRect(x: 3000, y: 100, width: 500, height: 500)),
        ]

        XCTAssertEqual(assigner.assignments(for: windows, among: displays), [5: 10, 6: 20])
    }

    func testFallsBackToPrimaryDisplayForUnresolvedWindow() {
        let window = makeWindow(id: 8, bounds: CGRect(x: 3000, y: 100, width: 500, height: 500))

        XCTAssertEqual(
            assigner.assignments(for: [window], among: displays, fallbackDisplayID: 10),
            [8: 10]
        )
    }

    private func makeWindow(id: CGWindowID, bounds: CGRect) -> WindowInfo {
        WindowInfo(
            id: id,
            ownerPID: 100,
            ownerName: "Test",
            title: "Window",
            bounds: bounds,
            layer: 0,
            isOnScreen: true
        )
    }
}
