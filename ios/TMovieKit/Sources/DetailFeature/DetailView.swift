import AppRouter
import DesignSystem
import FilmUI
import Models
import Networking
import Persistence
import PlayerFeature
import SwiftData
import SwiftUI

/// Netflix-style detail: 16:10 art, Play/Resume, synopsis, actions, cast, then Episodes / Similar / Images tabs.
public struct DetailView: View {
    let route: FilmRoute

    @State private var detail: FilmDetail?
    @State private var synopsis = ""
    @State private var people: [FilmPerson] = []
    @State private var backdrops: [FilmImage] = []
    @State private var similar: [FilmItem] = []
    @State private var failed = false
    @State private var noLink = false
    @State private var expanded = false
    @State private var tab = Tab.episodes
    @Query private var records: [WatchRecord]
    @Namespace private var tabLine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Tab: String, CaseIterable { case episodes = "Tập phim", similar = "Tương tự", images = "Hình ảnh" }

    public init(route: FilmRoute) {
        self.route = route
        let slug = route.film.slug
        _records = Query(filter: #Predicate<WatchRecord> { $0.slug == slug })
    }

    private var film: FilmItem { detail.map(FilmItem.init) ?? route.film }
    private var record: WatchRecord? { records.first }
    /// Unfiltered so indices match what the player saves.
    private var servers: [Episode] { detail?.episodes ?? [] }
    private var isSeries: Bool { servers.contains { ($0.serverData?.count ?? 0) > 1 } }
    private var tabs: [Tab] { (isSeries ? [.episodes] : []) + [.similar] + (backdrops.isEmpty ? [] : [.images]) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                VStack(alignment: .leading, spacing: 14) {
                    titleBlock
                    actions
                    if !people.isEmpty { castRail }
                    tabBar
                    tabContent
                }
                .padding(.top, 12)
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background(Color.canvas)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Phim này chưa có link phát", isPresented: $noLink) {}
        .task { await load() }
    }

    // MARK: Header

    private var header: some View {
        RemoteImage(url: film.thumbURL, maxPoints: 1000)
            .aspectRatio(16 / 10, contentMode: .fit)
            .overlay {
                LinearGradient(stops: [
                    .init(color: .black.opacity(0.6), location: 0), .init(color: .clear, location: 0.3),
                    .init(color: .clear, location: 0.6), .init(color: .canvas, location: 1),
                ], startPoint: .top, endPoint: .bottom)
            }
            .visualEffect { [reduceMotion] content, geo in
                let y = geo.frame(in: .scrollView(axis: .vertical)).minY
                return content
                    .scaleEffect(reduceMotion || y <= 0 ? 1 : 1 + y / geo.size.height, anchor: .bottom)
                    .offset(y: reduceMotion || y > 0 ? 0 : -y * 0.3)
            }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(film.name).font(.system(.title, design: .serif).weight(.bold))
            if let origin = film.originName, !origin.isEmpty {
                Text(origin).font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                if let vote = film.rating {
                    Text("★ " + vote.formatted(.number.precision(.fractionLength(1)))).foregroundStyle(.yellow)
                }
                if let year = film.year { Text(String(year)) }
                if let q = film.quality, !q.isEmpty {
                    Text(q).font(.caption2.weight(.bold)).padding(.horizontal, 5).padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.secondary))
                }
                if let ep = film.episodeCurrent { Text(ep) }
                if let time = detail?.time, !time.isEmpty { Text(time) }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)

            Button(action: play) {
                PlayWideLabel(record.map { "Tiếp tục \($0.episodeName)" } ?? "Phát")
            }
            .buttonStyle(PressableStyle())
            .disabled(detail == nil)
            .padding(.top, 4)

            if failed {
                Button("Không tải được phim · Thử lại") { Task { await load() } }.font(.footnote)
            }

