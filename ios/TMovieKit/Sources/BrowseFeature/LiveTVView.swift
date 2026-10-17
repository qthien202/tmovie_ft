import AVKit
import DesignSystem
import Models
import PlayerFeature
import SwiftUI

/// "Truyền hình": free-to-air channels from iptv-org's public playlists, plus M3U lists the user adds.
public struct LiveTVView: View {
    public init() {}

    struct Playlist: Hashable {
        let title: String
        let url: URL
        var custom = false

        /// Restreams of paid services (FPT Play, SCTV's DRM feed) and re-hosting sites: never in our lists.
        static let unlicensed = ["fptplay.net", "sctvdrm", "dethich.pw", "freem3u.xyz", "vietanhtv"]

        /// Our lists keep the broadcasters' own free streams; a list the user adds plays as it is.
        func keep(_ c: Channel) -> Bool {
            let u = c.url.absoluteString
            if u.contains(".mpd") { return false }  // DASH: AVPlayer plays HLS only
            return custom || (!Self.unlicensed.contains { u.contains($0) } && !(c.geoBlocked && title != "Việt Nam"))
        }
    }

    static let builtIn = [
        Playlist(title: "Việt Nam", url: URL(string: "https://iptv-org.github.io/iptv/countries/vn.m3u")!),
        Playlist(title: "Phim", url: URL(string: "https://iptv-org.github.io/iptv/categories/movies.m3u")!),
        Playlist(title: "Thể thao", url: URL(string: "https://iptv-org.github.io/iptv/categories/sports.m3u")!),
        Playlist(title: "Giải trí", url: URL(string: "https://iptv-org.github.io/iptv/categories/entertainment.m3u")!),
        Playlist(title: "Thiếu nhi", url: URL(string: "https://iptv-org.github.io/iptv/categories/kids.m3u")!),
        Playlist(title: "Tài liệu", url: URL(string: "https://iptv-org.github.io/iptv/categories/documentary.m3u")!),
        Playlist(title: "Âm nhạc", url: URL(string: "https://iptv-org.github.io/iptv/categories/music.m3u")!),
        Playlist(title: "Tin tức", url: URL(string: "https://iptv-org.github.io/iptv/categories/news.m3u")!),
    ]

    /// Lists the user added, one URL per line.
    @AppStorage("liveLists") private var customRaw = ""
    @State private var selected = builtIn[0].url
    @State private var loaded: [URL: [Channel]] = [:]
    @State private var failed: Set<URL> = []
    @State private var query = ""
    @State private var adding = false
    @State private var newURL = ""
    @State private var playing: Channel?
    @Namespace private var pill

    private var custom: [URL] { customRaw.split(separator: "\n").compactMap { URL(string: String($0)) } }
    private var lists: [Playlist] { Self.builtIn + custom.map { Playlist(title: $0.host() ?? $0.absoluteString, url: $0, custom: true) } }
    private var playlist: Playlist { lists.first { $0.url == selected } ?? Self.builtIn[0] }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                Section { content } header: { pills }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color.canvas)
        .navigationTitle("Truyền hình")
        .searchable(text: $query, prompt: "Tìm kênh")
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
        .task(id: selected) { await load(playlist) }
        .fullScreenCover(item: $playing) { LivePlayer(channel: $0) }
    }

    @ViewBuilder private var content: some View {
        if let channels = loaded[playlist.url] {
            let q = query.trimmingCharacters(in: .whitespaces)
            let shown = q.isEmpty ? channels : channels.filter { $0.name.localizedCaseInsensitiveContains(q) }
            if shown.isEmpty {
                message("Không có kênh nào")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 16) {
                    ForEach(shown) { c in
                        Button { playing = c } label: { ChannelTile(channel: c) }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        } else if failed.contains(playlist.url) {
            message("Không tải được danh sách kênh")
        } else {
            ProgressView().padding(32)
        }
    }

    private func message(_ text: String) -> some View {
        Text(text).foregroundStyle(.secondary).padding(32)
    }

    private var pills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(lists, id: \.url) { p in
                    Button { withAnimation(.snappy) { selected = p.url } } label: {
                        Text(p.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(p.url == playlist.url ? .black : .white)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background {
                                if p.url == playlist.url { Capsule().fill(.white).matchedGeometryEffect(id: "pill", in: pill) }
                            }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if p.custom { Button("Xoá danh sách", systemImage: "trash", role: .destructive) { remove(p.url) } }
                    }
                }
            }
            .padding(4)
            .glassSurface()
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollIndicators(.hidden)
        .padding(.vertical, 8)
        .background(Color.canvas)
    }

    private func load(_ p: Playlist) async {
        guard loaded[p.url] == nil else { return }
        failed.remove(p.url)
        do {
            let data = try await URLSession.shared.data(from: p.url).0
            loaded[p.url] = M3U.parse(String(decoding: data, as: UTF8.self)).filter(p.keep)
        } catch {
            failed.insert(p.url)
        }
    }

    private func add() {
        let text = newURL.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: text), ["http", "https"].contains(url.scheme ?? "") else { return }
        if !custom.contains(url) { customRaw = (custom + [url]).map(\.absoluteString).joined(separator: "\n") }
        selected = url
    }

    private func remove(_ url: URL) {
        customRaw = custom.filter { $0 != url }.map(\.absoluteString).joined(separator: "\n")
        loaded[url] = nil
        if selected == url { selected = Self.builtIn[0].url }
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

/// A channel full screen in AVKit's player, in landscape. Some playlists need their own User-Agent / Referer.
private struct LivePlayer: View {
    let channel: Channel
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let player { AVPlayerControllerView(player: player).ignoresSafeArea() }
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.headline).foregroundStyle(.white).frame(width: 44, height: 44)
            }
            .glassSurface(in: .circle, interactive: true)
            .padding()
            .accessibilityLabel("Đóng")
        }
        .onAppear {
            var headers: [String: String] = [:]
            if let ua = channel.userAgent { headers["User-Agent"] = ua }
            if let ref = channel.referrer { headers["Referer"] = ref }
            let asset = AVURLAsset(url: channel.url, options: headers.isEmpty ? nil : ["AVURLAssetHTTPHeaderFieldsKey": headers])
            let p = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            p.play()
            player = p
            OrientationLock.rotate(to: .landscape)
        }
        .onDisappear {
            player?.pause()
            OrientationLock.rotate(to: .portrait)
        }
    }
}

private struct AVPlayerControllerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {}
}
