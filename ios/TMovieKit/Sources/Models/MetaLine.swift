import Foundation

/// "★ 8.4 · 2026 · FHD · Phụ đề · Tập 12", same fields as the Flutter hero.
public func metaLine(tmdb: TmdbInfo?, imdb: ImdbInfo?, year: Int?, quality: String?, lang: String?, episode: String?) -> String {
    let vote = [tmdb?.voteAverage, imdb?.voteAverage].compactMap { $0 }.first { $0 > 0 }
    let parts: [String?] = [
        vote.map { "★ " + $0.formatted(.number.precision(.fractionLength(1))) },
        year.map(String.init), quality,
        (lang ?? "").localizedCaseInsensitiveContains("vietsub") ? "Phụ đề" : nil,
        episode,
    ]
    return parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
}