            if !synopsis.isEmpty {
                Text(synopsis)
                    .font(.subheadline)
                    .lineLimit(expanded ? nil : 3)
                    .onTapGesture { withAnimation(.snappy) { expanded.toggle() } }
                    .accessibilityAddTraits(.isButton)
            }
            credits
        }
        .padding(.horizontal, 16)
        .redacted(reason: detail == nil && !failed ? .placeholder : [])
    }

    @ViewBuilder private var credits: some View {
        // PhimAPI fills unknown credits with "Đang cập nhật".
        let known = { (name: String) in !name.isEmpty && name != "Đang cập nhật" }
        let actors = (detail?.actor ?? []).filter(known).prefix(4)
        let directors = people.filter { $0.knownForDepartment == "Directing" }.compactMap(\.name)
        let director = directors.isEmpty ? (detail?.director ?? []).filter(known) : directors
        if !actors.isEmpty { creditLine("Diễn viên", actors.joined(separator: ", ")) }
        if !director.isEmpty { creditLine("Đạo diễn", director.joined(separator: ", ")) }
    }

    private func creditLine(_ label: String, _ value: String) -> some View {
        (Text(label + ": ").foregroundStyle(.secondary) + Text(value).foregroundStyle(.secondary.opacity(0.8)))
            .font(.caption)
            .lineLimit(1)
    }

    private var actions: some View {
        HStack(spacing: 28) {
            SaveButton(film: film)
            ShareLink(item: "\(film.name)\(film.originName.map { " (\($0))" } ?? "") — đang xem trên TMovie") {
                ActionLabel("Chia sẻ", systemImage: "paperplane")
            }
            if let trailer = detail?.trailerUrl.flatMap(URL.init(string:)) {
                Link(destination: trailer) { ActionLabel("Trailer", systemImage: "film") }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
    }

    private var castRail: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 14) {
                ForEach(Array(people.filter { $0.knownForDepartment == "Acting" }.enumerated()), id: \.offset) { _, person in
                    VStack(spacing: 4) {
                        RemoteImage(url: person.profileURL(), maxPoints: 80)
                            .frame(width: 64, height: 64)
                            .clipShape(.circle)
                        Text(person.name ?? "").font(.caption2.weight(.semibold)).lineLimit(1)
                        Text(person.character ?? "").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                    .frame(width: 72)
                }
            }
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollIndicators(.hidden)
    }

    // MARK: Tabs

    private var tabBar: some View {
        HStack(spacing: 24) {
            ForEach(tabs, id: \.self) { t in
                Button { withAnimation(.snappy) { tab = t } } label: {
                    Text(t.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(current == t ? .white : .secondary)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .overlay(alignment: .top) {
                            if current == t {
                                Rectangle().fill(Color.brand).frame(height: 4).matchedGeometryEffect(id: "line", in: tabLine)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .overlay(alignment: .top) { Divider() }
        .padding(.top, 8)
    }

    /// Falls back to the first available tab when the chosen one disappears (e.g. a film, not a series).
    private var current: Tab { tabs.contains(tab) ? tab : tabs.first ?? .similar }

    @ViewBuilder private var tabContent: some View {
        switch current {
        case .episodes:
            EpisodeList(servers: servers, record: record, stills: backdrops, fallback: film.thumbURL) { server, list, i in
                if let detail { Player.play(detail, server: server, episodes: list, at: i) }
            }
        case .similar:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
                ForEach(similar) { f in
                    PosterCard(film: f, sourceID: "similar/\(route.sourceID)/\(f.slug)", width: nil)
                }
            }
            .padding(.horizontal, 16)
        case .images:
            LazyVStack(spacing: 10) {
                ForEach(Array(backdrops.enumerated()), id: \.offset) { _, image in
                    RemoteImage(url: image.url(), maxPoints: 500)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: Actions

    private func play() {
        guard let detail else { return }
        noLink = !Player.start(detail)
    }

    private func load() async {
        failed = false
        async let peopleTask = try? PhimAPI.shared.peoples(slug: route.film.slug)
        async let imagesTask = try? PhimAPI.shared.images(slug: route.film.slug)
        do {
            let d = try await PhimAPI.shared.detail(slug: route.film.slug)
            synopsis = d.content.map(plainText) ?? ""
            withAnimation(reduceMotion ? nil : .cinematic) { detail = d }
        } catch {
            failed = true
        }
        if let genre = (detail?.category ?? route.film.category)?.first?.slug {
            let list = (try? await PhimAPI.shared.list(.genre(genre)).items) ?? []
            similar = list.filter { $0.slug != route.film.slug }
        }
        people = await peopleTask ?? []
        backdrops = (await imagesTask ?? []).filter { $0.type == "backdrop" }
    }
}
