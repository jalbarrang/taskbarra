import Foundation
import TaskbarraCore
import XCTest

final class NotificationDeepLinkExtractorTests: XCTestCase {
    func testExtractsFallbackDeepLinkFromNestedUserInfo() {
        let plist: [String: Any] = [
            "req": [
                "uncc": [
                    "fallbackDeepLink": "discord://channels/1/2/3",
                ],
            ],
        ]

        XCTAssertEqual(
            NotificationDeepLinkExtractor.deepLink(in: plist),
            URL(string: "discord://channels/1/2/3")
        )
    }

    func testExtractsDeepLinkFromNestedBinaryPlistData() throws {
        let nestedData = try PropertyListSerialization.data(
            fromPropertyList: ["fallbackDeepLink": "discord://channels/4/5/6"],
            format: .binary,
            options: 0
        )
        let plist: [String: Any] = ["req": ["usda": nestedData]]

        XCTAssertEqual(
            NotificationDeepLinkExtractor.deepLink(in: plist),
            URL(string: "discord://channels/4/5/6")
        )
    }

    func testSkipsDeeplyNestedPayloads() {
        var value: Any = ["fallbackDeepLink": "discord://channels/deep"]
        for _ in 0..<20 {
            value = ["nested": value]
        }

        XCTAssertNil(NotificationDeepLinkExtractor.deepLink(in: ["root": value]))
    }

    func testSkipsOversizedDictionaries() {
        var oversized: [String: Any] = Dictionary(
            uniqueKeysWithValues: (0..<65).map { ("key\($0)", "not-a-link") }
        )
        oversized["fallbackDeepLink"] = "discord://channels/oversized"

        XCTAssertNil(NotificationDeepLinkExtractor.deepLink(in: oversized))
    }

    func testSkipsOversizedArrays() {
        var oversized = Array(repeating: "not-a-link", count: 65)
        oversized[64] = "discord://channels/oversized"

        XCTAssertNil(NotificationDeepLinkExtractor.deepLink(in: ["items": oversized]))
    }

    func testSkipsOversizedData() throws {
        let oversizedString = String(repeating: "x", count: 256 * 1024) + " discord://channels/oversized"
        let oversizedData = try XCTUnwrap(oversizedString.data(using: .utf8))

        XCTAssertNil(NotificationDeepLinkExtractor.deepLink(in: ["payload": oversizedData]))
    }
}
