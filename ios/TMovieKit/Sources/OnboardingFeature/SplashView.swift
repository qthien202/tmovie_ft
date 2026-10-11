import DesignSystem
import SwiftUI

/// Wordmark intro: letters spring in one after another, unblurring as they land. Plain fade with Reduce Motion.
public struct SplashView: View {
    let done: () -> Void

    public init(done: @escaping () -> Void) { self.done = done }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    public var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            HStack(spacing: 2) {
                ForEach(Array("TMOVIE".enumerated()), id: \.offset) { i, ch in
                    let landed = shown || reduceMotion
                    Text(String(ch))
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.brand, .brandLight], startPoint: .top, endPoint: .bottom))
                        .scaleEffect(landed ? 1 : 0.6)
                        .offset(y: landed ? 0 : 30)
                        .blur(radius: landed ? 0 : 8)
                        .opacity(shown ? 1 : 0)
                        .animation(reduceMotion ? .easeOut(duration: 0.3) : .bouncy(duration: 0.55).delay(Double(i) * 0.07), value: shown)
                }
            }
            .accessibilityLabel("TMovie")
        }
        .task {
            shown = true
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.6 : 1.4))
            done()
        }
    }
}
