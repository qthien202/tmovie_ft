import SwiftUI

extension View {
    /// Liquid Glass on iOS 26+, `.ultraThinMaterial` before that. `tint` colours the glass.
    @ViewBuilder
    public func glassSurface(in shape: some Shape = .capsule, interactive: Bool = false, tint: Color? = nil) -> some View {
        if #available(iOS 26, *) {
            let glass = Glass.regular.tint(tint?.opacity(0.35))
            glassEffect(interactive ? glass.interactive() : glass, in: shape)
        } else {
            background { shape.fill(.ultraThinMaterial).overlay(shape.fill(tint?.opacity(0.2) ?? .clear)) }
        }
    }
}
