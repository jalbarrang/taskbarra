import AppKit
import SwiftUI
import TaskbarraCore

final class TaskbarWindowController: NSWindowController {
    private let barHeight = TaskbarGeometry.defaultHeight
    private let windowStore: WindowStore
    private let notificationStore: NotificationStore
    private let workAreaReservation: WorkAreaReservation
    private let workAreaCoordinator: AXWindowWorkAreaCoordinator
    private let rectangleCompatibilityCoordinator: RectangleCompatibilityCoordinator
    private let axWindowResolver: AXWindowResolver
    private var placementObserver: TaskbarPlacementObserver
    private var fullscreenPollingTask: Task<Void, Never>?
    private var isHiddenForFullscreen = false

    convenience init() {
        let windowStore = WindowStore()
        let notificationStore = NotificationStore()
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
            windowStore?.refreshPassiveSnapshot()
        })
        let rootView = TaskbarView(
            windowStore: windowStore,
            notificationStore: notificationStore,
            interactionController: interactionController
        )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .preferredColorScheme(.dark)

        panel.contentView = NSHostingView(rootView: rootView)

        self.init(
            window: panel,
            windowStore: windowStore,
            notificationStore: notificationStore,
            workAreaReservation: workAreaReservation
        )

        windowStore.startMonitoring()
        notificationStore.startMonitoring()
        placementObserver.start()
        startFullscreenPolling()
        applyCurrentPlacement()
    }

    init(
        window: NSWindow?,
        windowStore: WindowStore,
        notificationStore: NotificationStore = NotificationStore(),
        workAreaReservation: WorkAreaReservation
    ) {
        self.windowStore = windowStore
        self.notificationStore = notificationStore
        self.workAreaReservation = workAreaReservation
        self.workAreaCoordinator = AXWindowWorkAreaCoordinator(workAreaReservation: workAreaReservation)
        self.rectangleCompatibilityCoordinator = RectangleCompatibilityCoordinator()
        self.axWindowResolver = AXWindowResolver()
        self.placementObserver = TaskbarPlacementObserver {}
        super.init(window: window)
        windowStore.onPassiveSnapshotDidChange = { [weak self] windows in
            self?.reconcileWorkAreaAfterPassiveDiscovery(windows: windows)
            self?.updateVisibilityForFullscreenWindow()
        }
        self.placementObserver = TaskbarPlacementObserver { [weak self] in
            self?.applyCurrentPlacement()
        }
    }

    required init?(coder: NSCoder) {
        self.windowStore = WindowStore()
        self.notificationStore = NotificationStore()
        self.workAreaReservation = WorkAreaReservation()
        self.workAreaCoordinator = AXWindowWorkAreaCoordinator(workAreaReservation: workAreaReservation)
        self.rectangleCompatibilityCoordinator = RectangleCompatibilityCoordinator()
        self.axWindowResolver = AXWindowResolver()
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
        if isHiddenForFullscreen {
            window?.orderOut(nil)
        } else {
            window?.orderFrontRegardless()
        }
        reconcileWorkAreaAfterPassiveDiscovery(windows: windowStore.windows)
        updateVisibilityForFullscreenWindow()
    }

    private func reconcileWorkAreaAfterPassiveDiscovery(windows: [WindowInfo]) {
        workAreaCoordinator.reconcile(windows: windows)
    }

    private func startFullscreenPolling(interval: Duration = .seconds(1)) {
        fullscreenPollingTask?.cancel()
        fullscreenPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                await MainActor.run {
                    self?.updateVisibilityForFullscreenWindow()
                }
            }
        }
    }

    private func updateVisibilityForFullscreenWindow() {
        let shouldHide = frontmostApplicationHasFullscreenWindow()
        guard shouldHide != isHiddenForFullscreen else { return }

        isHiddenForFullscreen = shouldHide
        if shouldHide {
            window?.orderOut(nil)
        } else {
            applyCurrentPlacement()
        }
    }

    private func frontmostApplicationHasFullscreenWindow() -> Bool {
        guard
            let frontmostApplication = NSWorkspace.shared.frontmostApplication,
            frontmostApplication.processIdentifier != ProcessInfo.processInfo.processIdentifier,
            frontmostApplication.activationPolicy == .regular
        else {
            return false
        }

        let appElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        guard let windows = axWindowResolver.copyWindows(for: appElement) else { return false }
        return windows.contains { window in
            axWindowResolver.isTrueFullscreen(window) || windowCoversMainScreen(window)
        }
    }

    private func windowCoversMainScreen(_ window: AXUIElement) -> Bool {
        guard
            let windowFrame = axWindowResolver.frame(of: window),
            let screenFrame = NSScreen.main?.frame
        else {
            return false
        }

        let tolerance: CGFloat = 4
        return abs(windowFrame.minX - screenFrame.minX) <= tolerance
            && abs(windowFrame.minY - screenFrame.minY) <= tolerance
            && abs(windowFrame.width - screenFrame.width) <= tolerance
            && abs(windowFrame.height - screenFrame.height) <= tolerance
    }
}
