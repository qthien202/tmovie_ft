import Foundation

/// PhimAPI mixes absolute URLs, `upload/vod/...`, `uploads/movies/...` and bare file names.
/// (The Dart helper prefixed `uploads/movies/` onto `upload/vod/...`, which 404s.)
func phimImageURL(_ raw: String?) -> URL? {
    guard let raw, !raw.isEmpty else { return nil }
    if raw.hasPrefix("http") { return URL(string: raw) }
    let path = raw.hasPrefix("/") ? String(raw.dropFirst()) : raw
    return URL(string: "https://phimimg.com/" + (path.contains("/") ? path : "uploads/movies/" + path))
}

func tmdbImageURL(_ path: String?, size: String) -> URL? {
    guard let path, !path.isEmpty else { return nil }
    return URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
}
