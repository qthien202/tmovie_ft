import DesignSystem
import Models
import PlayerFeature
import SwiftUI

/// Download state of one episode: arrow → progress ring → check. Tapping a finished or
/// running download offers to delete it; a failed one retries.
public struct DownloadButton: View {
    let film: FilmDetail
    let server: Int
    let index: Int
    var labeled = false

    @State private var confirmDelete = false

    public init(film: FilmDetail, server: Int, index: Int, labeled: Bool = false) {
        self.film = film
        self.server = server
        self.index = index
        self.labeled = labeled
    }

    private var item: DownloadItem? { Downloads.shared.item(film.slug, server: server, index: index) }

    public var body: some View {
        Button(action: tap) {
            if labeled {
                VStack(spacing: 6) {
                    icon.frame(height: 24)
                    Text(title).font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }
                .frame(minWidth: 64, minHeight: 48)
            } else {
                icon.frame(width: 44, height: 44).contentShape(.rect)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: item?.state == .done)
        .accessibilityLabel(title)
        .confirmationDialog(item?.state == .done ? "Xoá bản đã tải?" : "Huỷ tải xuống?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(item?.state == .done ? "Xoá bản tải" : "Huỷ tải", role: .destructive) {
                if let item { Downloads.shared.remove(item) }
            }
        }
    }

    @ViewBuilder private var icon: some View {
        switch item?.state {
        case nil:
            Image(systemName: "arrow.down.to.line").font(.title3.weight(.semibold))
        case .queued, .downloading:
            ProgressRing(progress: item?.progress ?? 0)
        case .done:
            Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(Color.brandLight)
                .transition(.scale.combined(with: .opacity))
        case .failed:
            Image(systemName: "exclamationmark.arrow.circlepath").font(.title3.weight(.semibold)).foregroundStyle(.orange)
        }
    }

    private var title: String {
        switch item?.state {
        case nil: "Tải xuống"
        case .queued: "Đang chờ"
        case .downloading: "\(Int((item?.progress ?? 0) * 100))%"
        case .done: "Đã tải"
        case .failed: "Thử lại"
        }
    }

    private func tap() {
        switch item?.state {
        case nil: withAnimation(.snappy) { Downloads.shared.enqueue(film, server: server, index: index) }
        case .failed: if let item { Downloads.shared.retry(item) }
        default: confirmDelete = true
        }
    }
}

/// Circular progress with a stop square, like the App Store.
struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.2), lineWidth: 2.5)
            Circle().trim(from: 0, to: max(0.03, progress))
                .stroke(Color.brandLight, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: progress)
            RoundedRectangle(cornerRadius: 1.5).fill(.white).frame(width: 7, height: 7)
        }
        .frame(width: 22, height: 22)
    }
}
