import AppRouter
import DesignSystem
import FilmUI
import Models
import Networking
import SwiftUI

/// Search with debounced results, plus genre chips and "Tìm kiếm hàng đầu" when idle.
public struct SearchView: View {
    public init() {}

    @State private var query = ""
    @State private var pager = Pager(.search(""))
    @State private var trending: [FilmItem] = []
    @State private var genres: [FilmCategory] = []

    private var trimmed: String { query.trimmingCharacters(in: .whitespaces) }

    public var body: some View {
        ScrollView {
            if trimmed.count < 2 { suggestions } else {
                PosterGrid(pager: pager, idPrefix: "search")
                    .padding(.top, 8)
                if pager.items.isEmpty, !pager.loading, !pager.failed {
                    ContentUnavailableView.search(text: trimmed)
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color.canvas)
        .navigationTitle("Tìm kiếm")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Phim, diễn viên, tên gốc…")
        .task(id: trimmed) {
            guard trimmed.count >= 2 else { return }
            try? await Task.sleep(for: .milliseconds(400))  // debounce typing
            guard !Task.isCancelled else { return }
            pager.source = .search(trimmed)
            await pager.loadMore()
        }
        .task {
            if trending.isEmpty { trending = (try? await PhimAPI.shared.list(.type("phim-moi-cap-nhat")).items) ?? [] }
            if genres.isEmpty { genres = (try? await PhimAPI.shared.taxonomy(.genres)) ?? [] }
        }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !genres.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Khám phá thể loại").font(.title3.bold()).padding(.horizontal, 16)
                    ScrollView(.horizontal) {
                        // Two staggered rows of chips, filled alternately.
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(0..<2, id: \.self) { row in
                                HStack(spacing: 8) {
                                    ForEach(genres.indices.filter { $0 % 2 == row }, id: \.self) { genreChip(genres[$0]) }
                                }
                            }
                        }
                    }
                    .contentMargins(.horizontal, 16, for: .scrollContent)
                    .scrollIndicators(.hidden)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Tìm kiếm hàng đầu").font(.title3.bold()).padding(.horizontal, 16)
                LazyVStack(spacing: 6) {
                    ForEach(trending) { film in
                        NavigationLink(value: FilmRoute(film: film, sourceID: "top-search/\(film.slug)")) {
                            HStack(spacing: 12) {
                                RemoteImage(url: film.thumbURL, maxPoints: 200)
                                    .frame(width: 140, height: 78)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .zoomSource(id: "top-search/\(film.slug)")
                                Text(film.name).font(.subheadline.weight(.medium)).lineLimit(2).multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "play.circle").font(.title2.weight(.light))
                            }
                            .padding(.horizontal, 16)
                            .contentShape(.rect)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private func genreChip(_ g: FilmCategory) -> some View {
        NavigationLink(value: ListRoute(title: g.name ?? "", source: .genre(g.slug ?? ""))) {
            Text(g.name ?? "")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(height: 40)
                .glassSurface(in: .rect(cornerRadius: 10), interactive: true)
        }
        .buttonStyle(PressableStyle())
    }
}
