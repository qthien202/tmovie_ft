import AppRouter
import DesignSystem
import FilmUI
import Models
import Networking
import SwiftUI

/// Wordmark plus category pills, over a fade so content scrolls under it.
struct HomeHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Wordmark().padding(.horizontal, 16)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    pill("Phim bộ", .type("phim-bo"))
                    pill("Phim lẻ", .type("phim-le"))
                    pill("TV Shows", .type("tv-shows"))
                    GenrePickerButton()
                }
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollIndicators(.hidden)
        }
        .padding(.bottom, 10)
        .background {
            LinearGradient(colors: [.black.opacity(0.85), .black.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }

    private func pill(_ title: String, _ source: PhimAPI.Source) -> some View {
        NavigationLink(value: ListRoute(title: title, source: source)) { Text(title).modifier(PillLabel()) }
            .buttonStyle(PressableStyle())
    }
}
