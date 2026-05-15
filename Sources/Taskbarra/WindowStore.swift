import AppKit
import Foundation
import Observation
import TaskbarraCore

@Observable
@MainActor
final class WindowStore {
    private let scanner: WindowScanner
    private let iconProvider: ApplicationIconProvider
    private var refreshTask: Task<Void, Never>?

    private(set) var windows: [WindowInfo] = []
    private(set) var appIconsByWindowID: [WindowInfo.ID: NSImage] = [:]
    private(set) var lastRefresh: Date?

    init(
        scanner: WindowScanner = WindowScanner(),
        iconProvider: ApplicationIconProvider = ApplicationIconProvider()
    ) {
        self.scanner = scanner
        self.iconProvider = iconProvider
    }

    func startPolling(interval: Duration = .seconds(2)) {
        refresh()

        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                await MainActor.run {
                    self?.refresh()
                }
            }
        }
    }

    func stopPolling() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() {
        let scannedWindows = scanner.scanVisibleWindows()
        windows = scannedWindows
        appIconsByWindowID = Dictionary(
            uniqueKeysWithValues: scannedWindows.compactMap { window in
                iconProvider.icon(forOwnerPID: window.ownerPID).map { icon in
                    (window.id, icon)
                }
            }
        )
        lastRefresh = Date()
    }
}
