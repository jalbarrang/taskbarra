import Foundation
import Observation

@Observable
@MainActor
final class WindowStore {
    private let scanner: WindowScanner
    private var refreshTask: Task<Void, Never>?

    private(set) var windows: [WindowInfo] = []
    private(set) var lastRefresh: Date?

    init(scanner: WindowScanner = WindowScanner()) {
        self.scanner = scanner
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
        windows = scanner.scanVisibleWindows()
        lastRefresh = Date()
    }
}
