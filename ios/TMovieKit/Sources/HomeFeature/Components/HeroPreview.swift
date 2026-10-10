import AVFoundation
import Models
import Networking
import PlayerFeature
import SwiftUI
import UIKit

/// Muted autoplay preview for the hero, Apple TV style: after the art has shown for a moment,
/// a 45s window of episode 1 (from ~4 min in, past the opening) fades in and loops.
/// PhimAPI rarely has trailers (and those are YouTube), but every film has HLS episodes.
struct HeroPreview: View {
    let slug: String
    @Binding var muted: Bool

    @State private var preview: PreviewPlayer?
    @State private var visible = false

    var body: some View {
        ZStack {
            if let preview {
                PlayerLayerView(player: preview.player)
                    .opacity(visible ? 1 : 0)
                    .animation(.easeInOut(duration: 1.2), value: visible)
            }
        }
        .allowsHitTesting(false)
        .task(id: slug) {
            visible = false
            try? await Task.sleep(for: .seconds(1.5))  // let the key art land first
            guard !Task.isCancelled,
                  let detail = try? await PhimAPI.shared.detail(slug: slug),
                  let url = detail.episodes?.first?.serverData?.first(where: { $0.streamURL != nil })?.streamURL
            else { return }
            let p = PreviewPlayer(url: url, muted: muted)
            preview = p
            await p.start()
            guard !Task.isCancelled else { return p.stop() }
            visible = true
        }
        .onChange(of: muted) { preview?.player.isMuted = muted }
        .onDisappear {
            preview?.stop()
            preview = nil
            visible = false
        }
        .onReceive(NotificationCenter.default.publisher(for: Player.willPresent)) { _ in
            preview?.stop()
            visible = false
        }
    }
}

/// One looping, muted AVPlayer over a fixed window of a stream.
@MainActor
final class PreviewPlayer {
    let player = AVPlayer()
    private var boundary: Any?
    private let item: AVPlayerItem

    init(url: URL, muted: Bool) {
        item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 10
        player.isMuted = muted
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.replaceCurrentItem(with: item)
    }

    /// Seeks past the opening, starts playback and loops a 45s window. Returns once playing.
    func start() async {
        let duration = (try? await item.asset.load(.duration))?.seconds ?? 0
        let from = duration > 600 ? 240 : max(0, duration * 0.1)
        let start = CMTime(seconds: from, preferredTimescale: 600)
        await player.seek(to: start, toleranceBefore: .positiveInfinity, toleranceAfter: .positiveInfinity)
        boundary = player.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTime(seconds: from + 45, preferredTimescale: 600))], queue: .main) { [weak self] in
            MainActor.assumeIsolated { self?.player.seek(to: start) }
        }
        player.play()
        // Wait until frames are actually flowing so the fade never shows a black layer.
        for _ in 0..<40 where player.timeControlStatus != .playing {
            try? await Task.sleep(for: .milliseconds(250))
        }
    }

    func stop() {
        player.pause()
        if let boundary { player.removeTimeObserver(boundary) }
        boundary = nil
        player.replaceCurrentItem(with: nil)
    }
}

/// AVPlayerLayer filling its bounds (aspect fill), as a SwiftUI view.
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> LayerView {
        let view = LayerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ view: LayerView, context: Context) { view.playerLayer.player = player }

    final class LayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
