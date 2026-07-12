import CoreGraphics
import TaskbarraCore
import XCTest

final class WindowWorkAreaResolverTests: XCTestCase {
    private let resolver = WindowWorkAreaResolver()
    private let workAreas = [
        DisplayWorkArea(
            displayID: 10,
            screenFrame: CGRect(x: 0, y: 0, width: 1000, height: 800),
            usableFrame: CGRect(x: 0, y: 0, width: 1000, height: 752)
        ),
        DisplayWorkArea(
            displayID: 20,
            screenFrame: CGRect(x: 1000, y: 0, width: 1200, height: 900),
            usableFrame: CGRect(x: 1000, y: 0, width: 1200, height: 852)
        ),
    ]

    func testReturnsUsableFrameFromAssignedDisplay() throws {
        let window = makeWindow(bounds: CGRect(x: 1100, y: 0, width: 1100, height: 900))

        let workArea = try XCTUnwrap(resolver.workArea(for: window, among: workAreas))

        XCTAssertEqual(workArea.displayID, 20)
        XCTAssertEqual(workArea.usableFrame, CGRect(x: 1000, y: 0, width: 1200, height: 852))
    }

    func testStraddlingWindowUsesMatchingDisplayWorkArea() throws {
        let window = makeWindow(bounds: CGRect(x: 800, y: 100, width: 700, height: 500))

        let workArea = try XCTUnwrap(resolver.workArea(for: window, among: workAreas))

        XCTAssertEqual(workArea.displayID, 20)
        XCTAssertEqual(workArea.screenFrame.minX, workArea.usableFrame.minX)
    }

    func testReturnsNilInsteadOfApplyingUnrelatedFrame() {
        let window = makeWindow(bounds: CGRect(x: 3000, y: 0, width: 500, height: 500))

        XCTAssertNil(resolver.workArea(for: window, among: workAreas))
    }

    private func makeWindow(bounds: CGRect) -> WindowInfo {
        WindowInfo(
            id: 1,
            ownerPID: 100,
            ownerName: "Test",
            title: "Window",
            bounds: bounds,
            layer: 0,
            isOnScreen: true
        )
    }
}
