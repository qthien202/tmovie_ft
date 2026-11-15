import AppRouter
import DesignSystem
import FilmUI
import Models
import Networking
import SwiftUI

/// "Khám phá": finding something to watch rather than browsing lists. Hot titles as stories,
/// moods, a shuffle that picks a film, the Mới & Hot feed, and themed collections.
public struct ExploreView: View {
    public init() {}

    struct Mood: Identifiable {
        let emoji: String, title: String, source: PhimAPI.Source, colors: [Color]
        var id: String { title }
    }

    static let moods: [Mood] = [
        Mood(emoji: "😱", title: "Hồi hộp", source: .genre("kinh-di"), colors: [hex(0x3A1C71), hex(0xD76D77)]),
        Mood(emoji: "💕", title: "Lãng mạn", source: .genre("tinh-cam"), colors: [hex(0xFF8FB1), hex(0x9D5CFF)]),
        Mood(emoji: "😂", title: "Cười xả láng", source: .genre("hai-huoc"), colors: [hex(0xF7971E), hex(0xFFD200)]),
        Mood(emoji: "🍿", title: "Cày một đêm", source: .type("phim-le"), colors: [hex(0x1D976C), hex(0x93F9B9)]),
        Mood(emoji: "📺", title: "Cày dài kỳ", source: .type("phim-bo"), colors: [hex(0x2B5876), hex(0x4E4376)]),
        Mood(emoji: "👨‍👩‍👧", title: "Cả nhà cùng xem", source: .type("hoat-hinh"), colors: [hex(0x3D8BFF), hex(0x5BE0FF)]),
        Mood(emoji: "🤯", title: "Mind-blowing", source: .genre("vien-tuong"), colors: [hex(0x0F2027), hex(0x2C7A8C)]),
        Mood(emoji: "⚔️", title: "Cổ trang", source: .genre("co-trang"), colors: [hex(0xC79A3A), hex(0x8A3A1F)]),
    ]

    static let collections: [(title: String, subtitle: String, source: PhimAPI.Source, colors: [Color])] = [
        ("Hàn Quốc đang gây sốt", "Những bộ ai cũng bàn tuần này", .country("han-quoc"), [hex(0xFF5F6D), hex(0x7B2FF7)]),
        ("Cày một lèo", "Phim bộ đã trọn, khỏi chờ tập", .type("phim-bo"), [hex(0x1D976C), hex(0x2B5876)]),
        ("Kinh dị nửa đêm", "Tắt đèn rồi hãy bấm", .genre("kinh-di"), [hex(0x200122), hex(0x6F0000)]),
        ("Hoạt hình cả nhà", "Cuối tuần cho bé và bố mẹ", .type("hoat-hinh"), [hex(0x3D8BFF), hex(0x5B8CFF)]),
    ]

