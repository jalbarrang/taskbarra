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
    private var eventMonitor: AXWindowEventMonitor?
    var onRefresh: (([WindowInfo]) -> Void)?

    private(set) var windows: [WindowInfo] = []
    private(set) var appIconsByWindowID: [WindowInfo.ID: NSImage] = [:]
    private(set) var activeWindowID: WindowInfo.ID?
    private(set) var minimizedWindowIDs: Set<WindowInfo.ID> = []
    private(set) var lastRefresh: Date?

    init(
        scanner: WindowScanner = WindowScanner(),
        iconProvider: ApplicationIconProvider = ApplicationIconProvider()
    ) {
        self.scanner = scanner
        self.iconProvider = iconProvider
    }

    func startMonitoring() {
        refresh()

        eventMonitor?.stop()
        let monitor = AXWindowEventMonitor { [weak self] in
            self?.refresh()
        }
        eventMonitor = monitor
        monitor.start()

        startFallbackPolling()
    }

    func stopMonitoring() {
        eventMonitor?.stop()
        eventMonitor = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func startFallbackPolling(interval: Duration = .seconds(10)) {
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

    func refresh() {
        let windowsInStackingOrder = scanner.scanVisibleWindowsInStackingOrder()
        let scannedWindows = windowsInStackingOrder.sorted(by: WindowScanner.windowSortOrder)
        windows = scannedWindows
        activeWindowID = windowsInStackingOrder.first(where: isFrontmostApplicationWindow)?.id
        minimizedWindowIDs = []
        appIconsByWindowID = Dictionary(
            uniqueKeysWithValues: scannedWindows.compactMap { window in
                iconProvider.icon(forOwnerPID: window.ownerPID).map { icon in
                    (window.id, icon)
                }
            }
        )
        lastRefresh = Date()
        onRefresh?(scannedWindows)
    }

    private func isFrontmostApplicationWindow(_ window: WindowInfo) -> Bool {
        NSWorkspace.shared.frontmostApplication?.processIdentifier == window.ownerPID
    }
}
