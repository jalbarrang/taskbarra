import Foundation
import SQLite3

public struct AppNotification: Equatable, Identifiable, Sendable {
    public let id: Int64
    public let bundleIdentifier: String
    public let title: String?
    public let body: String?
    public let deliveredAt: Date?
    public let presented: Bool
    public let badge: Int?
    public let notificationIdentifier: String?
    public let threadIdentifier: String?

    public init(
        id: Int64,
        bundleIdentifier: String,
        title: String?,
        body: String?,
        deliveredAt: Date?,
        presented: Bool,
        badge: Int?,
        notificationIdentifier: String?,
        threadIdentifier: String?
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.title = title
        self.body = body
        self.deliveredAt = deliveredAt
        self.presented = presented
        self.badge = badge
        self.notificationIdentifier = notificationIdentifier
        self.threadIdentifier = threadIdentifier
    }
}

public enum NotificationCenterDatabaseReaderError: Error, Equatable {
    case databaseUnavailable(URL)
    case openFailed(String)
    case prepareFailed(String)
}

public struct NotificationCenterDatabaseReader: Sendable {
    public let databaseURL: URL

    public init(databaseURL: URL = Self.defaultDatabaseURL()) {
        self.databaseURL = databaseURL
    }

    public static func defaultDatabaseURL(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        homeDirectory
            .appendingPathComponent("Library/Group Containers/group.com.apple.usernoted/db2/db")
    }

    public func readRecentNotifications(limit: Int = 100) throws -> [AppNotification] {
        guard FileManager.default.isReadableFile(atPath: databaseURL.path) else {
            throw NotificationCenterDatabaseReaderError.databaseUnavailable(databaseURL)
        }

        var database: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        guard sqlite3_open_v2(databaseURL.path, &database, flags, nil) == SQLITE_OK, let database else {
            let message = database.map { String(cString: sqlite3_errmsg($0)) } ?? "Unable to allocate SQLite handle"
            if let database { sqlite3_close(database) }
            throw NotificationCenterDatabaseReaderError.openFailed(
                message
            )
        }
        defer { sqlite3_close(database) }

        let sql = """
            SELECT r.rec_id, a.identifier, a.badge, r.delivered_date, r.presented, r.data
            FROM record r
            JOIN app a ON a.app_id = r.app_id
            ORDER BY r.delivered_date DESC
            LIMIT ?
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw NotificationCenterDatabaseReaderError.prepareFailed(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, Int32(max(0, limit)))

        var notifications: [AppNotification] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let notification = parseCurrentRow(statement) else { continue }
            notifications.append(notification)
        }
        return notifications
    }

    private func parseCurrentRow(_ statement: OpaquePointer) -> AppNotification? {
        let recID = sqlite3_column_int64(statement, 0)
        guard let identifierPointer = sqlite3_column_text(statement, 1) else { return nil }
        let databaseBundleIdentifier = String(cString: identifierPointer)
        let badge = sqlite3_column_type(statement, 2) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 2))
        let deliveredAt = date(fromAppleReferenceTime: sqlite3_column_double(statement, 3))
        let presented = sqlite3_column_int(statement, 4) != 0

        guard let blob = sqlite3_column_blob(statement, 5) else { return nil }
        let byteCount = Int(sqlite3_column_bytes(statement, 5))
        let data = Data(bytes: blob, count: byteCount)
        let rawPlist = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )
        let plist = rawPlist as? [String: Any]
        let request = plist?["req"] as? [String: Any]

        let plistBundleIdentifier = plist?["app"] as? String
        return AppNotification(
            id: recID,
            bundleIdentifier: plistBundleIdentifier ?? databaseBundleIdentifier,
            title: request?["titl"] as? String,
            body: request?["body"] as? String,
            deliveredAt: deliveredAt,
            presented: presented,
            badge: badge,
            notificationIdentifier: request?["iden"] as? String,
            threadIdentifier: request?["thre"] as? String
        )
    }

    private func date(fromAppleReferenceTime value: Double) -> Date? {
        guard value > 0 else { return nil }
        return Date(timeIntervalSinceReferenceDate: value)
    }
}
