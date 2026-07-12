import AppKit
import CoreGraphics
import TaskbarraCore

@MainActor
final class MultiMonitorTaskbarCoordinator {
    private let barHeight = TaskbarGeometry.defaultHeight
    private let windowStore: WindowStore
    private let windowDisplayStore: WindowDisplayStore
    private let notificationStore: NotificationStore
    private let workAreaReservation: WorkAreaReservation
    private let workAreaCoordinator: AXWindowWorkAreaCoordinator
    private let rectangleCompatibilityCoordinator: RectangleCompatibilityCoordinator
    private let axWindowResolver: AXWindowResolver
    private let displayOcclusionPolicy: DisplayOcclusionPolicy
    private let windowScreenAssigner: WindowScreenAssigner
    private let interactionController: WindowInteractionController
    private var placementObserver: TaskbarPlacementObserver
    private var panelsByDisplayID: [CGDirectDisplayID: TaskbarPanelController] = [:]
    private var screenReconciliationTask: Task<Void, Never>?
    private var fullscreenPollingTask: Task<Void, Never>?
    private var isStarted = false

    init(
        windowStore: WindowStore = WindowStore(),
        notificationStore: NotificationStore = NotificationStore(),
        workAreaReservation: WorkAreaReservation = WorkAreaReservation()
    ) {
        self.windowStore = windowStore
        self.windowDisplayStore = WindowDisplayStore()
        self.notificationStore = notificationStore
        self.workAreaReservation = workAreaReservation
        self.workAreaCoordinator = AXWindowWorkAreaCoordinator(workAreaReservation: workAreaReservation)
        self.rectangleCompatibilityCoordinator = RectangleCompatibilityCoordinator()
        self.axWindowResolver = AXWindowResolver()
        self.displayOcclusionPolicy = DisplayOcclusionPolicy()
        self.windowScreenAssigner = WindowScreenAssigner()
        self.interactionController = WindowInteractionController(refreshWindows: { [weak windowStore] in
            windowStore?.refreshPassiveSnapshot()
        })
        self.placementObserver = TaskbarPlacementObserver {}

        windowStore.onPassiveSnapshotDidChange = { [weak self] windows in
            self?.updateWindowAssignments(windows: windows)
            self?.workAreaCoordinator.reconcile(windows: windows)
            self?.updateVisibilityForFullscreenWindows()
        }
        self.placementObserver = TaskbarPlacementObserver { [weak self] in
            self?.scheduleScreenReconciliation()
        }
    }

    func start() {
        guard !isStarted else {
            showPanels()
            return
        }
        isStarted = true
        reconcileScreens()
        windowStore.startMonitoring()
        notificationStore.startMonitoring()
        placementObserver.start()
        startFullscreenPolling()
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        placementObserver.stop()
        screenReconciliationTask?.cancel()
        screenReconciliationTask = nil
        fullscreenPollingTask?.cancel()
        fullscreenPollingTask = nil
        windowStore.stopMonitoring()
        notificationStore.stopMonitoring()
        windowStore.onPassiveSnapshotDidChange = nil
        for panel in panelsByDisplayID.values {
            panel.tearDown()
        }
        panelsByDisplayID.removeAll()
        windowDisplayStore.removeAll()
        workAreaReservation.removeAll()
    }

