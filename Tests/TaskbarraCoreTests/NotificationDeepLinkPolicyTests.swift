@testable import TaskbarraCore
import XCTest

final class NotificationDeepLinkPolicyTests: XCTestCase {
    func testAllowsHttpAndHttpsByDefault() throws {
        let policy = NotificationDeepLinkPolicy()

        XCTAssertEqual(policy.decision(for: try XCTUnwrap(URL(string: "https://example.com/path"))), .allow)
        XCTAssertEqual(policy.decision(for: try XCTUnwrap(URL(string: "http://example.com/path"))), .allow)
    }

    func testRequiresConfirmationForUnlistedApplicationSchemes() throws {
        let policy = NotificationDeepLinkPolicy()

        XCTAssertEqual(policy.decision(for: try XCTUnwrap(URL(string: "discord://channels/1/2/3"))), .confirm)
        XCTAssertEqual(policy.schemeDescription(for: try XCTUnwrap(URL(string: "DISCORD://channels/1/2/3"))), "discord")
    }

    func testBlocksDangerousSchemes() throws {
        let policy = NotificationDeepLinkPolicy()

        XCTAssertEqual(policy.decision(for: try XCTUnwrap(URL(string: "file:///Users/example/secret.txt"))), .block)
        XCTAssertEqual(policy.decision(for: try XCTUnwrap(URL(string: "javascript:alert(1)"))), .block)
        XCTAssertEqual(policy.decision(for: try XCTUnwrap(URL(string: "data:text/plain,hello"))), .block)
    }

    func testSupportsCustomAllowlistAndBlocklist() throws {
        let policy = NotificationDeepLinkPolicy(allowedSchemes: ["discord"], blockedSchemes: ["x-blocked"])

        XCTAssertEqual(policy.decision(for: try XCTUnwrap(URL(string: "discord://channels/1/2/3"))), .allow)
        XCTAssertEqual(policy.decision(for: try XCTUnwrap(URL(string: "https://example.com"))), .confirm)
        XCTAssertEqual(policy.decision(for: try XCTUnwrap(URL(string: "x-blocked://payload"))), .block)
    }
}
