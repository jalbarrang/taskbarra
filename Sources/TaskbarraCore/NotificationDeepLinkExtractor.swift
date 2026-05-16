import Foundation

public enum NotificationDeepLinkExtractor {
    private static let candidateKeys = ["fallbackDeepLink", "deepLink", "url", "URL", "link", "target"]
    private static let candidateSchemes = ["http://", "https://", "://"]

    public static func deepLink(in plist: [String: Any]) -> URL? {
        findURL(in: plist, visitedData: [])
    }

    private static func findURL(in value: Any, visitedData: Set<Int>) -> URL? {
        urlFromScalar(value)
            ?? urlFromDictionary(value, visitedData: visitedData)
            ?? urlFromArray(value, visitedData: visitedData)
            ?? urlFromData(value, visitedData: visitedData)
    }

    private static func urlFromScalar(_ value: Any) -> URL? {
        if let string = value as? String { return url(from: string) }
        return value as? URL
    }

    private static func urlFromDictionary(_ value: Any, visitedData: Set<Int>) -> URL? {
        guard let dictionary = value as? [String: Any] else { return nil }

        for key in candidateKeys {
            if let candidate = dictionary[key], let url = findURL(in: candidate, visitedData: visitedData) {
                return url
            }
        }

        for candidate in dictionary.values {
            if let url = findURL(in: candidate, visitedData: visitedData) {
                return url
            }
        }
        return nil
    }

    private static func urlFromArray(_ value: Any, visitedData: Set<Int>) -> URL? {
        guard let array = value as? [Any] else { return nil }
        for candidate in array {
            if let url = findURL(in: candidate, visitedData: visitedData) {
                return url
            }
        }
        return nil
    }

    private static func urlFromData(_ value: Any, visitedData: Set<Int>) -> URL? {
        guard let data = value as? Data else { return nil }
        let identifier = data.hashValue
        guard !visitedData.contains(identifier) else { return nil }

        var visitedData = visitedData
        visitedData.insert(identifier)

        if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let url = findURL(in: plist, visitedData: visitedData) {
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
