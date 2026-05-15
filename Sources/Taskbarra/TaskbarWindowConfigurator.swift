import AppKit

struct TaskbarWindowConfigurator {
    @MainActor
    func configure(_ panel: NSPanel) {
        panel.title = "Taskbarra"
        panel.isReleasedWhenClosed = false
        panel.level = .statusBar
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .stationary,
        ]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.appearance = NSAppearance(named: .darkAqua)
    }
}
