import Foundation
import Models

/// What's hot in Vietnam right now: Netflix's weekly Top 10 (TV + films) matched to PhimAPI films
/// by `tools/hot/crawl_hot.py`, which a GitHub Action publishes every 6 hours on `hot-data`.
public struct HotList: Sendable {
    /// Ranked, TV and films interleaved.
    public let films: [FilmItem]
    /// Ranked series only.
    public let series: [FilmItem]
    /// Last day of the Netflix week the ranking covers.
    public let week: String?

    static let url = URL(string: "https://raw.githubusercontent.com/qthien202/tmovie_ft/hot-data/hot.json")!

    public static func fetch(session: URLSession = .shared) async -> HotList? {
        struct File: Decodable {
            let week: String?
            let items: [Entry]
        }
        struct Entry: Decodable {
            let kind: String
            let film: FilmItem
        }
        guard let file: File = try? await session.json(url) else { return nil }
        let entries = file.items.filter { !$0.film.isAdult }
        return HotList(
            films: entries.map(\.film),
            series: entries.filter { $0.kind == "tv" }.map(\.film),
            week: file.week
        )
    }
}
