import AppKit

@MainActor
final class TaskbarPlacementObserver {
    private var observers: [NSObjectProtocol] = []
    private let onPlacementChanged: () -> Void

    init(onPlacementChanged: @escaping () -> Void) {
        self.onPlacementChanged = onPlacementChanged
    }

    func start() {
        guard observers.isEmpty else { return }

        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.onPlacementChanged()
                }
            }
        )

        observers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.onPlacementChanged()
                }
            }
        )
    }

    func stop() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }
}
