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

    /// `refresh` (pull-to-refresh) skips the once-a-day hero cache.
    func load(refresh: Bool = false) async {
        failed = false
        async let heroTask = loadHero(refresh: refresh)
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

    // MARK: Hero: what's hot right now

    private struct HeroCache: Codable {
        let day: String
        let films: [FilmItem]
    }

    private static let heroCacheKey = "hero.hot.v5"
    private nonisolated static let preferredCountries: Set<String> = ["han-quoc", "trung-quoc", "au-my"]

    /// The most-watched titles among what is airing / updating now, built at most once a day.
    ///
    /// PhimAPI can't sort lists by views (`sort_field=view` is ignored) and Trakt's bundled client ID
    /// is revoked, so this reads each candidate's real KKPhim `view` count from its detail and ranks
    /// by that, favouring Korean / Chinese / Western titles and skipping animation (like the
    /// Flutter hero). Falls back to the freshest list if that fails.
    private func loadHero(refresh: Bool) async -> [FilmItem] {
        let today = Date.now.formatted(.iso8601.year().month().day())
        if !refresh, let data = UserDefaults.standard.data(forKey: Self.heroCacheKey),
           let cache = try? JSONDecoder().decode(HeroCache.self, from: data), cache.day == today, !cache.films.isEmpty {
            return cache.films
        }
        let hot = await rankByViews()
        guard hot.count >= 5 else { return await freshest() }
        if let data = try? JSONEncoder().encode(HeroCache(day: today, films: hot)) {
            UserDefaults.standard.set(data, forKey: Self.heroCacheKey)
        }
        return hot
    }

    private func rankByViews() async -> [FilmItem] {
        async let s1 = try? api.list(.type("phim-bo"), page: 1).items
        async let s2 = try? api.list(.type("phim-bo"), page: 2).items
        async let m1 = try? api.list(.type("phim-le"), page: 1).items
        var seen = Set<String>()
        let candidates = ((await s1 ?? []) + (await s2 ?? []) + (await m1 ?? []))
            .filter { seen.insert($0.slug).inserted && !$0.isAnimation }
        let scored = await withTaskGroup(of: (FilmItem, Double)?.self) { [api] group in
            for film in candidates {
                group.addTask {
                    guard let detail = try? await api.detail(slug: film.slug),
                          detail.episodes?.contains(where: { ($0.serverData ?? []).contains { $0.streamURL != nil } }) == true
                    else { return nil }
                    let preferred = (film.country ?? []).contains { Self.preferredCountries.contains($0.slug ?? "") }
                    return (film, Double(detail.view ?? 0) * (preferred ? 1.5 : 1))
                }
            }
            var out: [(FilmItem, Double)] = []
            for await r in group { if let r { out.append(r) } }
            return out
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(10).map(\.0)
    }

    /// Port of `HeroRepository._freshestFallback`: Hàn/Trung/Âu Mỹ first, no animation, top 10.
    private func freshest() async -> [FilmItem] {
        async let p1 = try? api.list(.type("phim-moi-cap-nhat"), page: 1).items
        async let p2 = try? api.list(.type("phim-moi-cap-nhat"), page: 2).items
        let all = (await p1 ?? []) + (await p2 ?? [])
        var seen = Set<String>()
        let films = all.filter { seen.insert($0.slug).inserted && !$0.isAnimation }
        let isPreferred = { (f: FilmItem) in (f.country ?? []).contains { Self.preferredCountries.contains($0.slug ?? "") } }
        return Array((films.filter(isPreferred) + films.filter { !isPreferred($0) }).prefix(10))
    }
}
