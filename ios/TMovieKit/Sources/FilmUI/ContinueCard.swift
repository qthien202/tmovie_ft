import AppRouter
import DesignSystem
import Models
import Networking
import Persistence
import PlayerFeature
import SwiftUI

/// "Xem tiếp" card, Apple TV Up Next: a large 16:9 still with the episode as a glass chip, a glass play
/// button, progress running along the bottom edge with the time left, and the title underneath.
/// Tapping resumes playback straight away.
public struct ContinueCard: View {
    let record: WatchRecord
    @State private var loading = false

    public init(record: WatchRecord) { self.record = record }

    private var episode: String {
        let name = record.episodeName
        return name.allSatisfy(\.isNumber) && !name.isEmpty ? "Tập \(Int(name) ?? 0)" : name
    }

    /// "Còn 24 phút", from the last episode's saved position.
    private var timeLeft: String? {
        guard let d = record.durations[record.lastEpisodeSlug], d > 0 else { return nil }
        let left = max(1, Int((d - (record.positions[record.lastEpisodeSlug] ?? 0)) / 60))
        return "Còn \(left) phút"
    }

    /// The frame the viewer paused on, else the film's still.
    @ViewBuilder private func still(_ film: FilmItem) -> some View {
        // `updatedAt` changes on every save, so a newer frame is read again.
        if let frame = UIImage(contentsOfFile: ContinueFrame.url(for: film.slug).path(percentEncoded: false)), record.updatedAt > .distantPast {
            Image(uiImage: frame).resizable().scaledToFill()
        } else {
            RemoteImage(url: film.thumbURL, maxPoints: 360)
        }
    }

    public var body: some View {
        if let film = record.film {
            Button {
                Task {
                    loading = true
                    defer { loading = false }
                    if let detail = try? await PhimAPI.shared.detail(slug: film.slug) { Player.start(detail) }
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    still(film)
                        .frame(width: 286, height: 161)
                        .overlay {
                            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .init(x: 0.5, y: 0.5), endPoint: .bottom)
                        }
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .frame(width: 52, height: 52)
                                .glassSurface(in: .circle)
                                .opacity(loading ? 0 : 1)
                                .overlay { if loading { ProgressView() } }
                        }
                        .overlay(alignment: .topLeading) {
                            if !episode.isEmpty {
                                Text(episode)
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 9)
                                    .frame(height: 24)
                                    .glassSurface(in: .capsule)
                                    .padding(10)
                            }
                        }
                        .overlay(alignment: .bottom) {
                            HStack(spacing: 10) {
                                Capsule().fill(.white.opacity(0.3)).frame(height: 4)
                                    .overlay(alignment: .leading) {
                                        GeometryReader { g in Capsule().fill(.white).frame(width: g.size.width * max(0.03, record.lastProgress)) }
                                    }
                                if let timeLeft {
                                    Text(timeLeft).font(.caption2.weight(.semibold)).fixedSize()
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 10)
                        }
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.12)))
                        .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
                    Text(film.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(width: 286, alignment: .leading)
                        .padding(.leading, 2)
                }
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
