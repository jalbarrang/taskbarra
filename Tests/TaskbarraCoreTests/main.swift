import CoreGraphics
import Foundation
import TaskbarraCore
import XCTest

private final class StubWindowInfoProvider: WindowInfoProviding {
    let windows: [[String: Any]]
    private(set) var requestedOptions: CGWindowListOption?

    init(windows: [[String: Any]]) {
        self.windows = windows
    }

    func copyWindowInfo(options: CGWindowListOption, relativeToWindow windowID: CGWindowID) -> [[String: Any]] {
        requestedOptions = options
        return windows
    }
}

final class TaskbarraCoreTests: XCTestCase {
    func testParsesWindowInfo() throws {
        let dictionary = makeWindowDictionary(
            id: 42,
            ownerPID: 100,
            ownerName: "Safari",
            title: "Example Page",
            bounds: CGRect(x: 10, y: 20, width: 800, height: 600)
        )

        let window = try XCTUnwrap(WindowScanner.parseWindowInfo(dictionary))

        XCTAssertEqual(window.id, 42)
        XCTAssertEqual(window.ownerPID, 100)
        XCTAssertEqual(window.ownerName, "Safari")
        XCTAssertEqual(window.title, "Example Page")
        XCTAssertEqual(window.bounds, CGRect(x: 10, y: 20, width: 800, height: 600))
        XCTAssertEqual(window.layer, 0)
        XCTAssertTrue(window.isOnScreen)
    }

    func testRejectsMalformedDictionaries() {
        XCTAssertNil(WindowScanner.parseWindowInfo([:]))
    }

    func testFiltersIrrelevantWindows() {
        let scanner = WindowScanner(currentProcessID: 999, ignoredOwnerNames: ["Dock"])

        XCTAssertTrue(scanner.isRelevantWindow(makeWindow()))
        XCTAssertFalse(scanner.isRelevantWindow(makeWindow(ownerPID: 999)))
        XCTAssertFalse(scanner.isRelevantWindow(makeWindow(ownerName: "Dock")))
        XCTAssertTrue(scanner.isRelevantWindow(makeWindow(title: "   ")))
        XCTAssertFalse(scanner.isRelevantWindow(makeWindow(layer: 1)))
        XCTAssertFalse(scanner.isRelevantWindow(makeWindow(isOnScreen: false)))
        XCTAssertFalse(scanner.isRelevantWindow(makeWindow(bounds: CGRect(x: 0, y: 0, width: 79, height: 600))))
        XCTAssertFalse(scanner.isRelevantWindow(makeWindow(bounds: CGRect(x: 0, y: 0, width: 800, height: 39))))
    }

    func testScansRelevantWindowsInStableOrder() {
        let provider = StubWindowInfoProvider(windows: [
            makeWindowDictionary(id: 3, ownerPID: 100, ownerName: "Safari", title: "Zeta"),
            makeWindowDictionary(id: 4, ownerPID: 100, ownerName: "Dock", title: "Dock Window"),
            makeWindowDictionary(id: 2, ownerPID: 101, ownerName: "Finder", title: "Downloads"),
            makeWindowDictionary(id: 1, ownerPID: 102, ownerName: "Finder", title: "Applications"),
        ])
        let scanner = WindowScanner(currentProcessID: 999, provider: provider, ignoredOwnerNames: ["Dock"])

        let windows = scanner.scan(options: .optionAll)

        XCTAssertEqual(windows.map(\.id), [1, 2, 3])
    }

    func testVisibleScanUsesActiveSpaceOptions() {
        let provider = StubWindowInfoProvider(windows: [makeWindowDictionary()])
        let scanner = WindowScanner(currentProcessID: 999, provider: provider)

        _ = scanner.scanVisibleWindows()

        XCTAssertEqual(provider.requestedOptions, [.optionOnScreenOnly, .excludeDesktopElements])
    }

    func testScansUntitledWindows() {
        let provider = StubWindowInfoProvider(windows: [
            makeWindowDictionary(id: 1, ownerPID: 100, ownerName: "Safari", title: "")
        ])
        let scanner = WindowScanner(currentProcessID: 999, provider: provider)

        let windows = scanner.scan(options: .optionAll)

        XCTAssertEqual(windows.map(\.displayTitle), ["Safari"])
    }

