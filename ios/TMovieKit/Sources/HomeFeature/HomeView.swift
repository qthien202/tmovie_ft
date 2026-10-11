import DesignSystem
import FilmUI
import Models
import Persistence
import SwiftData
import SwiftUI

/// Home: Apple TV-style hero tinted by its art, category pills, then Continue Watching,
/// My List, Top 10 and genre shelves over a colour wash from the hero.
public struct HomeView: View {
    @State private var store = HomeStore()
    @State private var heroPage: String?
    @State private var tint = Color.brand
    @Query(sort: \WatchRecord.updatedAt, order: .reverse) private var history: [WatchRecord]
    @Query(sort: \SavedFilm.addedAt, order: .reverse) private var saved: [SavedFilm]

    public init() {}

    private var heroFilm: FilmItem? { store.hero.first { $0.slug == heroPage } ?? store.hero.first }
    private var heroArt: URL? { heroFilm.flatMap { store.heroArt[$0.slug] ?? $0.thumbURL } }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 26) {
                HeroCarousel(films: store.hero, art: store.heroArt, tint: tint, page: $heroPage)
                if !history.isEmpty {
                    Shelf("Xem tiếp") {
                        ForEach(history.prefix(15)) { ContinueCard(record: $0) }
                    }
                }
                if !saved.isEmpty {
                    Shelf("Danh sách của tôi") {
                        ForEach(saved.compactMap(\.film)) { PosterCard(film: $0, sourceID: "mylist/\($0.slug)") }
                    }
                }
                if !store.top10.isEmpty {
                    Top10Shelf(films: store.top10, more: Rail.top10.more)
                }
                ForEach(Rail.home.filter { store.rails[$0]?.isEmpty != true }) { rail in
                    Shelf(rail.title, more: rail.more) {
                        if let films = store.rails[rail] {
                            ForEach(films) { PosterCard(film: $0, sourceID: "\(rail.title)/\($0.slug)") }
                        } else {
                            ForEach(0..<5, id: \.self) { _ in PosterPlaceholder() }
                        }
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background { AmbientBackground(url: heroArt, tint: tint) }
        .overlay(alignment: .top) { HomeHeader() }
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if store.failed {
                ContentUnavailableView {
                    Label("Không tải được phim", systemImage: "wifi.exclamationmark")
                } actions: {
                    Button("Thử lại") { Task { await store.load() } }.buttonStyle(.borderedProminent)
                }
            }
        }
        .refreshable { await store.load(refresh: true) }
        .task { if store.hero.isEmpty { await store.load() } }
        .task(id: heroArt) {
            let sampled = await ColorSampler.tint(of: heroArt) ?? .brand
            withAnimation(.easeInOut(duration: 0.8)) { tint = sampled }
        }
    }
}

private struct PosterPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.white.opacity(0.06)).frame(width: 112, height: 168)
            .shimmering()
            .clipShape(.rect(cornerRadius: 8, style: .continuous))
    }
}
