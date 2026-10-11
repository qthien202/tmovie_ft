import DesignSystem
import Models
import Persistence
import FilmUI
import SwiftUI

/// Netflix-style episode rows: still, number, progress. Long series are split into ranges of 50.
struct EpisodeList: View {
    let film: FilmDetail?
    let servers: [Episode]
    let record: WatchRecord?
    let stills: [FilmImage]
    let fallback: URL?
    let play: (Int, [ServerData], Int) -> Void

    @State private var server = 0
    @State private var range = 0
    private let chunk = 50

    private var list: [ServerData] { servers.indices.contains(server) ? servers[server].serverData ?? [] : [] }
    private var ranges: [Range<Int>] {
        stride(from: 0, to: list.count, by: chunk).map { $0..<min($0 + chunk, list.count) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if servers.count > 1 {
                    Menu {
                        Picker("Server", selection: $server) {
                            ForEach(servers.indices, id: \.self) { Text(servers[$0].serverName ?? "Server \($0 + 1)").tag($0) }
                        }
                    } label: { menuLabel(servers[server].serverName ?? "Server \(server + 1)") }
                }
                if ranges.count > 1 {
                    Menu {
                        Picker("Tập", selection: $range) {
                            ForEach(ranges.indices, id: \.self) { Text("Tập \(ranges[$0].lowerBound + 1)–\(ranges[$0].upperBound)").tag($0) }
                        }
                    } label: { menuLabel("Tập \((ranges[safe: range]?.lowerBound ?? 0) + 1)–\(ranges[safe: range]?.upperBound ?? 0)") }
                }
            }
            .padding(.horizontal, 16)

            LazyVStack(spacing: 14) {
                ForEach(ranges[safe: range] ?? 0..<0, id: \.self) { i in
                    row(i)
                }
            }
        }
        .onAppear {
            // Open on the episode last watched.
            if let r = record, servers.indices.contains(r.serverIndex) {
                server = r.serverIndex
                range = r.episodeIndex / chunk
            }
        }
        .onChange(of: server) { range = 0 }
    }

    private func row(_ i: Int) -> some View {
        let ep = list[i]
        let progress = record?.progress(ep.slug ?? "") ?? 0
        let isLast = record?.serverIndex == server && record?.episodeIndex == i
        return HStack(spacing: 4) {
            Button { play(server, list, i) } label: {
            HStack(spacing: 12) {
                RemoteImage(url: stills.isEmpty ? fallback : stills[i % stills.count].url(size: "w300"), maxPoints: 200)
                    .frame(width: 128, height: 72)
                    .overlay {
                        Image(systemName: "play.fill").font(.subheadline)
                            .frame(width: 32, height: 32)
                            .glassSurface(in: .circle)
                    }
                    .overlay(alignment: .bottom) {
                        if progress > 0 { ProgressStrip(progress) }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(ep.name ?? "Tập \(i + 1)").font(.subheadline.weight(.semibold))
                    if isLast { Text("Đang xem").font(.caption.weight(.semibold)).foregroundStyle(Color.brand) }
                }
                Spacer()
            }
            .contentShape(.rect)
            }
            .buttonStyle(PressableStyle())
            if let film, ep.streamURL != nil { DownloadButton(film: film, server: server, index: i) }
        }
        .disabled(ep.streamURL == nil)
        .opacity(ep.streamURL == nil ? 0.4 : 1)
        .padding(.horizontal, 16)
    }

    private func menuLabel(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title).lineLimit(1)
            Image(systemName: "chevron.down").imageScale(.small)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .frame(height: 36)
        .glassSurface(in: .rect(cornerRadius: 8), interactive: true)
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
