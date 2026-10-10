import DesignSystem
import SwiftUI

/// The hero film's art blurred into a colour wash behind the top of Home; cross-fades with the hero.
struct AmbientBackground: View {
    let url: URL?
    let tint: Color

    var body: some View {
        ZStack(alignment: .top) {
            Color.canvas
            LinearGradient(colors: [tint.opacity(0.35), .clear], startPoint: .top, endPoint: .center)
            RemoteImage(url: url, maxPoints: 120)
                .id(url)
                .transition(.opacity)
                .frame(height: 620)
                .blur(radius: 50)
                .saturation(1.4)
                .opacity(0.75)
                .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))
        }
        .animation(.easeInOut(duration: 0.8), value: url)
        .animation(.easeInOut(duration: 0.8), value: tint)
        .ignoresSafeArea()
    }
}
