import Foundation

public enum NotificationDeepLinkExtractor {
    private static let candidateKeys = ["fallbackDeepLink", "deepLink", "url", "URL", "link", "target"]
    private static let candidateSchemes = ["http://", "https://", "://"]

    private static let maxRecursionDepth = 12
    private static let maxCollectionItems = 64
    private static let maxDataBytes = 256 * 1024

    public static func deepLink(in plist: [String: Any]) -> URL? {
        findURL(in: plist, context: SearchContext())
    }

    private static func findURL(in value: Any, context: SearchContext) -> URL? {
        guard context.depth <= maxRecursionDepth else { return nil }

        return urlFromScalar(value)
            ?? urlFromDictionary(value, context: context)
            ?? urlFromArray(value, context: context)
            ?? urlFromData(value, context: context)
    }

    private static func urlFromScalar(_ value: Any) -> URL? {
        if let string = value as? String { return url(from: string) }
        return value as? URL
    }

    private static func urlFromDictionary(_ value: Any, context: SearchContext) -> URL? {
        guard let dictionary = value as? [String: Any], dictionary.count <= maxCollectionItems else { return nil }
        let nestedContext = context.descending()

        for key in candidateKeys {
            if let candidate = dictionary[key], let url = findURL(in: candidate, context: nestedContext) {
                return url
            }
        }

        for candidate in dictionary.values.prefix(maxCollectionItems) {
            if let url = findURL(in: candidate, context: nestedContext) {
                return url
            }
        }
        return nil
    }

    private static func urlFromArray(_ value: Any, context: SearchContext) -> URL? {
        guard let array = value as? [Any], array.count <= maxCollectionItems else { return nil }
        let nestedContext = context.descending()

        for candidate in array.prefix(maxCollectionItems) {
            if let url = findURL(in: candidate, context: nestedContext) {
                return url
            }
        }
        return nil
    }

    private static func urlFromData(_ value: Any, context: SearchContext) -> URL? {
        guard let data = value as? Data, data.count <= maxDataBytes else { return nil }
        let identifier = DataIdentifier(data: data)
        guard !context.visitedData.contains(identifier) else { return nil }

        var nestedContext = context.descending()
        nestedContext.visitedData.insert(identifier)

        if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let url = findURL(in: plist, context: nestedContext) {
            return url
        }

        if let string = String(data: data, encoding: .utf8) {
            return url(from: string)
        }
        return nil
    }

    private static func url(from string: String) -> URL? {
        guard candidateSchemes.contains(where: string.contains) else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }

        guard let range = trimmed.range(of: #"[A-Za-z][A-Za-z0-9+.-]*://[^\s\"'<>]+"#, options: .regularExpression)
        else { return nil }
        return URL(string: String(trimmed[range]))
    }
}

private struct SearchContext {
    var depth: Int = 0
    var visitedData: Set<DataIdentifier> = []

    func descending() -> SearchContext {
        var context = self
        context.depth += 1
        return context
    }
}

private struct DataIdentifier: Hashable {
    private let count: Int
    private let prefix: Data
    private let suffix: Data

    init(data: Data) {
        count = data.count
        prefix = data.prefix(32)
        suffix = data.suffix(32)
    }
}
