import ApplicationServices
import CoreGraphics
import TaskbarraCore

@MainActor
struct AXWindowResolver {
    private let framePolicy: WindowFramePolicy

    init(framePolicy: WindowFramePolicy = WindowFramePolicy()) {
        self.framePolicy = framePolicy
    }

    func findWindow(matching window: WindowInfo, includeMinimized: Bool = false) -> AXUIElement? {
        let app = AXUIElementCreateApplication(window.ownerPID)
        guard let axWindows = copyWindows(for: app) else { return nil }

        return axWindows.first { axWindow in
            matches(window, axWindow: axWindow, includeMinimized: includeMinimized, requireTitle: true)
        }
            ?? axWindows.first { axWindow in
                matches(window, axWindow: axWindow, includeMinimized: includeMinimized, requireTitle: false)
            }
            ?? axWindows.first { axWindow in
                includeMinimized && isMinimized(axWindow) && titleMatches(window, axWindow: axWindow)
            }
    }

    func copyWindows(for appElement: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        guard error == .success else { return nil }
        return value as? [AXUIElement]
    }

    func isMinimized(_ window: AXUIElement) -> Bool {
        boolAttribute(kAXMinimizedAttribute, of: window) ?? false
    }

    func isTrueFullscreen(_ window: AXUIElement) -> Bool {
        boolAttribute("AXFullScreen", of: window) ?? false
    }

    func frame(of window: AXUIElement) -> CGRect? {
        guard let position = cgPointAttribute(kAXPositionAttribute, of: window),
            let size = cgSizeAttribute(kAXSizeAttribute, of: window)
        else { return nil }
        return CGRect(origin: position, size: size)
    }

    func stringAttribute(_ attribute: String, of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? String
    }

    func boolAttribute(_ attribute: String, of element: AXUIElement) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? Bool
    }

    func cgPointAttribute(_ attribute: String, of element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
            let value,
            CFGetTypeID(value) == AXValueGetTypeID()
        else { return nil }
        let axValue = unsafeDowncast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgPoint else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else { return nil }
        return point
    }

    func cgSizeAttribute(_ attribute: String, of element: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
            let value,
            CFGetTypeID(value) == AXValueGetTypeID()
        else { return nil }
        let axValue = unsafeDowncast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgSize else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else { return nil }
        return size
    }

    func isAttributeSettable(_ attribute: String, of element: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        guard AXUIElementIsAttributeSettable(element, attribute as CFString, &settable) == .success else {
            return false
        }
        return settable.boolValue
    }

    private func matches(
        _ window: WindowInfo,
        axWindow: AXUIElement,
        includeMinimized: Bool,
        requireTitle: Bool
    ) -> Bool {
        guard includeMinimized || !isMinimized(axWindow), let frame = frame(of: axWindow) else { return false }
        guard !requireTitle || titleMatches(window, axWindow: axWindow) else { return false }
        return framePolicy.isApproximatelyEqual(frame, window.bounds)
    }

    private func titleMatches(_ window: WindowInfo, axWindow: AXUIElement) -> Bool {
        let title = stringAttribute(kAXTitleAttribute, of: axWindow) ?? ""
        return window.title.isEmpty || title.isEmpty || title == window.title
    }
}
