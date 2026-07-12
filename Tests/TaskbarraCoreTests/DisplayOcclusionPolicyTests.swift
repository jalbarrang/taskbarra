import CoreGraphics
import TaskbarraCore
import XCTest

final class DisplayOcclusionPolicyTests: XCTestCase {
    private let policy = DisplayOcclusionPolicy(tolerance: 4)
    private let displays = [
        DisplayDescriptor(id: 10, frame: CGRect(x: 0, y: 0, width: 1000, height: 800)),
        DisplayDescriptor(id: 20, frame: CGRect(x: 1000, y: 0, width: 1200, height: 900)),
    ]

    func testFullscreenWindowOccludesOnlyItsDisplay() {
        let window = makeWindow(bounds: CGRect(x: 1000, y: 0, width: 1200, height: 900))

        XCTAssertEqual(policy.occludedDisplayIDs(windows: [window], displays: displays), [20])
    }

    func testMaximizedWindowAboveTaskbarDoesNotOccludeDisplay() {
        let window = makeWindow(bounds: CGRect(x: 0, y: 0, width: 1000, height: 752))

        XCTAssertEqual(policy.occludedDisplayIDs(windows: [window], displays: displays), [])
    }

    func testFullscreenWindowsCanOccludeTwoDisplaysIndependently() {
        let windows = [
            makeWindow(id: 1, bounds: CGRect(x: 0, y: 0, width: 1000, height: 800)),
            makeWindow(id: 2, bounds: CGRect(x: 1000, y: 0, width: 1200, height: 900)),
        ]

        XCTAssertEqual(policy.occludedDisplayIDs(windows: windows, displays: displays), [10, 20])
    }

    func testIgnoresMinimizedAndNonstandardLayerWindows() {
        let minimized = makeWindow(bounds: displays[0].frame, isOnScreen: false)
        let overlay = makeWindow(id: 2, bounds: displays[1].frame, layer: 1)

        XCTAssertEqual(policy.occludedDisplayIDs(windows: [minimized, overlay], displays: displays), [])
    }

    private func makeWindow(
        id: CGWindowID = 1,
        bounds: CGRect,
        layer: Int = 0,
        isOnScreen: Bool = true
    ) -> WindowInfo {
        WindowInfo(
            id: id,
            ownerPID: 100,
            ownerName: "Test",
            title: "Window",
            bounds: bounds,
            layer: layer,
            isOnScreen: isOnScreen
        )
    }
}
