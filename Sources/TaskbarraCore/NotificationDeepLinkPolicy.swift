import Foundation

public struct NotificationDeepLinkPolicy: Sendable {
    public enum Decision: Equatable, Sendable {
        case allow
        case confirm
        case block
    }

    public let allowedSchemes: Set<String>
    public let blockedSchemes: Set<String>

    public init(
        allowedSchemes: Set<String> = ["http", "https"],
        blockedSchemes: Set<String> = ["file", "javascript", "data"]
    ) {
        self.allowedSchemes = Set(allowedSchemes.map { $0.lowercased() })
        self.blockedSchemes = Set(blockedSchemes.map { $0.lowercased() })
    }

    public func decision(for url: URL) -> Decision {
        guard let scheme = url.scheme?.lowercased(), !scheme.isEmpty else { return .block }
        if blockedSchemes.contains(scheme) { return .block }
        if allowedSchemes.contains(scheme) { return .allow }
        return .confirm
    }

    public func schemeDescription(for url: URL) -> String {
        url.scheme?.lowercased() ?? "unknown"
    }
}
