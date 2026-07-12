import CoreGraphics
import TaskbarraCore
import XCTest

final class ScreenCoordinateConverterTests: XCTestCase {
    private let converter = ScreenCoordinateConverter(primaryScreenHeight: 900)

    func testConvertsPrimaryScreenRect() {
        let appKitRect = CGRect(x: 0, y: 48, width: 1440, height: 852)

        XCTAssertEqual(converter.appKitToCG(appKitRect), CGRect(x: 0, y: 0, width: 1440, height: 852))
    }

    func testConvertsSecondaryScreenToTheRight() {
        let appKitRect = CGRect(x: 1440, y: 48, width: 1920, height: 1032)

        XCTAssertEqual(converter.appKitToCG(appKitRect), CGRect(x: 1440, y: -180, width: 1920, height: 1032))
    }

    func testConvertsSecondaryScreenAbovePrimary() {
        let appKitRect = CGRect(x: 0, y: 948, width: 1440, height: 852)

        XCTAssertEqual(converter.appKitToCG(appKitRect), CGRect(x: 0, y: -900, width: 1440, height: 852))
    }

    func testRoundTripPreservesRect() {
        let original = CGRect(x: -1280, y: -240, width: 1280, height: 1024)

        XCTAssertEqual(converter.cgToAppKit(converter.appKitToCG(original)), original)
        XCTAssertEqual(converter.appKitToCG(converter.cgToAppKit(original)), original)
    }
}
