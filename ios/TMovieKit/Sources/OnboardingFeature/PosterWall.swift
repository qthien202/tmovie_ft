import DesignSystem
import Models
import SwiftUI

/// Tilted grid of posters drifting upward forever.
struct PosterWall: View {
    let films: [FilmItem]
    let animate: Bool
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let w = (geo.size.width + 120) / 4
            HStack(alignment: .top, spacing: 10) {
                ForEach(0..<4, id: \.self) { col in
                    VStack(spacing: 10) {
                        ForEach(Array(column(col).enumerated()), id: \.offset) { _, film in
                            RemoteImage(url: film.posterURL, maxPoints: 160)
                                .frame(width: w, height: w * 1.5)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .offset(y: (col.isMultiple(of: 2) ? -40 : -120) + (drift ? -260 : 0))
                }
            }
            .rotationEffect(.degrees(-12))
            .offset(x: -60, y: -40)
            .animation(animate ? .linear(duration: 40).repeatForever(autoreverses: true) : nil, value: drift)
            .onAppear { drift = true }
        }
        .opacity(films.isEmpty ? 0 : 1)
        .animation(.easeOut(duration: 0.8), value: films.isEmpty)
    }

    private func column(_ c: Int) -> [FilmItem] {
        let all = films + films
        return stride(from: c, to: all.count, by: 4).map { all[$0] }
    }
}
