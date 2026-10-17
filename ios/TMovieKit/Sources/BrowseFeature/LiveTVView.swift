import DesignSystem
import Models
import PlayerFeature
import SwiftUI

/// "Truyền hình": iptv-org's channels by country and category (Việt Nam first), plus M3U lists the
/// user adds. Lists play as published; only DASH, which AVPlayer doesn't play, is skipped.
/// Search covers every country.
public struct LiveTVView: View {
    public init() {}

    /// iptv-org's whole index (~11k channels; every country and category in one file).
    static let iptvOrg = URL(string: "https://iptv-org.github.io/iptv/index.m3u")!
    /// Playlists load once per run: the index is 2.5 MB.
    @MainActor static var cache: [URL: [Channel]] = [:]

    /// Lists the user added, one URL per line.
    @AppStorage("liveLists") private var customRaw = ""
    @State private var source = iptvOrg
    @State private var country: String? = "vn"
    @State private var category: String?
    @State private var channels: [Channel]?
    @State private var failed = false
    @State private var query = ""
    @State private var adding = false
    @State private var newURL = ""
    @State private var picking: Picking?

    enum Picking: String, Identifiable { case country, category; var id: Self { self } }

    private var custom: [URL] { customRaw.split(separator: "\n").compactMap { URL(string: String($0)) } }
    private var all: [Channel] { channels ?? [] }
    private var countries: [String: Int] { all.reduce(into: [:]) { if let c = $1.country { $0[c, default: 0] += 1 } } }
    private var categories: [String: Int] { all.reduce(into: [:]) { d, ch in ch.categories.forEach { d[$0, default: 0] += 1 } } }

    private var shown: [Channel] {
        let q = query.trimmingCharacters(in: .whitespaces)
        return all.filter { c in
            (!q.isEmpty || country == nil || c.country == country)  // search covers every country
                && (category == nil || c.categories.contains(category!))
                && (q.isEmpty || c.name.localizedCaseInsensitiveContains(q))
        }
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12, pinnedViews: .sectionHeaders) {
                Section { content } header: { pills }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color.canvas)
        .navigationTitle("Truyền hình")
        .searchable(text: $query, prompt: "Tìm trong \(all.count.formatted()) kênh")
        .toolbar {
            Button { newURL = ""; adding = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("Thêm danh sách kênh")
        }
        .alert("Thêm danh sách kênh", isPresented: $adding) {
            TextField("Link danh sách .m3u", text: $newURL)
                .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
            Button("Thêm") { add() }
            Button("Huỷ", role: .cancel) {}
        }
        .task(id: source) { await load() }
        .sheet(item: $picking) { kind in
            switch kind {
            case .country:
                OptionSheet(
                    title: "Quốc gia", all: "Tất cả quốc gia", selected: country,
                    // Việt Nam first, then by name.
                    options: countries.keys.sorted { ($0 == "vn" ? 0 : 1, Self.countryName($0)) < ($1 == "vn" ? 0 : 1, Self.countryName($1)) }
                        .map { ($0, "\(Self.flag($0)) \(Self.countryName($0))", countries[$0] ?? 0) }
                ) { country = $0 }
            case .category:
                OptionSheet(
                    title: "Thể loại", all: "Tất cả thể loại", selected: category,
                    options: categories.keys.sorted { Self.categoryName($0) < Self.categoryName($1) }
                        .map { ($0, Self.categoryName($0), categories[$0] ?? 0) }
                ) { category = $0 }
            }
        }
    }

    @ViewBuilder private var content: some View {
        if failed {
            message("Không tải được danh sách kênh")
        } else if channels == nil {
            ProgressView().frame(maxWidth: .infinity).padding(32)
        } else if shown.isEmpty {
            message("Không có kênh nào")
        } else {
            Text("\(shown.count.formatted()) kênh").font(.footnote).foregroundStyle(.secondary).padding(.horizontal, 16)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 16) {
                ForEach(shown) { c in
                    Button { Player.live(c) } label: { ChannelTile(channel: c) }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func message(_ text: String) -> some View {
        Text(text).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(32)
    }

    /// Same pills as Home's header.
    private var pills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if !countries.isEmpty {
                    pickerPill(country.map { "\(Self.flag($0)) \(Self.countryName($0))" } ?? "Quốc gia", selected: country != nil) { picking = .country }
                }
                if !categories.isEmpty {
                    pickerPill(category.map(Self.categoryName) ?? "Thể loại", selected: category != nil) { picking = .category }
                }
                if !custom.isEmpty {
                    Button { source = Self.iptvOrg } label: { Text("iptv-org").modifier(PillLabel(selected: source == Self.iptvOrg)) }
                }
                ForEach(custom, id: \.self) { url in
                    Button { source = url; country = nil; category = nil } label: {
                        Text(url.host() ?? url.absoluteString).modifier(PillLabel(selected: source == url))
                    }
                    .contextMenu { Button("Xoá danh sách", systemImage: "trash", role: .destructive) { remove(url) } }
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollIndicators(.hidden)
        .padding(.vertical, 8)
        .background(Color.canvas)
    }

    private func pickerPill(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "chevron.down").font(.caption.weight(.semibold))
            }
            .modifier(PillLabel(selected: selected))
        }
    }

