import AppKit
import SwiftUI

final class TaskbarWindowController: NSWindowController {
    private let barHeight = TaskbarGeometry.defaultHeight
    private let windowStore: WindowStore
    private let workAreaReservation: WorkAreaReservation
    private var placementObserver: TaskbarPlacementObserver

    convenience init() {
        let windowStore = WindowStore()
        let workAreaReservation = WorkAreaReservation()
        let geometry = TaskbarGeometry.forMainScreen()

        let panel = NSPanel(
            contentRect: geometry.taskbarFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        TaskbarWindowConfigurator().configure(panel)

        let rootView = TaskbarView(windowStore: windowStore)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .preferredColorScheme(.dark)

        panel.contentView = NSHostingView(rootView: rootView)

        self.init(
            window: panel,
            windowStore: windowStore,
            workAreaReservation: workAreaReservation
        )

        windowStore.startPolling()
        placementObserver.start()
        applyCurrentPlacement()
    }

    init(window: NSWindow?, windowStore: WindowStore, workAreaReservation: WorkAreaReservation) {
        self.windowStore = windowStore
        self.workAreaReservation = workAreaReservation
        self.placementObserver = TaskbarPlacementObserver {}
        super.init(window: window)
        self.placementObserver = TaskbarPlacementObserver { [weak self] in
            self?.applyCurrentPlacement()
        }
    }

    required init?(coder: NSCoder) {
        self.windowStore = WindowStore()
        self.workAreaReservation = WorkAreaReservation()
        self.placementObserver = TaskbarPlacementObserver {}
        super.init(coder: coder)
    }

    override func showWindow(_ sender: Any?) {
        reposition()
        super.showWindow(sender)
        window?.orderFrontRegardless()
    }

    func reposition() {
        applyCurrentPlacement()
    }

    private func applyCurrentPlacement() {
        let geometry = TaskbarGeometry.forMainScreen(barHeight: barHeight)
        workAreaReservation.apply(geometry: geometry)
        window?.setFrame(geometry.taskbarFrame, display: true)
        window?.orderFrontRegardless()
    }
}
