import DesignSystem
import FilmUI
import Models
import PlayerFeature
import SwiftUI

/// "Đã tải xuống": episodes saved for offline viewing, grouped by film.
struct DownloadsView: View {
    private var downloads: Downloads { .shared }

    private var films: [(slug: String, items: [DownloadItem])] {
        var order: [String] = []
        var groups: [String: [DownloadItem]] = [:]
        for item in downloads.items {
            if groups[item.slug] == nil { order.append(item.slug) }
            groups[item.slug, default: []].append(item)
        }
        return order.map { ($0, groups[$0]!.sorted { ($0.server, $0.index) < ($1.server, $1.index) }) }
    }

    var body: some View {
        List {
            if downloads.items.isEmpty {
                ContentUnavailableView("Chưa có phim nào", systemImage: "arrow.down.circle",
                                       description: Text("Nhấn \(Image(systemName: "arrow.down.to.line")) ở trang phim để xem khi không có mạng."))
                    .listRowBackground(Color.clear)
            }
            ForEach(films, id: \.slug) { group in
                Section {
                    ForEach(group.items) { row($0) }
                        .onDelete { offsets in offsets.map { group.items[$0] }.forEach(downloads.remove) }
                } header: {
                    HStack(spacing: 12) {
                        RemoteImage(url: group.items.first?.posterURL, maxPoints: 80)
                            .frame(width: 36, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        Text(group.items.first?.filmName ?? "").font(.headline).foregroundStyle(.white).textCase(nil)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.canvas)
        .navigationTitle("Đã tải xuống")
        .toolbar {
            if downloads.totalBytes > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(downloads.totalBytes.formatted(.byteCount(style: .file))).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .animation(.snappy, value: downloads.items)
    }

    private func row(_ item: DownloadItem) -> some View {
        Button { play(item) } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.episodeName).font(.subheadline.weight(.semibold))
                    Text(status(item)).font(.caption).foregroundStyle(item.state == .failed ? .orange : .secondary)
                        .contentTransition(.numericText())
                }
                Spacer()
                if item.state == .done {
                    Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(.white)
                } else if item.state == .failed {
                    Button("Thử lại") { downloads.retry(item) }.buttonStyle(.bordered).controlSize(.small)
                } else {
                    ProgressView(value: item.progress).frame(width: 64).tint(.brandLight)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(item.state != .done)
        .listRowBackground(Color.white.opacity(0.06))
    }

    private func status(_ item: DownloadItem) -> String {
        let size = item.bytes.formatted(.byteCount(style: .file))
        return switch item.state {
        case .queued: "Đang chờ"
        case .downloading: "Đang tải \(Int(item.progress * 100))% · \(size)"
        case .done: size
        case .failed: "Tải lỗi"
        }
    }

    private func play(_ item: DownloadItem) {
        guard let film = downloads.film(item.slug) else { return }
        Player.play(film, server: item.server, episodes: film.episodes?[item.server].serverData ?? [], at: item.index)
    }
}
