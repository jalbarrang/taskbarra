import AppKit
import Foundation
import Observation
import TaskbarraCore

@Observable
@MainActor
final class WindowStore {
    private let scanner: WindowScanner
    private let iconProvider: ApplicationIconProvider
    private let titleResolver: WindowTitleResolver
    private let passiveAXScanner: PassiveAXWindowScanning
    private let snapshotMatcher: WindowSnapshotMatcher
    private var refreshTask: Task<Void, Never>?
    private var eventMonitor: AXWindowEventMonitor?
    var onPassiveSnapshotDidChange: (([WindowInfo]) -> Void)?

    private(set) var windows: [WindowInfo] = []
    private(set) var appIconsByWindowID: [WindowInfo.ID: NSImage] = [:]
    private(set) var activeWindowID: WindowInfo.ID?
    private(set) var minimizedWindowIDs: Set<WindowInfo.ID> = []
    private(set) var lastRefresh: Date?

    init(
        scanner: WindowScanner = WindowScanner(),
        iconProvider: ApplicationIconProvider = ApplicationIconProvider(),
        titleResolver: WindowTitleResolver = WindowTitleResolver(),
        passiveAXScanner: PassiveAXWindowScanning = PassiveAXWindowScanner(),
        snapshotMatcher: WindowSnapshotMatcher = WindowSnapshotMatcher()
    ) {
        self.scanner = scanner
        self.iconProvider = iconProvider
        self.titleResolver = titleResolver
        self.passiveAXScanner = passiveAXScanner
        self.snapshotMatcher = snapshotMatcher
    }

    func startMonitoring() {
        refreshPassiveSnapshot()

        eventMonitor?.stop()
        let monitor = AXWindowEventMonitor { [weak self] in
            self?.refreshPassiveSnapshot()
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
                    self?.refreshPassiveSnapshot()
                }
            }
        }
    }

    func refreshPassiveSnapshot() {
        let windowsInStackingOrder = scanner.scanVisibleWindowsInStackingOrder().map(enrichTitle)
        let minimizedWindows = passiveAXScanner.scanMinimizedWindows()
            .filter { snapshotMatcher.visibleCounterpart(for: $0, in: windowsInStackingOrder) == nil }
            .map { $0.windowInfo() }
        let scannedWindows = (windowsInStackingOrder + minimizedWindows).sorted(by: WindowScanner.windowSortOrder)
        windows = scannedWindows
        activeWindowID = windowsInStackingOrder.first(where: isFrontmostApplicationWindow)?.id
        minimizedWindowIDs = Set(minimizedWindows.map(\.id))
        appIconsByWindowID = Dictionary(
            uniqueKeysWithValues: scannedWindows.compactMap { window in
                iconProvider.icon(forOwnerPID: window.ownerPID).map { icon in
                    (window.id, icon)
                }
            }
        )
        lastRefresh = Date()
        onPassiveSnapshotDidChange?(scannedWindows)
    }

    private func enrichTitle(_ window: WindowInfo) -> WindowInfo {
        let title = titleResolver.bestEffortTitle(for: window)
        guard title != window.title else { return window }
        return window.replacingTitle(title)
    }

    private func isFrontmostApplicationWindow(_ window: WindowInfo) -> Bool {
        NSWorkspace.shared.frontmostApplication?.processIdentifier == window.ownerPID
    }

}
