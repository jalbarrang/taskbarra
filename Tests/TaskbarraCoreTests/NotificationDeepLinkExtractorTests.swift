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
}
