import AppKit
import ApplicationServices
import TaskbarraCore

@MainActor
final class AXWindowWorkAreaCoordinator {
    private let workAreaReservation: WorkAreaReservation
    private let policy: WindowFramePolicy
    private var lastAppliedFramesByWindowID: [WindowInfo.ID: CGRect] = [:]

    init(
        workAreaReservation: WorkAreaReservation,
        policy: WindowFramePolicy = WindowFramePolicy()
    ) {
        self.workAreaReservation = workAreaReservation
        self.policy = policy
    }

    func reconcile(windows: [WindowInfo]) {
        let screenFrame = workAreaReservation.screenFrame
        let usableFrame = workAreaReservation.usableFrame
        guard !screenFrame.isEmpty, !usableFrame.isEmpty else { return }

        let liveIDs = Set(windows.map(\.id))
        lastAppliedFramesByWindowID = lastAppliedFramesByWindowID.filter { liveIDs.contains($0.key) }

        for window in windows {
            let frame = window.bounds
            guard
                policy.shouldMoveMaximizedWindow(
                    windowFrame: frame,
                    screenFrame: screenFrame,
                    usableFrame: usableFrame,
                    lastAppliedFrame: lastAppliedFramesByWindowID[window.id]
                )
            else {
                continue
            }

            guard let axWindow = findAXWindow(matching: window) else { continue }
            guard !isTrueFullscreen(axWindow), canSetFrame(axWindow) else { continue }

            if setFrame(usableFrame, for: axWindow) {
                lastAppliedFramesByWindowID[window.id] = usableFrame
            }
        }
    }

    private func findAXWindow(matching window: WindowInfo) -> AXUIElement? {
        let app = AXUIElementCreateApplication(window.ownerPID)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
            let axWindows = value as? [AXUIElement]
        else { return nil }

        return axWindows.first { axWindow in
            guard !isMinimized(axWindow), let frame = frame(of: axWindow) else { return false }
            let title = stringAttribute(kAXTitleAttribute, of: axWindow) ?? ""
            let titleMatches = window.title.isEmpty || title.isEmpty || title == window.title
            return titleMatches && policy.isApproximatelyEqual(frame, window.bounds)
        }
            ?? axWindows.first { axWindow in
                guard !isMinimized(axWindow), let frame = frame(of: axWindow) else { return false }
                return policy.isApproximatelyEqual(frame, window.bounds)
            }
    }

    private func canSetFrame(_ window: AXUIElement) -> Bool {
        isAttributeSettable(kAXPositionAttribute, of: window) && isAttributeSettable(kAXSizeAttribute, of: window)
    }

    private func isTrueFullscreen(_ window: AXUIElement) -> Bool {
        boolAttribute("AXFullScreen", of: window) ?? false
    }

    private func isMinimized(_ window: AXUIElement) -> Bool {
        boolAttribute(kAXMinimizedAttribute, of: window) ?? false
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        guard let position = cgPointAttribute(kAXPositionAttribute, of: window),
            let size = cgSizeAttribute(kAXSizeAttribute, of: window)
        else { return nil }
        return CGRect(origin: position, size: size)
    }

    private func setFrame(_ frame: CGRect, for window: AXUIElement) -> Bool {
        var position = frame.origin
        var size = frame.size
        guard let positionValue = AXValueCreate(.cgPoint, &position),
            let sizeValue = AXValueCreate(.cgSize, &size)
        else { return false }

        let positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        return positionResult == .success && sizeResult == .success
    }

    private func stringAttribute(_ attribute: String, of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? String
    }

    private func boolAttribute(_ attribute: String, of element: AXUIElement) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? Bool
    }

    private func cgPointAttribute(_ attribute: String, of element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
            let value,
            CFGetTypeID(value) == AXValueGetTypeID()
        else { return nil }
        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgPoint else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func cgSizeAttribute(_ attribute: String, of element: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
            let value,
            CFGetTypeID(value) == AXValueGetTypeID()
        else { return nil }
        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgSize else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else { return nil }
        return size
    }

    private func isAttributeSettable(_ attribute: String, of element: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        guard AXUIElementIsAttributeSettable(element, attribute as CFString, &settable) == .success else {
            return false
        }
        return settable.boolValue
    }
}
