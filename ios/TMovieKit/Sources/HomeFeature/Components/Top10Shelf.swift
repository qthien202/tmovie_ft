import AppRouter
import DesignSystem
import FilmUI
import Models
import SwiftUI

/// "Top 10" as a deck of cards fanned across the width, the rank printed on each poster. Swiping
/// left pulls the top card out and tucks it under the deck; swiping right pulls the bottom one back
/// on top. Endless: after 10 comes 1. Tapping the top card opens the film, a card behind brings it up.
struct Top10Shelf: View {
    let films: [FilmItem]
    let more: ListRoute

    @State private var top = 0
    /// The card on its way out (or back in), drawn at the side for the first half of the move.
    @State private var moving: Int?
    @State private var movingOnTop = true
    @State private var drag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cardWidth: CGFloat = 162
    private var n: Int { films.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RailHeader(title: "Top 10 phim bộ tuần này", more: more)
            ZStack(alignment: .topLeading) {
                ForEach(Array(films.enumerated()), id: \.element.id) { i, film in
                    card(film, rank: i + 1, depth: (i - top + n) % n, index: i)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 262, alignment: .top)
            .clipped()
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { drag = $0.translation.width }
                    .onEnded { value in
                        drag = 0
                        if value.translation.width < -40 { step(1) } else if value.translation.width > 40 { step(-1) }
                    }
            )
            .sensoryFeedback(.selection, trigger: top)
        }
    }

    @ViewBuilder
    private func card(_ film: FilmItem, rank: Int, depth k: Int, index: Int) -> some View {
        let route = FilmRoute(film: film, sourceID: "top10/\(film.slug)")
        let v = CGFloat(min(k, 4))
        let isMoving = moving == index
        let face = poster(film, rank: rank, dim: Double(min(0.5, v * 0.13)))
        Group {
            if k == 0 && !isMoving {
                NavigationLink(value: route) { face.zoomSource(id: route.sourceID) }.buttonStyle(PressableStyle())
            } else {
                Button { bring(index) } label: { face }.buttonStyle(.plain)
            }
        }
        .accessibilityLabel("Hạng \(rank): \(film.name)")
        .scaleEffect(isMoving ? 0.96 : 1 - v * 0.075, anchor: .bottomLeading)
        .rotationEffect(.degrees(isMoving ? -12 : 0), anchor: .bottomLeading)
        .offset(x: isMoving ? -150 : 18 + v * 64 + (k == 0 ? drag * 0.6 : 0), y: isMoving ? -6 : v * 7)
        .opacity(k > 4 && !isMoving ? 0 : 1)
        .zIndex(isMoving ? (movingOnTop ? 40 : -1) : Double(20 - k))
        .allowsHitTesting(k <= 4)
    }

    private func poster(_ film: FilmItem, rank: Int, dim: Double) -> some View {
        RemoteImage(url: film.posterURL, maxPoints: 320)
            .frame(width: cardWidth, height: cardWidth * 1.5)
            .overlay(LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .init(x: 0.5, y: 0.55), endPoint: .bottom))
            .overlay(alignment: .bottomLeading) {
                Text("\(rank)")
                    .font(.system(size: 64, weight: .black))
                    .tracking(-3)
                    .foregroundStyle(medal(rank))
                    .shadow(color: .black.opacity(0.6), radius: 10, y: 3)
                    .padding(.leading, 10)
                    .offset(y: 8)
            }
            .overlay(alignment: .topLeading) { episodeBadge(film) }
            .overlay(Color.black.opacity(dim))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.16)))
            .shadow(color: .black.opacity(0.55), radius: 15, x: -10, y: 14)
    }

    private func medal(_ rank: Int) -> AnyShapeStyle {
        let colors: [Color]? = switch rank {
        case 1: [Color(red: 1, green: 0.95, blue: 0.8), Color(red: 0.94, green: 0.72, blue: 0.3)]
        case 2: [.white, Color(red: 0.73, green: 0.76, blue: 0.8)]
        case 3: [Color(red: 1, green: 0.88, blue: 0.75), Color(red: 0.82, green: 0.54, blue: 0.3)]
        default: nil
        }
        return colors.map { AnyShapeStyle(LinearGradient(colors: $0, startPoint: .top, endPoint: .bottom)) } ?? AnyShapeStyle(.white)
    }

    @ViewBuilder private func episodeBadge(_ film: FilmItem) -> some View {
        if let ep = film.episodeCurrent, !ep.isEmpty, ep.lowercased() != "full" {
            Text(ep.replacingOccurrences(of: "Hoàn Tất", with: "Trọn bộ"))
                .font(.system(size: 10, weight: .bold))
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.brand, in: UnevenRoundedRectangle(bottomTrailingRadius: 9, style: .continuous))
                .foregroundStyle(.white)
        }
    }

    /// One card forward (1) or back (-1), wrapping around.
    private func step(_ dir: Int) {
        guard n > 1, moving == nil else { return }
        let next = (top + dir + n) % n
        if reduceMotion { top = next; return }
        // Forward: the top card slides out on top, then tucks under. Back: the bottom card slides out
        // from under the deck, then lands on top.
        let card = dir > 0 ? top : next
        movingOnTop = dir > 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { moving = card; top = next }
        Task {
            try? await Task.sleep(for: .milliseconds(260))
            movingOnTop.toggle()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { moving = nil }
        }
    }

    private func bring(_ index: Int) {
        guard moving == nil, index != top else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { top = index }
    }
}
