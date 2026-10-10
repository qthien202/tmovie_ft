import AppRouter
import Foundation
import Models
import Networking
import Observation

/// A horizontal rail on Home.
struct Rail: Identifiable, Hashable {
    let title: String
    let source: PhimAPI.Source
    var id: PhimAPI.Source { source }
    var more: ListRoute { ListRoute(title: title, source: source) }

    static let home: [Rail] = [
        Rail(title: "Mới cập nhật", source: .type("phim-moi-cap-nhat")),
        Rail(title: "Phim Hàn Quốc", source: .country("han-quoc")),
        Rail(title: "Phim Trung Quốc", source: .country("trung-quoc")),
        Rail(title: "Phim lẻ", source: .type("phim-le")),
        Rail(title: "TV Shows", source: .type("tv-shows")),
        Rail(title: "Hành động", source: .genre("hanh-dong")),
        Rail(title: "Tình cảm", source: .genre("tinh-cam")),
        Rail(title: "Kinh dị", source: .genre("kinh-di")),
        Rail(title: "Hoạt hình", source: .type("hoat-hinh")),
    ]

    /// Big-number rail.
    static let top10 = Rail(title: "Top 10 phim bộ hôm nay", source: .type("phim-bo"))
}

@MainActor @Observable
final class HomeStore {
    private(set) var hero: [FilmItem] = []
    /// Textless TMDB backdrops (w1280) per hero slug: cleaner, sharper key art than PhimAPI thumbs.
    private(set) var heroArt: [String: URL] = [:]
    private(set) var rails: [Rail: [FilmItem]] = [:]
    private(set) var failed = false

    private let api: PhimAPI

    init(api: PhimAPI = .shared) { self.api = api }

    func load() async {
        failed = false
        async let heroTask = loadHero()
        await withTaskGroup(of: (Rail, [FilmItem]).self) { [api] group in
            for rail in Rail.home + [Rail.top10] {
                group.addTask { (rail, (try? await api.list(rail.source).items) ?? []) }
            }
            for await (rail, items) in group { rails[rail] = items }
        }
        hero = await heroTask
        await withTaskGroup(of: (String, URL?).self) { [api, hero] group in
            for film in hero {
                group.addTask {
                    let images = (try? await api.images(slug: film.slug)) ?? []
                    let clean = images.first { $0.type == "backdrop" && $0.iso6391 == nil } ?? images.first { $0.type == "backdrop" }
                    return (film.slug, clean?.url(size: "w1280"))
                }
            }
            for await (slug, url) in group { heroArt[slug] = url }
        }
        failed = hero.isEmpty && rails.values.allSatisfy(\.isEmpty)
    }

    /// Port of `HeroRepository._freshestFallback`: Hàn/Trung/Âu Mỹ first, no animation, top 10.
    // ponytail: Trakt trending match is skipped until a working Trakt client ID exists (bundled one 403s).
    private func loadHero() async -> [FilmItem] {
        async let p1 = try? api.list(.type("phim-moi-cap-nhat"), page: 1).items
        async let p2 = try? api.list(.type("phim-moi-cap-nhat"), page: 2).items
        let all = (await p1 ?? []) + (await p2 ?? [])
        var seen = Set<String>()
        let films = all.filter { seen.insert($0.slug).inserted && !$0.isAnimation }
        let preferred: Set<String> = ["han-quoc", "trung-quoc", "au-my"]
        let isPreferred = { (f: FilmItem) in (f.country ?? []).contains { preferred.contains($0.slug ?? "") } }
        return Array((films.filter(isPreferred) + films.filter { !isPreferred($0) }).prefix(10))
    }
}
