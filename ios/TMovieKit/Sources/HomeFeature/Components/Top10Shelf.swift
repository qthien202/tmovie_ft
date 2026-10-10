import AppRouter
import DesignSystem
import FilmUI
import Models
import SwiftUI

/// Netflix "Top 10": huge outlined rank numbers tucked behind each poster.
struct Top10Shelf: View {
    let films: [FilmItem]
    let more: ListRoute

    var body: some View {
        Shelf("Top 10 phim bộ tuần này", more: more, spacing: 4) {
            ForEach(Array(films.enumerated()), id: \.element.id) { i, film in
                HStack(alignment: .bottom, spacing: -22) {
                    Text("\(i + 1)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundStyle(Color.canvas)
                        // Outline: four hard shadows read as a stroke around the dark fill.
                        .shadow(color: .white.opacity(0.85), radius: 0, x: 1.5)
                        .shadow(color: .white.opacity(0.85), radius: 0, x: -1.5)
                        .shadow(color: .white.opacity(0.85), radius: 0, y: 1.5)
                        .shadow(color: .white.opacity(0.85), radius: 0, y: -1.5)
                        .offset(y: 22)
                        .accessibilityHidden(true)
                    PosterCard(film: film, sourceID: "top10/\(film.slug)", width: 104)
                }
            }
        }
    }
}