    func testDisplayTitleFallback() {
        XCTAssertEqual(makeWindow(ownerName: "Preview", title: "").displayTitle, "Preview")
        XCTAssertEqual(makeWindow(ownerName: "Preview", title: "Document.pdf").displayTitle, "Document.pdf")
    }

    func testWindowInfoReplacingTitle() {
        let original = makeWindow(id: 12, ownerName: "Safari", title: "")
        let updated = original.replacingTitle("Example Page")

        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.ownerPID, original.ownerPID)
        XCTAssertEqual(updated.ownerName, original.ownerName)
        XCTAssertEqual(updated.bounds, original.bounds)
        XCTAssertEqual(updated.title, "Example Page")
        XCTAssertEqual(updated.displayTitle, "Example Page")
    }

    func testWindowFramePolicySelectsMaximizedWindows() {
        let policy = WindowFramePolicy(tolerance: 4)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let usable = CGRect(x: 0, y: 48, width: 1440, height: 852)

        XCTAssertTrue(policy.shouldMoveMaximizedWindow(windowFrame: screen, screenFrame: screen, usableFrame: usable))
        XCTAssertTrue(
            policy.shouldMoveMaximizedWindow(
                windowFrame: CGRect(x: 0, y: 1, width: 1440, height: 899),
                screenFrame: screen,
                usableFrame: usable
            ))
    }

    func testWindowFramePolicyHandlesRectangleMaximize() {
        let policy = WindowFramePolicy(tolerance: 4)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let usable = CGRect(x: 0, y: 48, width: 1440, height: 852)
        let rectangleMaximized = CGRect(x: 0, y: 0, width: 1440, height: 875)

        XCTAssertTrue(
            policy.shouldMoveMaximizedWindow(windowFrame: rectangleMaximized, screenFrame: screen, usableFrame: usable))
    }

    func testWindowFramePolicySkipsAdjustedAndManualWindows() {
        let policy = WindowFramePolicy(tolerance: 4)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let usable = CGRect(x: 0, y: 48, width: 1440, height: 852)
        let manual = CGRect(x: 120, y: 80, width: 900, height: 700)

        XCTAssertFalse(policy.shouldMoveMaximizedWindow(windowFrame: usable, screenFrame: screen, usableFrame: usable))
        XCTAssertFalse(policy.shouldMoveMaximizedWindow(windowFrame: manual, screenFrame: screen, usableFrame: usable))
        XCTAssertFalse(
            policy.shouldMoveMaximizedWindow(
                windowFrame: usable,
                screenFrame: screen,
                usableFrame: usable,
                lastAppliedFrame: usable
            ))

        let changedUsable = CGRect(x: 0, y: 64, width: 1440, height: 836)
        XCTAssertTrue(
            policy.shouldMoveMaximizedWindow(
                windowFrame: usable,
                screenFrame: screen,
                usableFrame: changedUsable,
                lastAppliedFrame: usable
            ))
    }
}

private func makeWindow(
    id: CGWindowID = 1,
    ownerPID: pid_t = 100,
    ownerName: String = "Safari",
    title: String = "Example Page",
    bounds: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600),
    layer: Int = 0,
    isOnScreen: Bool = true
) -> WindowInfo {
    WindowInfo(
        id: id,
        ownerPID: ownerPID,
        ownerName: ownerName,
        title: title,
        bounds: bounds,
        layer: layer,
        isOnScreen: isOnScreen
    )
}

private func makeWindowDictionary(
    id: UInt32 = 1,
    ownerPID: pid_t = 100,
    ownerName: String = "Safari",
    title: String = "Example Page",
    bounds: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600),
    layer: Int = 0,
    isOnScreen: Bool = true
) -> [String: Any] {
    [
        kCGWindowNumber as String: NSNumber(value: id),
        kCGWindowOwnerPID as String: NSNumber(value: ownerPID),
        kCGWindowOwnerName as String: ownerName,
        kCGWindowName as String: title,
        kCGWindowBounds as String: bounds.dictionaryRepresentation,
        kCGWindowLayer as String: NSNumber(value: layer),
        kCGWindowIsOnscreen as String: NSNumber(value: isOnScreen),
    ]
}
