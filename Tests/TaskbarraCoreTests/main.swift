import CoreGraphics
import Foundation
import TaskbarraCore

private struct StubWindowInfoProvider: WindowInfoProviding {
    let windows: [[String: Any]]

    func copyWindowInfo(options: CGWindowListOption, relativeToWindow windowID: CGWindowID) -> [[String: Any]] {
        windows
    }
}

@main
struct TestRunner {
    static func main() throws {
        try run("parses CGWindow dictionaries into WindowInfo", testParsesWindowInfo)
        try run("returns nil for malformed dictionaries", testRejectsMalformedDictionaries)
        try run("filters irrelevant windows", testFiltersIrrelevantWindows)
        try run("scan parses, filters, and sorts windows", testScansRelevantWindowsInStableOrder)
        try run("displayTitle falls back to ownerName when title is empty", testDisplayTitleFallback)
        try run(
            "window frame policy selects maximized windows that overlap taskbar",
            testWindowFramePolicySelectsMaximizedWindows)
        try run(
            "window frame policy skips adjusted and manual windows", testWindowFramePolicySkipsAdjustedAndManualWindows)
        print("All TaskbarraCore tests passed")
    }
}

private func testParsesWindowInfo() throws {
    let dictionary = makeWindowDictionary(
        id: 42,
        ownerPID: 100,
        ownerName: "Safari",
        title: "Example Page",
        bounds: CGRect(x: 10, y: 20, width: 800, height: 600)
    )

    let window = try unwrap(WindowScanner.parseWindowInfo(dictionary))

    expectEqual(window.id, 42)
    expectEqual(window.ownerPID, 100)
    expectEqual(window.ownerName, "Safari")
    expectEqual(window.title, "Example Page")
    expectEqual(window.bounds, CGRect(x: 10, y: 20, width: 800, height: 600))
    expectEqual(window.layer, 0)
    expect(window.isOnScreen)
}

private func testRejectsMalformedDictionaries() {
    expect(WindowScanner.parseWindowInfo([:]) == nil)
}

private func testFiltersIrrelevantWindows() {
    let scanner = WindowScanner(currentProcessID: 999, ignoredOwnerNames: ["Dock"])

    expect(scanner.isRelevantWindow(makeWindow()))
    expect(!scanner.isRelevantWindow(makeWindow(ownerPID: 999)))
    expect(!scanner.isRelevantWindow(makeWindow(ownerName: "Dock")))
    expect(!scanner.isRelevantWindow(makeWindow(title: "   ")))
    expect(!scanner.isRelevantWindow(makeWindow(layer: 1)))
    expect(!scanner.isRelevantWindow(makeWindow(isOnScreen: false)))
    expect(!scanner.isRelevantWindow(makeWindow(bounds: CGRect(x: 0, y: 0, width: 79, height: 600))))
    expect(!scanner.isRelevantWindow(makeWindow(bounds: CGRect(x: 0, y: 0, width: 800, height: 39))))
}

private func testScansRelevantWindowsInStableOrder() {
    let provider = StubWindowInfoProvider(windows: [
        makeWindowDictionary(id: 3, ownerPID: 100, ownerName: "Safari", title: "Zeta"),
        makeWindowDictionary(id: 4, ownerPID: 100, ownerName: "Dock", title: "Dock Window"),
        makeWindowDictionary(id: 2, ownerPID: 101, ownerName: "Finder", title: "Downloads"),
        makeWindowDictionary(id: 1, ownerPID: 102, ownerName: "Finder", title: "Applications"),
    ])
    let scanner = WindowScanner(currentProcessID: 999, provider: provider, ignoredOwnerNames: ["Dock"])

    let windows = scanner.scan(options: .optionAll)

    expectEqual(windows.map(\.id), [1, 2, 3])
}

private func testDisplayTitleFallback() {
    expectEqual(makeWindow(ownerName: "Preview", title: "").displayTitle, "Preview")
    expectEqual(makeWindow(ownerName: "Preview", title: "Document.pdf").displayTitle, "Document.pdf")
}

private func testWindowFramePolicySelectsMaximizedWindows() {
    let policy = WindowFramePolicy(tolerance: 4)
    let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let usable = CGRect(x: 0, y: 48, width: 1440, height: 852)

    expect(policy.shouldMoveMaximizedWindow(windowFrame: screen, screenFrame: screen, usableFrame: usable))
    expect(
        policy.shouldMoveMaximizedWindow(
            windowFrame: CGRect(x: 0, y: 1, width: 1440, height: 899),
            screenFrame: screen,
            usableFrame: usable
        ))
}

private func testWindowFramePolicySkipsAdjustedAndManualWindows() {
    let policy = WindowFramePolicy(tolerance: 4)
    let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let usable = CGRect(x: 0, y: 48, width: 1440, height: 852)
    let manual = CGRect(x: 120, y: 80, width: 900, height: 700)

    expect(!policy.shouldMoveMaximizedWindow(windowFrame: usable, screenFrame: screen, usableFrame: usable))
    expect(!policy.shouldMoveMaximizedWindow(windowFrame: manual, screenFrame: screen, usableFrame: usable))
    expect(
        !policy.shouldMoveMaximizedWindow(
            windowFrame: usable,
            screenFrame: screen,
            usableFrame: usable,
            lastAppliedFrame: usable
        ))

    let changedUsable = CGRect(x: 0, y: 64, width: 1440, height: 836)
    expect(
        policy.shouldMoveMaximizedWindow(
            windowFrame: usable,
            screenFrame: screen,
            usableFrame: changedUsable,
            lastAppliedFrame: usable
        ))
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

private func run(_ name: String, _ test: () throws -> Void) throws {
    do {
        try test()
        print("✓ \(name)")
    } catch {
        print("✗ \(name)")
        throw error
    }
}

private func expect(_ condition: @autoclosure () -> Bool, file: StaticString = #file, line: UInt = #line) {
    guard condition() else {
        fatalError("Expectation failed at \(file):\(line)")
    }
}

private func expectEqual<T: Equatable>(
    _ lhs: @autoclosure () -> T,
    _ rhs: @autoclosure () -> T,
    file: StaticString = #file,
    line: UInt = #line
) {
    let lhsValue = lhs()
    let rhsValue = rhs()
    guard lhsValue == rhsValue else {
        fatalError("Expected \(lhsValue) == \(rhsValue) at \(file):\(line)")
    }
}

private func unwrap<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) throws -> T {
    guard let value else {
        fatalError("Expected non-nil value at \(file):\(line)")
    }
    return value
}
