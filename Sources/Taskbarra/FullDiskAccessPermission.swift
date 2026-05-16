import Foundation
import TaskbarraCore

struct FullDiskAccessPermission {
    private let protectedURL: URL

    init(protectedURL: URL = NotificationCenterDatabaseReader.defaultDatabaseURL()) {
        self.protectedURL = protectedURL
    }

    func isGranted() -> Bool {
        FileManager.default.isReadableFile(atPath: protectedURL.path)
    }
}
