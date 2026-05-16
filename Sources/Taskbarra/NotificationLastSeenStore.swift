import Foundation

@MainActor
final class NotificationLastSeenStore {
    private let defaults: UserDefaults
    private let key = "notificationLastSeenByBundleIdentifier"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func lastSeenAt(for bundleIdentifier: String) -> Date? {
        values[normalize(bundleIdentifier)].map(Date.init(timeIntervalSinceReferenceDate:))
    }

    func markSeen(bundleIdentifier: String, at date: Date = Date()) {
        var current = values
        current[normalize(bundleIdentifier)] = date.timeIntervalSinceReferenceDate
        values = current
    }

    private var values: [String: TimeInterval] {
        get { defaults.dictionary(forKey: key) as? [String: TimeInterval] ?? [:] }
        set { defaults.set(newValue, forKey: key) }
    }

    private func normalize(_ bundleIdentifier: String) -> String {
        bundleIdentifier.lowercased()
    }
}
