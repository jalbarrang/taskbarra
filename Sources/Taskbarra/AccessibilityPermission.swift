@preconcurrency import ApplicationServices
import Foundation

struct AccessibilityPermission {
    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func promptForTrust() {
        let promptOption = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptOption: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
