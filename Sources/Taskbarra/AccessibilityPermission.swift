import ApplicationServices
import Foundation

struct AccessibilityPermission {
    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func promptForTrust() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
