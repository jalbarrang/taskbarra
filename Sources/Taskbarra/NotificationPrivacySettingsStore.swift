import Foundation
import TaskbarraCore

@MainActor
final class NotificationPrivacySettingsStore {
    private enum Key {
        static let showNotificationPreviews = "showNotificationPreviews"
        static let excludedBundleIdentifiers = "excludedNotificationBundleIdentifiers"
        static let maxNotificationAge = "maxNotificationAge"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.showNotificationPreviews: false,
            Key.maxNotificationAge: 7 * 24 * 60 * 60,
        ])
    }

    var configuration: NotificationPrivacyConfiguration {
        NotificationPrivacyConfiguration(
            showNotificationPreviews: defaults.bool(forKey: Key.showNotificationPreviews),
            excludedBundleIdentifiers: Set(defaults.stringArray(forKey: Key.excludedBundleIdentifiers) ?? []),
            maxNotificationAge: defaults.double(forKey: Key.maxNotificationAge)
        )
    }
}
