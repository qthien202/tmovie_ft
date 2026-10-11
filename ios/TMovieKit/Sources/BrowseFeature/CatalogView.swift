import AppRouter
import DesignSystem
import FilmUI
import Models
import Networking
import SwiftUI

/// Netflix-style category page for a type list, genre or country: pills, a featured card,
/// shelves sliced by country (or by genre for a country page), then an endless filtered grid.
public struct CatalogView: View {
    let route: ListRoute

    @State private var pager: Pager
    @State private var shelves: [(title: String, films: [FilmItem])] = []
    @State private var tint = Color.brand
    @Environment(\.dismiss) private var dismiss

    public init(route: ListRoute) {
        self.route = route
        _pager = State(initialValue: Pager(route.source))
    }

    private var featured: FilmItem? { pager.items.first }

    private var genreSlug: String? {
        if case .genre(let slug) = route.source { slug } else { nil }
    }

    private var countrySlug: String? {
        if case .country(let slug) = route.source { slug } else { nil }
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 26) {
                pills
                if let featured { FeaturedCard(film: featured, tint: tint) }
                ForEach(shelves, id: \.title) { shelf in
                    Shelf(shelf.title) {
                        ForEach(shelf.films) { PosterCard(film: $0, sourceID: "\(route.title)/\(shelf.title)/\($0.slug)") }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    RailHeader(title: "Tất cả")
                    PosterGrid(pager: pager, idPrefix: "catalog/\(route.title)")
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(colors: [tint.opacity(0.4), .canvas], startPoint: .top, endPoint: .center)
                .background(Color.canvas)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: tint)
        }
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { FilterMenu(pager: pager, source: route.source) } }
        .overlay {
            if pager.items.isEmpty, !pager.loading, pager.filter != PhimAPI.Filter() {
                ContentUnavailableView("Không có phim", systemImage: "film.stack", description: Text("Thử bỏ bớt bộ lọc."))
            }
        }
        .task {
            if pager.items.isEmpty { await pager.loadMore() }
            if shelves.isEmpty { shelves = await loadShelves() }
        }
        .task(id: featured?.slug) { tint = await ColorSampler.tint(of: featured?.thumbURL) ?? .brand }
        .onChange(of: pager.filter) { Task { await pager.loadMore() } }
    }

    private var pills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Button { dismiss() } label: {
                    HStack(spacing: 6) { Text(route.title); Image(systemName: "xmark").imageScale(.small) }
                        .modifier(PillLabel())
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Đóng \(route.title)")
                GenrePickerButton(selected: genreSlug)
                GenrePickerButton(selected: countrySlug, kind: .countries)
            }
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollIndicators(.hidden)
    }

    /// Country slices for a type/genre page; genre slices for a country page.
    private func loadShelves() async -> [(title: String, films: [FilmItem])] {
        let slices: [(String, PhimAPI.Filter)] = if case .country = route.source {
            [("Hành động", .init(category: "hanh-dong")), ("Tình cảm", .init(category: "tinh-cam")),
             ("Cổ trang", .init(category: "co-trang")), ("Hài hước", .init(category: "hai-huoc")),
             ("Kinh dị", .init(category: "kinh-di"))]
        } else {
            [("Hàn Quốc", .init(country: "han-quoc")), ("Trung Quốc", .init(country: "trung-quoc")),
             ("Âu Mỹ", .init(country: "au-my")), ("Nhật Bản", .init(country: "nhat-ban")),
             ("Thái Lan", .init(country: "thai-lan")), ("Việt Nam", .init(country: "viet-nam"))]
        }
        let source = route.source
        return await withTaskGroup(of: (Int, String, [FilmItem]).self) { group in
            for (i, slice) in slices.enumerated() {
                group.addTask { (i, slice.0, (try? await PhimAPI.shared.list(source, filter: slice.1).items) ?? []) }
            }
            var out: [(Int, String, [FilmItem])] = []
            for await r in group where r.2.count >= 4 { out.append(r) }
            return out.sorted { $0.0 < $1.0 }.map { ($0.1, $0.2) }
        }
    }
}

/// Big poster card at the top of a category, Netflix style.
private struct FeaturedCard: View {
    let film: FilmItem
    let tint: Color

    var body: some View {
        let route = FilmRoute(film: film, sourceID: "featured/\(film.slug)")
        ZStack(alignment: .bottom) {
            NavigationLink(value: route) {
                RemoteImage(url: film.thumbURL, maxPoints: 900)
                    .overlay {
                        LinearGradient(stops: [.init(color: .clear, location: 0.4), .init(color: .black.opacity(0.9), location: 1)], startPoint: .top, endPoint: .bottom)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(film.name)

            VStack(spacing: 10) {
                Text(film.name)
                    .font(.system(.title, design: .serif).weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(film.genreLine).font(.footnote.weight(.medium)).foregroundStyle(.white.opacity(0.85))
                HStack(spacing: 10) {
                    PlayFilmButton(film: film)
                    SaveButton(film: film, style: .wide)
                }
                .padding(.top, 4)
            }
            .foregroundStyle(.white)
            .padding(16)
        }
        .aspectRatio(0.78, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.15)))
        .shadow(color: tint.opacity(0.35), radius: 30, y: 14)
        .zoomSource(id: route.sourceID)
        .padding(.horizontal, 24)
        .modifier(RiseIn())
    }
}
