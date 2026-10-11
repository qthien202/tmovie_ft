import SwiftUI

public extension View {
    /// A soft light sweeping across a loading placeholder.
    func shimmering() -> some View { modifier(Shimmer()) }

    /// Rail items shrink and dim toward the edges of a horizontal scroll.
    func railItemMotion() -> some View { modifier(RailItemMotion()) }

    /// Grid items rise in as they scroll up from the bottom edge.
    func gridItemMotion() -> some View { modifier(GridItemMotion()) }
}

private struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if !reduceMotion {
                GeometryReader { geo in
                    LinearGradient(colors: [.clear, .white.opacity(0.09), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: geo.size.width * 0.6)
                        .offset(x: phase * geo.size.width)
                }
                .clipped()
                .allowsHitTesting(false)
                .onAppear { withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { phase = 1 } }
            }
        }
    }
}

private struct RailItemMotion: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.scrollTransition(.interactive, axis: .horizontal) { [reduceMotion] view, phase in
            let still = reduceMotion || phase.isIdentity
            return view.scaleEffect(still ? 1 : 0.94).opacity(still ? 1 : 0.6)
        }
    }
}

private struct GridItemMotion: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.scrollTransition(.animated(.cinematic)) { [reduceMotion] view, phase in
            // Only the bottom edge: items leaving under the nav bar stay put.
            let entering = !reduceMotion && phase == .bottomTrailing
            return view.opacity(entering ? 0 : 1).scaleEffect(entering ? 0.92 : 1).offset(y: entering ? 24 : 0)
        }
    }
}
