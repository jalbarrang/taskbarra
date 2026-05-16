import Foundation
import TaskbarraCore
import XCTest

final class NotificationPrivacyFilterTests: XCTestCase {
    func testFiltersExcludedBundleIdentifiersAndOldNotifications() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let configuration = NotificationPrivacyConfiguration(
            excludedBundleIdentifiers: ["COM.EXAMPLE.SECRET"],
            maxNotificationAge: 100
        )

        let visible = makeNotification(
            bundleIdentifier: "com.example.visible",
            deliveredAt: now.addingTimeInterval(-50)
        )
        let excluded = makeNotification(bundleIdentifier: "com.example.secret", deliveredAt: now)
        let old = makeNotification(bundleIdentifier: "com.example.old", deliveredAt: now.addingTimeInterval(-101))

        let filtered = NotificationPrivacyFilter.filter(
            notifications: [visible, excluded, old],
            configuration: configuration,
            now: now
        )

        XCTAssertEqual(filtered, [visible])
    }

    func testDefaultConfigurationHidesPreviewText() {
        let notification = makeNotification(bundleIdentifier: "com.example.app", deliveredAt: Date())
        let configuration = NotificationPrivacyConfiguration()

        XCTAssertNil(NotificationPrivacyFilter.displayTitle(for: notification, configuration: configuration))
        XCTAssertNil(NotificationPrivacyFilter.displayBody(for: notification, configuration: configuration))
    }

    func testShowsPreviewTextWhenEnabled() {
        let notification = makeNotification(bundleIdentifier: "com.example.app", deliveredAt: Date())
        let configuration = NotificationPrivacyConfiguration(showNotificationPreviews: true)

        XCTAssertEqual(NotificationPrivacyFilter.displayTitle(for: notification, configuration: configuration), "Secret title")
        XCTAssertEqual(NotificationPrivacyFilter.displayBody(for: notification, configuration: configuration), "Secret body")
    }

    private func makeNotification(bundleIdentifier: String, deliveredAt: Date?) -> AppNotification {
        AppNotification(
            id: Int64(bundleIdentifier.hashValue),
            bundleIdentifier: bundleIdentifier,
            title: "Secret title",
            body: "Secret body",
            deliveredAt: deliveredAt,
            presented: true,
            badge: nil,
            notificationIdentifier: nil,
            threadIdentifier: nil
        )
    }
}
