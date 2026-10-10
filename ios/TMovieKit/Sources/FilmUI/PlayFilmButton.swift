import DesignSystem
import Models
import Networking
import Persistence
import PlayerFeature
import SwiftData
import SwiftUI

/// "Phát" / "Tiếp tục" from anywhere a film shows: fetches the detail, then starts or resumes playback.
public struct PlayFilmButton: View {
    let film: FilmItem
    let capsule: Bool
    @State private var loading = false
    @State private var noLink = false
    @Query private var records: [WatchRecord]

    /// `capsule`: Apple TV hero style; otherwise a full-width bar.
    public init(film: FilmItem, capsule: Bool = false) {
        self.film = film
        self.capsule = capsule
        let slug = film.slug
        _records = Query(filter: #Predicate<WatchRecord> { $0.slug == slug })
    }

    public var body: some View {
        Button {
            Task {
                loading = true
                defer { loading = false }
                guard let detail = try? await PhimAPI.shared.detail(slug: film.slug) else { noLink = true; return }
                noLink = !Player.start(detail)
            }
        } label: {
            Group {
                if capsule { PlayCapsuleLabel(records.isEmpty ? "Xem ngay" : "Xem tiếp") } else { PlayWideLabel(records.isEmpty ? "Phát" : "Tiếp tục") }
            }
            .overlay { if loading { ProgressView().tint(.black) } }
        }
        .buttonStyle(PressableStyle())
        .disabled(loading)
        .alert("Phim này chưa có link phát", isPresented: $noLink) {}
    }
}
