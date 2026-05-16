import Foundation
import TaskbarraCore
import XCTest

final class AppNotificationSummaryTests: XCTestCase {
    func testUnreadCountUsesLastSeenDateAndKeepsLatestNotification() {
        let oldNotification = makeNotification(id: 1, deliveredAt: Date(timeIntervalSinceReferenceDate: 100), badge: 9)
        let newNotification = makeNotification(id: 2, deliveredAt: Date(timeIntervalSinceReferenceDate: 300), badge: 9)

        let summary = AppNotificationSummarizer.summary(
            bundleIdentifier: "COM.EXAMPLE.APP",
            notifications: [oldNotification, newNotification],
            lastSeenAt: Date(timeIntervalSinceReferenceDate: 200)
        )

        XCTAssertEqual(summary.bundleIdentifier, "com.example.app")
        XCTAssertEqual(summary.unreadCount, 1)
        XCTAssertEqual(summary.systemBadge, 9)
        XCTAssertEqual(summary.latestNotification, newNotification)
        XCTAssertEqual(summary.badgeCount, 1)
    }

    func testBadgeFallsBackToSystemBadgeWhenEverythingIsSeen() {
        let notification = makeNotification(id: 1, deliveredAt: Date(timeIntervalSinceReferenceDate: 100), badge: 4)

        let summary = AppNotificationSummarizer.summary(
            bundleIdentifier: "com.example.app",
            notifications: [notification],
            lastSeenAt: Date(timeIntervalSinceReferenceDate: 200)
        )

        XCTAssertEqual(summary.unreadCount, 0)
        XCTAssertEqual(summary.badgeCount, 4)
    }

    func testNotificationsWithoutDatesAreUnreadUntilThereIsAnySeenDate() {
        let notification = makeNotification(id: 1, deliveredAt: nil, badge: nil)

        let unread = AppNotificationSummarizer.summary(
            bundleIdentifier: "com.example.app",
            notifications: [notification],
            lastSeenAt: nil
        )
        let seen = AppNotificationSummarizer.summary(
            bundleIdentifier: "com.example.app",
            notifications: [notification],
            lastSeenAt: Date()
        )

        XCTAssertEqual(unread.unreadCount, 1)
        XCTAssertEqual(seen.unreadCount, 0)
    }

    private func makeNotification(id: Int64, deliveredAt: Date?, badge: Int?) -> AppNotification {
        AppNotification(
            id: id,
            bundleIdentifier: "com.example.app",
            title: "Title \(id)",
            body: nil,
            deliveredAt: deliveredAt,
            presented: true,
            badge: badge,
            notificationIdentifier: nil,
            threadIdentifier: nil
        )
    }
}
