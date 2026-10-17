import Foundation

/// One channel of an extended M3U playlist.
public struct Channel: Identifiable, Hashable, Sendable {
    public var id: String { url.absoluteString + name }
    public let name: String
    public let logo: URL?
    public let url: URL
    public let userAgent: String?
    public let referrer: String?
    public let geoBlocked: Bool
    /// ISO code from iptv-org's `tvg-id` ("VTV1.vn@SD" → "vn"); nil for other playlists.
    public let country: String?
    /// `group-title`, split on ";" ("Movies;Series"); iptv-org's "Undefined" counts as none.
    public let categories: [String]
}

public enum M3U {
    /// Parses `#EXTINF:-1 tvg-logo="…" http-user-agent="…",Name`, optional `#EXTVLCOPT:http-…`
    /// lines, then the URL. Names lose their "(1080p)" / "[Geo-blocked]" tags.
    public static func parse(_ text: String) -> [Channel] {
        var out: [Channel] = []
        var info: String?
        var ua: String?
        var ref: String?
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("#EXTINF") {
                info = line; ua = attr(line, "http-user-agent"); ref = attr(line, "http-referrer")
            } else if line.hasPrefix("#EXTVLCOPT:http-user-agent=") {
                ua = String(line.drop { $0 != "=" }.dropFirst())
            } else if line.hasPrefix("#EXTVLCOPT:http-referrer=") {
                ref = String(line.drop { $0 != "=" }.dropFirst())
            } else if !line.isEmpty, !line.hasPrefix("#"), let i = info, let url = URL(string: line) {
                // The name follows the last attribute (`…",Name`); attributes may hold commas themselves.
                let name = i.range(of: "\",", options: .backwards).map { String(i[$0.upperBound...]) }
                    ?? String(i.drop { $0 != "," }.dropFirst())
                let clean = name.replacing(#/\s*[\[(][^\])]*[\])]/#, with: "").trimmingCharacters(in: .whitespaces)
                out.append(Channel(
                    name: clean.isEmpty ? name : clean, logo: attr(i, "tvg-logo").flatMap(URL.init(string:)), url: url,
                    userAgent: ua, referrer: ref, geoBlocked: name.contains("[Geo-blocked]"),
                    country: attr(i, "tvg-id").flatMap(country(fromID:)),
                    categories: (attr(i, "group-title") ?? "").split(separator: ";")
                        .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty && $0 != "Undefined" }
                ))
                info = nil; ua = nil; ref = nil
            }
        }
        return out
    }

    /// "VTV1.vn@SD" → "vn".
    private static func country(fromID id: String) -> String? {
        let base = id.split(separator: "@").first.map(String.init) ?? id
        guard let dot = base.lastIndex(of: ".") else { return nil }
        let code = base[base.index(after: dot)...].lowercased()
        return code.count == 2 ? code : nil
    }

    private static func attr(_ line: String, _ key: String) -> String? {
        guard let start = line.range(of: " \(key)=\"") else { return nil }
        let rest = line[start.upperBound...]
        guard let end = rest.firstIndex(of: "\"") else { return nil }
        return rest[..<end].isEmpty ? nil : String(rest[..<end])
    }
}
