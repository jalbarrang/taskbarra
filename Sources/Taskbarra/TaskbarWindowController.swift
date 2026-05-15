import AppKit
import SwiftUI

final class TaskbarWindowController: NSWindowController {
    private let barHeight = TaskbarGeometry.defaultHeight
    private let windowStore: WindowStore
    private let workAreaReservation: WorkAreaReservation
    private let workAreaCoordinator: AXWindowWorkAreaCoordinator
    private let rectangleCompatibilityCoordinator: RectangleCompatibilityCoordinator
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

        let interactionController = WindowInteractionController(refreshWindows: { [weak windowStore] in
            windowStore?.refresh()
        })
        let rootView = TaskbarView(windowStore: windowStore, interactionController: interactionController)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .preferredColorScheme(.dark)

        panel.contentView = NSHostingView(rootView: rootView)

        self.init(
            window: panel,
            windowStore: windowStore,
            workAreaReservation: workAreaReservation
        )

        windowStore.startMonitoring()
        placementObserver.start()
        applyCurrentPlacement()
    }

    init(window: NSWindow?, windowStore: WindowStore, workAreaReservation: WorkAreaReservation) {
        self.windowStore = windowStore
        self.workAreaReservation = workAreaReservation
        self.workAreaCoordinator = AXWindowWorkAreaCoordinator(workAreaReservation: workAreaReservation)
        self.rectangleCompatibilityCoordinator = RectangleCompatibilityCoordinator()
        self.placementObserver = TaskbarPlacementObserver {}
        super.init(window: window)
        windowStore.onRefresh = { [weak self] windows in
            self?.workAreaCoordinator.reconcile(windows: windows)
        }
        self.placementObserver = TaskbarPlacementObserver { [weak self] in
            self?.applyCurrentPlacement()
        }
    }

    required init?(coder: NSCoder) {
        self.windowStore = WindowStore()
        self.workAreaReservation = WorkAreaReservation()
        self.workAreaCoordinator = AXWindowWorkAreaCoordinator(workAreaReservation: workAreaReservation)
        self.rectangleCompatibilityCoordinator = RectangleCompatibilityCoordinator()
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
        rectangleCompatibilityCoordinator.reserveTaskbarSpaceIfRectangleIsPresent(taskbarHeight: geometry.barHeight)
        window?.setFrame(geometry.taskbarFrame, display: true)
        window?.orderFrontRegardless()
        workAreaCoordinator.reconcile(windows: windowStore.windows)
    }
}
