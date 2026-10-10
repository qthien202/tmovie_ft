import AppRouter
import DesignSystem
import FilmUI
import Models
import Networking
import SwiftUI

/// "Mới & Hot": upcoming, airing and completed series as a feed of large cards.
public struct NewHotView: View {
    public init() {}

    enum Feed: String, CaseIterable, Identifiable {
        case upcoming = "🍿 Sắp chiếu", airing = "🔥 Đang chiếu", completed = "✅ Trọn bộ"
        var id: Self { self }
        var source: PhimAPI.Source {
            switch self {
            case .upcoming: .type("phim-sap-chieu")
            case .airing: .type("phim-bo-dang-chieu")
            case .completed: .type("phim-bo-hoan-thanh")
            }
        }
    }

    @State private var feed = Feed.upcoming
    @State private var pager = Pager(Feed.upcoming.source)
    @Namespace private var pill

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28, pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(pager.items) { film in
                        FeedCard(film: film)
                            .onAppear { if film.slug == pager.items.last?.slug { Task { await pager.loadMore() } } }
                    }
                    if pager.loading { ProgressView().frame(maxWidth: .infinity) }
                } header: {
                    pills
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color.canvas)
        .navigationTitle("Mới & Hot")
        .task(id: feed) {
            pager.source = feed.source
            await pager.loadMore()
        }
    }

    private var pills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Feed.allCases) { f in
                    Button { withAnimation(.snappy) { feed = f } } label: {
                        Text(f.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(feed == f ? .black : .white)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background {
                                if feed == f { Capsule().fill(.white).matchedGeometryEffect(id: "pill", in: pill) }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .glassSurface()
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollIndicators(.hidden)
        .padding(.vertical, 8)
    }
}

/// Big landscape card for the New & Hot feed.
private struct FeedCard: View {
    let film: FilmItem

    var body: some View {
        let route = FilmRoute(film: film, sourceID: "feed/\(film.slug)")
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(value: route) {
                RemoteImage(url: film.thumbURL, maxPoints: 700)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .zoomSource(id: route.sourceID)
                    .scrollTransition(.animated(.cinematic)) { c, p in
                        c.scaleEffect(p.isIdentity ? 1 : 0.95).opacity(p.isIdentity ? 1 : 0.5)
                    }
            }
            .buttonStyle(PressableStyle())
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(film.name).font(.title3.bold()).lineLimit(2)
                    Text(film.metaLine).font(.caption).foregroundStyle(.secondary)
                    Text(film.genreLine).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                SaveButton(film: film)
            }
        }
        .padding(.horizontal, 16)
    }
}
