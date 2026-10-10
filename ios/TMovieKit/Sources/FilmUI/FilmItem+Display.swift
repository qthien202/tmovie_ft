import Models

extension FilmItem {
    /// "★ 8.4 · 2026 · FHD · Phụ đề · Tập 12"
    public var metaLine: String {
        Models.metaLine(tmdb: tmdb, imdb: imdb, year: year, quality: quality, lang: lang, episode: episodeCurrent)
    }

    /// "Tình cảm • Cổ trang • Chính kịch"
    public var genreLine: String { (category ?? []).prefix(3).compactMap(\.name).joined(separator: " • ") }

    /// TMDB score, else IMDb, when either is above zero.
    public var rating: Double? { [tmdb?.voteAverage, imdb?.voteAverage].compactMap { $0 }.first { $0 > 0 } }
}
