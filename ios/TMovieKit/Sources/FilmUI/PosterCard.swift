import AppRouter
import DesignSystem
import Models
import SwiftUI

/// Portrait poster that pushes the film with a zoom transition.
public struct PosterCard: View {
    let film: FilmItem
    let sourceID: String
    let width: CGFloat?

    public init(film: FilmItem, sourceID: String, width: CGFloat? = 112) {
        self.film = film
        self.sourceID = sourceID
        self.width = width
    }

    public var body: some View {
        NavigationLink(value: FilmRoute(film: film, sourceID: sourceID)) {
            RemoteImage(url: film.posterURL, maxPoints: 260)
                .aspectRatio(2 / 3, contentMode: .fit)
                .frame(width: width)
                .overlay(alignment: .topLeading) { badge }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .zoomSource(id: sourceID)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(film.name)
    }

    @ViewBuilder private var badge: some View {
        if let ep = film.episodeCurrent, !ep.isEmpty, ep.lowercased() != "full" {
            Text(ep.replacingOccurrences(of: "Hoàn Tất", with: "Trọn bộ"))
                .font(.system(size: 10, weight: .bold))
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.brand, in: UnevenRoundedRectangle(bottomTrailingRadius: 8, style: .continuous))
                .foregroundStyle(.white)
        }
    }
}