    private func load() async {
        failed = false
        if let hit = Self.cache[source] { channels = hit; return }
        channels = nil
        do {
            let data = try await URLSession.shared.data(from: source).0
            let list = M3U.parse(String(decoding: data, as: UTF8.self)).filter { !$0.url.absoluteString.contains(".mpd") }
            Self.cache[source] = list
            channels = list
        } catch {
            failed = true
        }
    }

    private func add() {
        let text = newURL.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: text), ["http", "https"].contains(url.scheme ?? "") else { return }
        if !custom.contains(url) { customRaw = (custom + [url]).map(\.absoluteString).joined(separator: "\n") }
        source = url
        country = nil
        category = nil
    }

    private func remove(_ url: URL) {
        customRaw = custom.filter { $0 != url }.map(\.absoluteString).joined(separator: "\n")
        Self.cache[url] = nil
        if source == url { source = Self.iptvOrg }
    }

    // MARK: Names

    /// iptv-org writes the UK as "uk".
    private static func iso(_ code: String) -> String { code == "uk" ? "GB" : code.uppercased() }

    static func countryName(_ code: String) -> String {
        Locale(identifier: "vi").localizedString(forRegionCode: iso(code)) ?? iso(code)
    }

    static func flag(_ code: String) -> String {
        String(String.UnicodeScalarView(iso(code).unicodeScalars.compactMap { UnicodeScalar(0x1F1E6 + $0.value - 65) }))
    }

    /// iptv-org's categories, in Vietnamese.
    static func categoryName(_ c: String) -> String {
        [
            "General": "Tổng hợp", "News": "Tin tức", "Entertainment": "Giải trí", "Movies": "Phim", "Series": "Phim bộ",
            "Sports": "Thể thao", "Kids": "Thiếu nhi", "Animation": "Hoạt hình", "Music": "Âm nhạc", "Documentary": "Tài liệu",
            "Education": "Giáo dục", "Comedy": "Hài", "Culture": "Văn hoá", "Lifestyle": "Đời sống", "Classic": "Kinh điển",
            "Family": "Gia đình", "Travel": "Du lịch", "Cooking": "Ẩm thực", "Outdoor": "Ngoài trời", "Science": "Khoa học",
            "Business": "Kinh doanh", "Auto": "Ô tô", "Weather": "Thời tiết", "Relax": "Thư giãn", "Shop": "Mua sắm",
            "Religious": "Tôn giáo", "Legislative": "Nghị viện", "Public": "Công cộng", "Interactive": "Tương tác",
        ][c] ?? c
    }
}

/// A list of choices with channel counts; nil is "all".
private struct OptionSheet: View {
    let title: String
    let all: String
    let selected: String?
    let options: [(key: String, label: String, count: Int)]
    let pick: (String?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                row(nil, all, nil)
                ForEach(options, id: \.key) { row($0.key, $0.label, $0.count) }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Xong") { dismiss() } }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ key: String?, _ label: String, _ count: Int?) -> some View {
        Button { pick(key); dismiss() } label: {
            HStack {
                Text(label).foregroundStyle(.primary)
                Spacer()
                if let count { Text(count.formatted()).foregroundStyle(.secondary) }
                if key == selected { Image(systemName: "checkmark").foregroundStyle(Color.brand) }
            }
        }
    }
}

private struct ChannelTile: View {
    let channel: Channel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.06))
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay {
                    if let logo = channel.logo {
                        RemoteImage(url: logo, maxPoints: 200, fit: true).padding(12)
                    } else {
                        Text(channel.name.prefix(2).uppercased()).font(.title3.bold()).foregroundStyle(.white)
                    }
                }
            Text(channel.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2, reservesSpace: true)
        }
        .contentShape(.rect)
    }
}
