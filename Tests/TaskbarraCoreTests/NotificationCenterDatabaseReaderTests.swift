import Foundation
import TaskbarraCore
import XCTest

final class NotificationCenterDatabaseReaderTests: XCTestCase {
    func testDefaultDatabaseURLUsesUsernotedGroupContainer() {
        let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)

        let url = NotificationCenterDatabaseReader.defaultDatabaseURL(homeDirectory: home)

        XCTAssertEqual(
            url.path,
            "/Users/example/Library/Group Containers/group.com.apple.usernoted/db2/db"
        )
    }

    func testReadsNotificationsFromSQLiteDatabase() throws {
        let databaseURL = try makeFixtureDatabase()
        let reader = NotificationCenterDatabaseReader(databaseURL: databaseURL)

        let notifications = try reader.readRecentNotifications(limit: 10)

        XCTAssertEqual(notifications.count, 1)
        let notification = try XCTUnwrap(notifications.first)
        XCTAssertEqual(notification.id, 42)
        XCTAssertEqual(notification.bundleIdentifier, "com.example.AppFromPlist")
        XCTAssertEqual(notification.title, "Build finished")
        XCTAssertEqual(notification.body, "Taskbarra tests passed")
        XCTAssertEqual(notification.presented, true)
        XCTAssertEqual(notification.badge, 7)
        XCTAssertEqual(notification.notificationIdentifier, "notification-1")
        XCTAssertEqual(notification.threadIdentifier, "thread-1")
        XCTAssertEqual(notification.deepLink, URL(string: "discord://channels/1/2/3"))
        XCTAssertEqual(notification.deliveredAt, Date(timeIntervalSinceReferenceDate: 123_456))
    }

    func testThrowsWhenDatabaseIsUnavailable() {
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("db")
        let reader = NotificationCenterDatabaseReader(databaseURL: missingURL)

        XCTAssertThrowsError(try reader.readRecentNotifications()) { error in
            XCTAssertEqual(
                error as? NotificationCenterDatabaseReaderError,
                .databaseUnavailable(missingURL)
            )
        }
    }

    private func makeFixtureDatabase() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let databaseURL = directory.appendingPathComponent("db")

        try runSQLite(databaseURL: databaseURL, sql: """
            CREATE TABLE app (app_id INTEGER PRIMARY KEY, identifier VARCHAR, badge INTEGER NULL);
            CREATE TABLE record (
                rec_id INTEGER PRIMARY KEY,
                app_id INTEGER,
                uuid BLOB,
                data BLOB,
                request_date REAL,
                request_last_date REAL,
                delivered_date REAL,
                presented Bool,
                style INTEGER,
                snooze_fire_date REAL
            );
            INSERT INTO app (app_id, identifier, badge)
            VALUES (1, 'com.example.AppFromDatabase', 7);
            """)

        let plist = try PropertyListSerialization.data(
            fromPropertyList: [
                "app": "com.example.AppFromPlist",
                "date": 123_456.0,
                "req": [
                    "titl": "Build finished",
                    "body": "Taskbarra tests passed",
                    "iden": "notification-1",
                    "thre": "thread-1",
                    "usda": ["fallbackDeepLink": "discord://channels/1/2/3"],
                ],
            ],
            format: .binary,
            options: 0
        )
        let hex = plist.map { String(format: "%02x", $0) }.joined()

        try runSQLite(databaseURL: databaseURL, sql: """
            INSERT INTO record (rec_id, app_id, uuid, data, delivered_date, presented, style)
            VALUES (42, 1, x'00', x'\(hex)', 123456.0, 1, 1);
            """)

        return databaseURL
    }

    private func runSQLite(databaseURL: URL, sql: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [databaseURL.path, sql]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
    }
}
