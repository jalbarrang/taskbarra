import Foundation

public struct NotificationPrivacyConfiguration: Equatable, Sendable {
    public let showNotificationPreviews: Bool
    public let excludedBundleIdentifiers: Set<String>
    public let maxNotificationAge: TimeInterval

    public init(
        showNotificationPreviews: Bool = false,
        excludedBundleIdentifiers: Set<String> = [],
        maxNotificationAge: TimeInterval = 7 * 24 * 60 * 60
    ) {
        self.showNotificationPreviews = showNotificationPreviews
        self.excludedBundleIdentifiers = Set(excludedBundleIdentifiers.map { $0.lowercased() })
        self.maxNotificationAge = maxNotificationAge
    }
}

public enum NotificationPrivacyFilter {
    public static func filter(
        notifications: [AppNotification],
        configuration: NotificationPrivacyConfiguration,
        now: Date = Date()
    ) -> [AppNotification] {
        notifications.filter { notification in
            !configuration.excludedBundleIdentifiers.contains(notification.bundleIdentifier.lowercased())
                && isRecent(notification, maxAge: configuration.maxNotificationAge, now: now)
        }
    }

    public static func displayTitle(
        for notification: AppNotification,
        configuration: NotificationPrivacyConfiguration
    ) -> String? {
        configuration.showNotificationPreviews ? notification.title : nil
    }

    public static func displayBody(
        for notification: AppNotification,
        configuration: NotificationPrivacyConfiguration
    ) -> String? {
        configuration.showNotificationPreviews ? notification.body : nil
    }

    private static func isRecent(_ notification: AppNotification, maxAge: TimeInterval, now: Date) -> Bool {
        guard maxAge > 0, let deliveredAt = notification.deliveredAt else { return true }
        return now.timeIntervalSince(deliveredAt) <= maxAge
    }
}