    private func scheduleScreenReconciliation() {
        screenReconciliationTask?.cancel()
        screenReconciliationTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            self?.reconcileScreens()
        }
    }

    private func reconcileScreens() {
        let screens = eligibleScreens()
        let liveDisplayIDs = Set(screens.map { $0.id })

        for displayID in Array(panelsByDisplayID.keys) where !liveDisplayIDs.contains(displayID) {
            panelsByDisplayID.removeValue(forKey: displayID)?.tearDown()
            windowDisplayStore.removeDisplay(displayID)
            workAreaReservation.removeReservation(for: displayID)
        }

        for displayID in workAreaReservation.displayIDs where !liveDisplayIDs.contains(displayID) {
            workAreaReservation.removeReservation(for: displayID)
        }

        for (displayID, screen) in screens {
            let geometry = TaskbarGeometry.forScreen(screen, barHeight: barHeight)
            workAreaReservation.apply(geometry: geometry, for: displayID)
            if panelsByDisplayID[displayID] == nil {
                panelsByDisplayID[displayID] = TaskbarPanelController(
                    displayID: displayID,
                    screen: screen,
                    windowStore: windowStore,
                    windowDisplayStore: windowDisplayStore,
                    notificationStore: notificationStore,
                    interactionController: interactionController
                )
            }
            panelsByDisplayID[displayID]?.show()
        }

        updateWindowAssignments(windows: windowStore.windows, screens: screens)
        if !screens.isEmpty {
            rectangleCompatibilityCoordinator.reserveTaskbarSpaceIfRectangleIsPresent(taskbarHeight: barHeight)
        }
        workAreaCoordinator.reconcile(windows: windowStore.windows)
        updateVisibilityForFullscreenWindows()
    }

    private func showPanels() {
        for panel in panelsByDisplayID.values {
            panel.show()
        }
    }

    private func eligibleScreens() -> [(id: CGDirectDisplayID, screen: NSScreen)] {
        NSScreen.screens.compactMap { screen in
            guard let displayID = displayID(for: screen) else { return nil }
            let isMirroredReplica = CGDisplayIsInMirrorSet(displayID) != 0
                && CGDisplayMirrorsDisplay(displayID) != kCGNullDirectDisplay
            guard !isMirroredReplica else { return nil }
            return (displayID, screen)
        }
    }

    private func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return number.uint32Value
    }

    private func updateWindowAssignments(windows: [WindowInfo]) {
        updateWindowAssignments(windows: windows, screens: eligibleScreens())
    }

    private func updateWindowAssignments(
        windows: [WindowInfo],
        screens: [(id: CGDirectDisplayID, screen: NSScreen)]
    ) {
        let displays = screens.map { DisplayDescriptor(id: $0.id, frame: CGDisplayBounds($0.id)) }
        let primaryDisplayID = NSScreen.screens.first.flatMap { displayID(for: $0) }
        let fallbackDisplayID = primaryDisplayID.flatMap { primaryID in
            displays.contains { $0.id == primaryID } ? primaryID : nil
        } ?? displays.first?.id
        windowDisplayStore.update(
            windows: windows,
            displays: displays,
            fallbackDisplayID: fallbackDisplayID
        )
    }

    private func startFullscreenPolling(interval: Duration = .seconds(1)) {
        fullscreenPollingTask?.cancel()
        fullscreenPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled else { return }
                self?.updateVisibilityForFullscreenWindows()
            }
        }
    }

    private func updateVisibilityForFullscreenWindows() {
        let displays = eligibleScreens().map { screen in
            DisplayDescriptor(id: screen.id, frame: CGDisplayBounds(screen.id))
        }
        var occludedDisplayIDs = displayOcclusionPolicy.occludedDisplayIDs(
            windows: windowStore.windows,
            displays: displays
        )
        occludedDisplayIDs.formUnion(trueFullscreenDisplayIDs(displays: displays))

        let hideEveryPanel = !NSScreen.screensHaveSeparateSpaces && !occludedDisplayIDs.isEmpty
        for (displayID, panel) in panelsByDisplayID {
            panel.setHiddenForFullscreen(hideEveryPanel || occludedDisplayIDs.contains(displayID))
        }
    }

    private func trueFullscreenDisplayIDs(displays: [DisplayDescriptor]) -> Set<CGDirectDisplayID> {
        guard
            let frontmostApplication = NSWorkspace.shared.frontmostApplication,
            frontmostApplication.processIdentifier != ProcessInfo.processInfo.processIdentifier,
            frontmostApplication.activationPolicy == .regular
        else {
            return []
        }

        let appElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        guard let windows = axWindowResolver.copyWindows(for: appElement) else { return [] }
        return Set(windows.compactMap { window in
            guard axWindowResolver.isTrueFullscreen(window), let frame = axWindowResolver.frame(of: window) else {
                return nil
            }
            return windowScreenAssigner.displayID(for: frame, among: displays)
        })
    }
}