    @State private var hot: [FilmItem] = []
    @State private var mood = 0
    @State private var moodFilms: [Int: [FilmItem]] = [:]
    @State private var collectionFilms: [String: [FilmItem]] = [:]
    @State private var feed = NewHotView.Feed.upcoming
    @State private var pagers = Dictionary(uniqueKeysWithValues: NewHotView.Feed.allCases.map { ($0, $0.makePager()) })
    @Namespace private var pill

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                stories
                moodsSection
                ShuffleCard(pool: hot)
                feedSection
                collectionsSection
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Color.canvas)
        .navigationTitle("Khám phá")
        .task {
            if hot.isEmpty, let list = await HotList.fetch() { hot = list.films + list.series.filter { s in !list.films.contains { $0.slug == s.slug } } }
        }
        .task { await loadMoods() }
        .task { await loadCollections() }
        .task(id: feed) { if pagers[feed]!.items.isEmpty { await pagers[feed]!.loadMore() } }
    }

    // MARK: Sections

    private var stories: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                ForEach(Array(hot.prefix(12).enumerated()), id: \.element.id) { i, film in
                    NavigationLink(value: FilmRoute(film: film, sourceID: "story/\(film.slug)")) {
                        VStack(spacing: 6) {
                            RemoteImage(url: film.posterURL, maxPoints: 160)
                                .frame(width: 62, height: 62)
                                .clipShape(.circle)
                                .padding(3)
                                .background(Circle().fill(Color.canvas))
                                .padding(3)
                                .background(Circle().fill(AngularGradient(colors: [.brand, hex(0x9D8CFF), hex(0xFF8FB1), hex(0xFFD36E), .brand], center: .center)))
                                .zoomSource(id: "story/\(film.slug)")
                            Text((i < 3 ? "🔥 " : "") + shortName(film.name))
                                .font(.caption2).foregroundStyle(.secondary).lineLimit(1).frame(width: 74)
                        }
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollIndicators(.hidden)
    }

    private var moodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hôm nay bạn muốn xem gì?").font(.title3.bold()).padding(.horizontal, 16)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(Array(Self.moods.enumerated()), id: \.element.id) { i, m in
                        Button { withAnimation(.snappy) { mood = i } } label: { MoodCard(mood: m, posters: moodFilms[i] ?? [], selected: mood == i) }
                            .buttonStyle(PressableStyle())
                    }
                }
                .padding(.vertical, 4)
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollIndicators(.hidden)
            let m = Self.moods[mood]
            Shelf("\(m.emoji) \(m.title)", more: ListRoute(title: m.title, source: m.source)) {
                ForEach(moodFilms[mood] ?? []) { PosterCard(film: $0, sourceID: "mood/\($0.slug)") }
            }
            .id(mood)
            .padding(.top, 6)
        }
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mới & Hot").font(.title3.bold()).padding(.horizontal, 16)
            HStack(spacing: 0) {
                ForEach(NewHotView.Feed.allCases) { f in
                    Button { withAnimation(.snappy) { feed = f } } label: {
                        Text(f.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(feed == f ? .black : .white)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background { if feed == f { Capsule().fill(.white).matchedGeometryEffect(id: "pill", in: pill) } }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .glassSurface()
            .padding(.horizontal, 16)
            ForEach(pagers[feed]!.items.prefix(5)) { FeedCard(film: $0) }
            if pagers[feed]!.items.isEmpty { ProgressView().frame(maxWidth: .infinity, minHeight: 120) }
        }
    }

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bộ sưu tập").font(.title3.bold()).padding(.horizontal, 16)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Self.collections, id: \.title) { c in
                    NavigationLink(value: ListRoute(title: c.title, source: c.source)) {
                        CollectionCard(title: c.title, subtitle: c.subtitle, colors: c.colors, posters: collectionFilms[c.title] ?? [])
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: Data

    private func loadMoods() async {
        await withTaskGroup(of: (Int, [FilmItem]).self) { group in
            for (i, m) in Self.moods.enumerated() {
                group.addTask { (i, (try? await PhimAPI.shared.list(m.source).items) ?? []) }
            }
            for await (i, films) in group { moodFilms[i] = films }
        }
    }

    private func loadCollections() async {
        await withTaskGroup(of: (String, [FilmItem]).self) { group in
            for c in Self.collections {
                group.addTask { (c.title, Array(((try? await PhimAPI.shared.list(c.source).items) ?? []).dropFirst().prefix(3))) }
            }
            for await (title, films) in group { collectionFilms[title] = films }
        }
    }
}

/// "Việc Ma, Lương Quái: Phần 2" → "Việc Ma, Lương Quái".
private func shortName(_ name: String) -> String {
    String(name.split(whereSeparator: { ":/(".contains($0) }).first ?? Substring(name)).trimmingCharacters(in: .whitespaces)
}

func hex(_ v: UInt32) -> Color {
    Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
}

/// Three posters fanned like cards.
private struct Fan: View {
    let posters: [FilmItem]
    let width: CGFloat

    var body: some View {
        ZStack {
            ForEach(Array(posters.prefix(3).enumerated()), id: \.element.id) { i, f in
                RemoteImage(url: f.posterURL, maxPoints: 160)
                    .frame(width: width, height: width * 1.48)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 6)
                    .rotationEffect(.degrees([-14, 0, 14][i]), anchor: .bottom)
                    .offset(x: [-width * 0.55, 0, width * 0.55][i], y: i == 1 ? -2 : 10)
                    .zIndex(i == 1 ? 1 : 0)
            }
        }
    }
}

private struct MoodCard: View {
    let mood: ExploreView.Mood
    let posters: [FilmItem]
    let selected: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: mood.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Fan(posters: posters, width: 62).frame(maxHeight: .infinity, alignment: .top).padding(.top, 14)
            HStack(spacing: 8) {
                Text(mood.emoji).font(.title3)
                Text(mood.title).font(.subheadline.weight(.bold)).foregroundStyle(.white).lineLimit(2).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .glassSurface(in: .rect(cornerRadius: 18))
            .padding(8)
        }
        .frame(width: 150, height: 178)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(selected ? .white : .white.opacity(0.18), lineWidth: selected ? 2.5 : 1))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
        .offset(y: selected ? -3 : 0)
    }
}

