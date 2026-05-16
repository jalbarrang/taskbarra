import Foundation

public struct AppNotificationSummary: Equatable, Sendable {
    public let bundleIdentifier: String
    public let unreadCount: Int
    public let systemBadge: Int?
    public let latestNotification: AppNotification?

    public init(
        bundleIdentifier: String,
        unreadCount: Int,
        systemBadge: Int?,
        latestNotification: AppNotification?
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.unreadCount = unreadCount
        self.systemBadge = systemBadge
        self.latestNotification = latestNotification
    }

    public var badgeCount: Int {
        if unreadCount > 0 { return unreadCount }
        return systemBadge ?? 0
    }
}

public enum AppNotificationSummarizer {
    public static func summary(
        bundleIdentifier: String,
        notifications: [AppNotification],
        lastSeenAt: Date?
    ) -> AppNotificationSummary {
        let normalizedBundleIdentifier = bundleIdentifier.lowercased()
        let matchingNotifications = notifications
            .filter { $0.bundleIdentifier.lowercased() == normalizedBundleIdentifier }
            .sorted { lhs, rhs in
                switch (lhs.deliveredAt, rhs.deliveredAt) {
                case let (lhsDate?, rhsDate?): lhsDate > rhsDate
                case (.some, .none): true
                case (.none, .some): false
                case (.none, .none): lhs.id > rhs.id
                }
            }

        let unreadCount = matchingNotifications.filter { notification in
            guard let deliveredAt = notification.deliveredAt else { return lastSeenAt == nil }
            guard let lastSeenAt else { return true }
            return deliveredAt > lastSeenAt
        }.count

        let systemBadge = matchingNotifications.compactMap(\.badge).first
        return AppNotificationSummary(
            bundleIdentifier: normalizedBundleIdentifier,
            unreadCount: unreadCount,
            systemBadge: systemBadge,
            latestNotification: matchingNotifications.first
        )
    }
}
