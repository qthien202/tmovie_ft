import Foundation

/// Strips ads that the stream providers splice into HLS media playlists.
///
/// KKPhim / OPhim streams insert ads as runs of segments wrapped in `#EXT-X-DISCONTINUITY` tags,
/// served from a different path than the film (`convertv8/x.ts`, `/v8/<hash>/segment_0001.ts`
/// among bare `abc123.ts` segments). This drops every discontinuity-delimited block whose
/// segments all come from another path, plus the tags around it. Master playlists and playlists
/// without discontinuities pass through, and nothing is cut beyond a quarter of the running time.
/// Same rules as the Android `HlsAdFilter`, tested on the same playlist.
public enum HLSAdFilter {
    private static let discontinuity = "#EXT-X-DISCONTINUITY"

    private struct Block {
        let lines: [String]
        var segments: [String] { lines.filter { !$0.isEmpty && !$0.hasPrefix("#") } }
        var duration: Double {
            lines.filter { $0.hasPrefix("#EXTINF:") }
                .compactMap { Double($0.dropFirst(8).split(separator: ",").first ?? "") }
                .reduce(0, +)
        }
    }

    /// Directory part of a segment URI: "" for "abc.ts", "convertv8" for "convertv8/x.ts".
    private static func directory(_ segment: String) -> String {
        let path = segment.split(separator: "?").first.map(String.init) ?? segment
        guard let slash = path.lastIndex(of: "/") else { return "" }
        return String(path[..<slash])
    }

    public static func clean(_ playlist: String) -> String {
        guard !playlist.contains("#EXT-X-STREAM-INF"), playlist.contains(discontinuity) else { return playlist }
        let lines = playlist.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        guard let headerEnd = lines.firstIndex(where: { $0.hasPrefix("#EXTINF") || $0 == discontinuity }) else { return playlist }
        let header = Array(lines[..<headerEnd])
        let endList = lines[headerEnd...].contains("#EXT-X-ENDLIST")

        var blocks: [Block] = []
        var current: [String] = []
        for line in lines[headerEnd...] {
            switch line {
            case discontinuity:
                if !current.isEmpty { blocks.append(Block(lines: current)) }
                current = []
            case "#EXT-X-ENDLIST": break
            default: current.append(line)
            }
        }
        if !current.isEmpty { blocks.append(Block(lines: current)) }

        // The film's segments live in the directory that holds the most segments.
        let counts = Dictionary(blocks.flatMap(\.segments).map { (directory($0), 1) }, uniquingKeysWith: +)
        guard let mainDirectory = counts.max(by: { $0.value < $1.value })?.key else { return playlist }
        let kept = blocks.filter { $0.segments.isEmpty || $0.segments.contains { directory($0) == mainDirectory } }
        let dropped = blocks.filter { !$0.segments.isEmpty && !$0.segments.contains { directory($0) == mainDirectory } }
        guard !dropped.isEmpty else { return playlist }
        let total = blocks.map(\.duration).reduce(0, +)
        guard total > 0, dropped.map(\.duration).reduce(0, +) <= total / 4 else { return playlist }

        var out = header
        for (i, block) in kept.enumerated() {
            if i > 0 { out.append(discontinuity) }
            out += block.lines.filter { !$0.isEmpty }
        }
        if endList { out.append("#EXT-X-ENDLIST") }
        return out.joined(separator: "\n") + "\n"
    }
}
