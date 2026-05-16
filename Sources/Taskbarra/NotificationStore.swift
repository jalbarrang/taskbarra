import AppKit
import Foundation
import TaskbarraCore

@MainActor
final class NotificationStore: ObservableObject {
    @Published private(set) var notificationsByBundleIdentifier: [String: [AppNotification]] = [:]

    private let reader: NotificationCenterDatabaseReader
    private let lastSeenStore: NotificationLastSeenStore
    private let privacySettingsStore: NotificationPrivacySettingsStore
    private var timer: Timer?

    init(
        reader: NotificationCenterDatabaseReader = NotificationCenterDatabaseReader(),
        lastSeenStore: NotificationLastSeenStore = NotificationLastSeenStore(),
        privacySettingsStore: NotificationPrivacySettingsStore = NotificationPrivacySettingsStore()
    ) {
        self.reader = reader
        self.lastSeenStore = lastSeenStore
        self.privacySettingsStore = privacySettingsStore
    }

    func startMonitoring() {
        refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        do {
            let notifications = try reader.readRecentNotifications(limit: 200)
            let filteredNotifications = NotificationPrivacyFilter.filter(
                notifications: notifications,
                configuration: privacyConfiguration
            )
            notificationsByBundleIdentifier = Dictionary(
                grouping: filteredNotifications,
                by: normalizedBundleIdentifier
            )
        } catch {
            notificationsByBundleIdentifier = [:]
        }
    }

    func notifications(forOwnerPID ownerPID: pid_t, limit: Int = 5) -> [AppNotification] {
        guard let bundleIdentifier = bundleIdentifier(forOwnerPID: ownerPID) else { return [] }
        return Array((notificationsByBundleIdentifier[bundleIdentifier] ?? []).prefix(limit))
    }

    func notificationSummary(forOwnerPID ownerPID: pid_t) -> AppNotificationSummary? {
        guard let bundleIdentifier = bundleIdentifier(forOwnerPID: ownerPID) else { return nil }
        return AppNotificationSummarizer.summary(
            bundleIdentifier: bundleIdentifier,
            notifications: notificationsByBundleIdentifier[bundleIdentifier] ?? [],
            lastSeenAt: lastSeenStore.lastSeenAt(for: bundleIdentifier)
        )
    }

    func notificationCount(forOwnerPID ownerPID: pid_t) -> Int {
        notificationSummary(forOwnerPID: ownerPID)?.badgeCount ?? 0
    }

    var privacyConfiguration: NotificationPrivacyConfiguration {
        privacySettingsStore.configuration
    }

    func markSeen(ownerPID: pid_t) {
        guard let bundleIdentifier = bundleIdentifier(forOwnerPID: ownerPID) else { return }
        lastSeenStore.markSeen(bundleIdentifier: bundleIdentifier)
        objectWillChange.send()
    }

    private func bundleIdentifier(forOwnerPID ownerPID: pid_t) -> String? {
        NSRunningApplication(processIdentifier: ownerPID)?.bundleIdentifier?.lowercased()
    }

    private func normalizedBundleIdentifier(_ notification: AppNotification) -> String {
        notification.bundleIdentifier.lowercased()
    }
}
