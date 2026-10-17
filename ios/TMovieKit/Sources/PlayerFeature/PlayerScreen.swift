import AVFoundation
import AVKit
import DesignSystem
import Models
import SwiftUI

/// Full-screen custom player: video, gestures, controls, panels.
struct PlayerScreen: View {
    @State var model: PlayerModel
    var close: () -> Void

    @State private var hud: Hud?
    @State private var tapSeek: TapSeek?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Hud: Equatable {
        case seek(target: Double, delta: Double)
        case brightness(Double)
        case volume(Double)
    }

    struct TapSeek: Equatable {
        let forward: Bool
        let seconds: Int
        let id = UUID()
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VideoSurface(model: model)
                .ignoresSafeArea()
                .overlay { gestureLayer }

            PlayerControls(model: model, close: close)

            tapSeekBubble
            hudView
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : .snappy, value: model.controlsVisible)
        .animation(reduceMotion ? nil : .snappy, value: model.panel)
    }

    // MARK: Gestures

    private var gestureLayer: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(.rect)
                .gesture(
                    SpatialTapGesture(count: 2).onEnded { tap in
                        guard !model.locked, model.panel == .none else { return }
                        doubleTap(forward: tap.location.x > geo.size.width / 2)
                    }
                    .exclusively(before: SpatialTapGesture(count: 1).onEnded { _ in
                        if model.panel != .none { model.panel = .none }
                        else if model.controlsVisible { model.controlsVisible = false }
                        else { model.interact() }
                    })
                )
                .simultaneousGesture(drag(in: geo.size), including: model.locked ? .none : .all)
                .simultaneousGesture(
                    MagnifyGesture().onEnded { value in
                        guard !model.locked else { return }
                        if value.magnification > 1.15 { model.fill = true } else if value.magnification < 0.87 { model.fill = false }
                    },
                    including: model.locked ? .none : .all
                )
        }
    }

    @State private var dragMode = 0  // 0 undecided, 1 seek, 2 brightness, 3 volume
    @State private var dragStart: Double = 0

    private func drag(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if dragMode == 0 {
                    if abs(value.translation.width) > abs(value.translation.height) {
                        // Live TV doesn't seek: a sideways swipe does nothing.
                        dragMode = model.isLive ? 4 : 1
                        dragStart = model.position
                    } else {
                        dragMode = value.startLocation.x < size.width / 2 ? 2 : 3
                        dragStart = dragMode == 2 ? Double(model.brightness) : Double(model.volume)
                    }
                    // The HUD takes the screen; the controls would sit under it.
                    model.controlsVisible = false
                }
                switch dragMode {
                case 1:
                    // A full-width swipe covers 90 s.
                    let delta = value.translation.width / size.width * 90
                    let target = min(max(0, dragStart + delta), model.duration)
                    hud = .seek(target: target, delta: target - dragStart)
                case 2:
                    let level = min(1, max(0, dragStart - value.translation.height / (size.height * 0.8)))
                    model.brightness = level
                    hud = .brightness(level)
                case 3:
                    let level = min(1, max(0, dragStart - value.translation.height / (size.height * 0.8)))
                    model.volume = Float(level)
                    hud = .volume(level)
                default: break
                }
            }
            .onEnded { _ in
                if case .seek(let target, _) = hud { model.seek(to: target) }
                dragMode = 0
                withAnimation(.easeOut(duration: 0.3)) { hud = nil }
            }
    }

    private func doubleTap(forward: Bool) {
        guard !model.isLive else { return }
        let seconds = (tapSeek?.forward == forward ? tapSeek?.seconds ?? 0 : 0) + 10
        model.seek(by: forward ? 10 : -10)
        let tap = TapSeek(forward: forward, seconds: seconds)
        withAnimation(.snappy) { tapSeek = tap }
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            if tapSeek?.id == tap.id { withAnimation(.easeOut) { tapSeek = nil } }
        }
    }

    // MARK: Overlays

    @ViewBuilder private var tapSeekBubble: some View {
        if let tap = tapSeek {
            HStack {
                if tap.forward { Spacer() }
                VStack(spacing: 6) {
                    Image(systemName: tap.forward ? "goforward.10" : "gobackward.10").font(.largeTitle)
                    Text("\(tap.forward ? "+" : "−")\(tap.seconds)s").font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxHeight: .infinity)
                .frame(width: 220)
                .background(.white.opacity(0.12), in: UnevenRoundedRectangle(
                    topLeadingRadius: tap.forward ? 400 : 0, bottomLeadingRadius: tap.forward ? 400 : 0,
                    bottomTrailingRadius: tap.forward ? 0 : 400, topTrailingRadius: tap.forward ? 0 : 400
                ))
                .transition(.opacity)
                if !tap.forward { Spacer() }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder private var hudView: some View {
        switch hud {
        case .seek(let target, let delta):
            Text("\(formatTime(target))  (\(delta >= 0 ? "+" : "−")\(formatTime(abs(delta))))")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .glassSurface(in: .rect(cornerRadius: 16))
                .allowsHitTesting(false)
        case .brightness(let level):
            levelView(icon: "sun.max.fill", value: level)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .volume(let level):
            levelView(icon: level == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill", value: level)
                .frame(maxWidth: .infinity, alignment: .trailing)
        case nil:
            EmptyView()
        }
    }

    /// A vertical level bar pinned to the screen edge the finger is dragging on.
    private func levelView(icon: String, value: Double) -> some View {
        VStack(spacing: 10) {
            Text("\(Int(value * 100))").font(.caption.bold().monospacedDigit())
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: 6, height: 140)
                .overlay(alignment: .bottom) {
                    Capsule().fill(Color.brandLight).frame(height: 140 * value)
                }
            Image(systemName: icon).font(.subheadline)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 14)
        .frame(width: 48)
        .glassSurface(in: .capsule)
        .padding(.horizontal, 32)
        .allowsHitTesting(false)
    }
}

/// The AVPlayerLayer (aspect fit / fill) plus its Picture-in-Picture controller.
private struct VideoSurface: UIViewRepresentable {
    let model: PlayerModel

    func makeUIView(context: Context) -> LayerView {
        let view = LayerView()
        view.playerLayer.player = model.player
        if AVPictureInPictureController.isPictureInPictureSupported() {
            let pip = AVPictureInPictureController(playerLayer: view.playerLayer)
            pip?.canStartPictureInPictureAutomaticallyFromInline = true
            model.pip = pip
        }
        return view
    }

    func updateUIView(_ view: LayerView, context: Context) {
        view.playerLayer.videoGravity = model.fill ? .resizeAspectFill : .resizeAspect
        if let window = view.window { model.attachVolumeView(to: window) }
    }

    final class LayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
