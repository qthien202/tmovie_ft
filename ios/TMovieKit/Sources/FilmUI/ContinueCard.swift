import AppRouter
import DesignSystem
import Networking
import Persistence
import PlayerFeature
import SwiftUI

/// "Xem tiếp" card: landscape still with progress; tapping resumes playback straight away.
public struct ContinueCard: View {
    let record: WatchRecord
    @State private var loading = false

    public init(record: WatchRecord) { self.record = record }

    public var body: some View {
        if let film = record.film {
            Button {
                Task {
                    loading = true
                    defer { loading = false }
                    if let detail = try? await PhimAPI.shared.detail(slug: film.slug) { Player.start(detail) }
                }
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    RemoteImage(url: film.thumbURL, maxPoints: 260)
                        .frame(width: 210, height: 118)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .glassSurface(in: .circle)
                                .opacity(loading ? 0 : 1)
                                .overlay { if loading { ProgressView() } }
                        }
                        .overlay(alignment: .bottom) { ProgressStrip(max(0.03, record.lastProgress)) }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(film.name).font(.footnote.weight(.semibold)).lineLimit(1)
                        Text(record.episodeName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(width: 210, alignment: .leading)
                    .background(Color.white.opacity(0.08))
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Tiếp tục xem \(film.name), \(record.episodeName)")
            .contextMenu {
                NavigationLink(value: FilmRoute(film: film, sourceID: "continue/\(film.slug)")) {
                    Label("Thông tin phim", systemImage: "info.circle")
                }
                Button("Xoá khỏi Xem tiếp", systemImage: "xmark", role: .destructive) { Library.remove(record) }
            }
        }
    }
}