private struct CollectionCard: View {
    let title: String, subtitle: String, colors: [Color], posters: [FilmItem]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Fan(posters: posters, width: 60).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 12)
            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.heavy)).foregroundStyle(.white).lineLimit(2).multilineTextAlignment(.leading)
                Text(subtitle).font(.caption2).foregroundStyle(.white.opacity(0.8)).lineLimit(2).multilineTextAlignment(.leading)
            }
            .padding(12)
        }
        .frame(height: 236)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.white.opacity(0.16)))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
    }
}

/// "Để TMovie chọn giúp": posters spin past like a slot machine and stop on one hot title.
private struct ShuffleCard: View {
    let pool: [FilmItem]
    @State private var shown: FilmItem?
    @State private var picked: FilmItem?
    @State private var spinning = false

    var body: some View {
        HStack(spacing: 16) {
            RemoteImage(url: (shown ?? pool.first)?.posterURL, maxPoints: 260)
                .frame(width: 124, height: 186)
                .blur(radius: spinning ? 1.5 : 0)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.2)))
                .shadow(color: .black.opacity(0.45), radius: 12, y: 8)
                .id(shown?.slug)
                .transition(.push(from: .bottom))
            VStack(alignment: .leading, spacing: 6) {
                Text(picked == nil ? "Không biết xem gì?" : "TMovie chọn cho bạn")
                    .font(.caption.weight(.bold)).textCase(.uppercase).foregroundStyle(Color.brandLight)
                Text(picked?.name ?? "Để TMovie chọn giúp").font(.title3.weight(.heavy)).lineLimit(3)
                Text(picked.map { [$0.year.map(String.init), $0.country?.first?.name, $0.episodeCurrent].compactMap { $0 }.joined(separator: " · ") } ?? "Lắc một cái, ra một phim đang hot.")
                    .font(.footnote).foregroundStyle(.secondary).lineLimit(2)
                HStack(spacing: 8) {
                    if let picked {
                        PlayFilmButton(film: picked, capsule: true)
                    }
                    Button(action: spin) {
                        Text(picked == nil ? "🎲 Chọn giúp tôi" : "🎲 Chọn lại")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(picked == nil ? .black : .white)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background { if picked == nil { Capsule().fill(.white) } }
                            .glassSurface(interactive: true)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(spinning || pool.isEmpty)
                }
                .padding(.top, 6)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Color.brand.opacity(0.28), hex(0x9D8CFF).opacity(0.22), hex(0xFF8FB1).opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .glassSurface(in: .rect(cornerRadius: 30))
        .padding(.horizontal, 16)
        .sensoryFeedback(.selection, trigger: shown?.slug)
        .sensoryFeedback(.success, trigger: picked?.slug)
    }

    /// Fast at first, slowing down, then lands on a random pick.
    private func spin() {
        guard !pool.isEmpty else { return }
        spinning = true
        picked = nil
        let target = pool.randomElement()!
        Task {
            for step in 0..<16 {
                withAnimation(.easeOut(duration: 0.12)) { shown = pool.randomElement() }
                try? await Task.sleep(for: .milliseconds(60 + step * step * 2))
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { shown = target; picked = target; spinning = false }
        }
    }
}
