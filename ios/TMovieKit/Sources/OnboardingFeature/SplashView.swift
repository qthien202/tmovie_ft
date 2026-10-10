import DesignSystem
import SwiftUI

/// Wordmark intro: letters spring in, then a teal light sweep. Static fade with Reduce Motion.
public struct SplashView: View {
    let done: () -> Void

    public init(done: @escaping () -> Void) { self.done = done }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            HStack(spacing: 2) {
                ForEach(Array("TMOVIE".enumerated()), id: \.offset) { i, ch in
                    Text(String(ch))
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.brand, .brandLight], startPoint: .top, endPoint: .bottom))
                        .keyframeAnimator(initialValue: Letter(), trigger: true) { content, v in
                            content.scaleEffect(v.scale).opacity(v.opacity).offset(y: v.y).blur(radius: v.blur)
                        } keyframes: { _ in
                            let d = reduceMotion ? 0 : Double(i) * 0.07
                            KeyframeTrack(\.opacity) { LinearKeyframe(0, duration: d); LinearKeyframe(1, duration: 0.3) }
                            KeyframeTrack(\.y) { LinearKeyframe(reduceMotion ? 0 : 30, duration: d); SpringKeyframe(0, duration: 0.5, spring: .bouncy) }
                            KeyframeTrack(\.scale) { LinearKeyframe(reduceMotion ? 1 : 0.6, duration: d); SpringKeyframe(1, duration: 0.5, spring: .bouncy) }
                            KeyframeTrack(\.blur) { LinearKeyframe(reduceMotion ? 0 : 8, duration: d); LinearKeyframe(0, duration: 0.35) }
                        }
                }
            }
            .accessibilityLabel("TMovie")
        }
        .task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.6 : 1.4))
            done()
        }
    }

    struct Letter { var scale = 0.6; var opacity = 0.0; var y = 30.0; var blur = 8.0 }
}
