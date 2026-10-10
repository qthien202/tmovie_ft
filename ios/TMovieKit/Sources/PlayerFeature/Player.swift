import AVKit
import Models
import Persistence
import UIKit

/// Presents AVPlayerViewController full screen (UIKit, not a SwiftUI cover) so AVKit owns the
/// whole experience: Done/swipe-down, scrubbing, speed, PiP, AirPlay, idle-fading chrome,
/// keep-awake. A "Tập tiếp theo" button shows in the last 18s and the next episode auto-plays at the end.
@MainActor
public final class Player: NSObject, AVPlayerViewControllerDelegate {
    /// Posted before the full-screen player appears, so inline previews can stop.
    public static let willPresent = Notification.Name("TMoviePlayerWillPresent")

    /// Kept alive while on screen or in Picture in Picture.
    private static var current: Player?

    private let film: FilmDetail
    private let server: Int
    private let episodes: [ServerData]
    private var index: Int
    private var lastSave = Date.distantPast
    private var resignObserver: NSObjectProtocol?
    private let player = AVPlayer()
    private let controller = AVPlayerViewController()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var inPiP = false
    private lazy var nextButton: UIButton = {
        var config: UIButton.Configuration
        if #available(iOS 26, *) { config = .glass() } else { config = .filled(); config.baseBackgroundColor = .white; config.baseForegroundColor = .black }
        config.title = "Tập tiếp theo"
        config.image = UIImage(systemName: "forward.end.fill")
        config.imagePadding = 8
        config.cornerStyle = .capsule
        config.buttonSize = .large
        let b = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.playNext() })
        b.translatesAutoresizingMaskIntoConstraints = false
        b.alpha = 0
        return b
    }()

    /// Plays `episodes[index]` of `server`, resuming at the saved second.
    public static func play(_ film: FilmDetail, server: Int, episodes: [ServerData], at index: Int) {
        current?.tearDown()
        let p = Player(film: film, server: server, episodes: episodes, index: index)
        current = p
        p.present()
    }

    private init(film: FilmDetail, server: Int, episodes: [ServerData], index: Int) {
        self.film = film
        self.server = server
        self.episodes = episodes
        self.index = index
        super.init()
        controller.player = player
        controller.delegate = self
        controller.allowsPictureInPicturePlayback = true
        controller.modalPresentationStyle = .fullScreen
        // ponytail: sits on top of AVKit's controls; move into a custom overlay if AVKit ever covers it.
        controller.view.addSubview(nextButton)
        NSLayoutConstraint.activate([
            nextButton.trailingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor, constant: -84),
        ])
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .main) { [weak self] time in
            MainActor.assumeIsolated { self?.tick(time) }
        }
        resignObserver = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveProgress() }
        }
        load(index)
    }

    private func load(_ i: Int) {
        guard episodes.indices.contains(i), let url = episodes[i].streamURL else { return }
        if player.currentItem != nil { saveProgress() }
        index = i
        let item = AVPlayerItem(url: url)
        item.externalMetadata = [
            metadata(.commonIdentifierTitle, film.name),
            metadata(.iTunesMetadataTrackSubTitle, episodes[i].name ?? ""),
        ]
        showNext(false)
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.playNext() }
        }
        player.replaceCurrentItem(with: item)
        let ep = episodes[i]
        let record = Library.record(film.slug)
        let resume = record?.positions[ep.slug ?? ""] ?? 0
        let total = record?.durations[ep.slug ?? ""] ?? 0
        // Resume unless the episode was basically finished.
        if resume > 5, total == 0 || resume < total - 20 {
            item.seek(to: CMTime(seconds: resume, preferredTimescale: 600), completionHandler: nil)
        }
        player.play()
        saveProgress()
    }

    private var nextIndex: Int? {
        episodes.indices.first { $0 > index && episodes[$0].streamURL != nil }
    }

    private func playNext() {
        if let next = nextIndex { load(next) }
    }

    private func tick(_ time: CMTime) {
        if Date.now.timeIntervalSince(lastSave) >= 10 { saveProgress() }
        guard let duration = player.currentItem?.duration.seconds, duration.isFinite, nextIndex != nil else { return }
        showNext(duration - time.seconds <= 18)
    }

    private func saveProgress() {
        lastSave = .now
        let ep = episodes[index]
        Library.save(
            film: FilmItem(film), server: server, episode: index, episodeName: ep.name ?? "", episodeSlug: ep.slug ?? "",
            position: player.currentTime().seconds, duration: player.currentItem?.duration.seconds ?? 0
        )
    }

    private func showNext(_ show: Bool) {
        guard (nextButton.alpha == 1) != show else { return }
        UIView.animate(springDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.4, bounce: 0.2) {
            nextButton.alpha = show ? 1 : 0
            nextButton.transform = show ? .identity : CGAffineTransform(translationX: 0, y: 12)
        }
    }

    // MARK: Presentation

    private func present() {
        NotificationCenter.default.post(name: Player.willPresent, object: nil)
        OrientationLock.rotate(to: .landscape)
        topViewController()?.present(controller, animated: true)
    }

    private func tearDown() {
        saveProgress()
        player.pause()
        player.replaceCurrentItem(with: nil)
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        timeObserver = nil
        endObserver = nil
        if Self.current === self { Self.current = nil }
    }

    public nonisolated func playerViewController(_ vc: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { [weak self] ctx in
            MainActor.assumeIsolated {
                guard let self, !ctx.isCancelled else { return }
                OrientationLock.rotate(to: .portrait)
                if !self.inPiP { self.tearDown() }
            }
        }
    }

    public nonisolated func playerViewControllerWillStartPictureInPicture(_ vc: AVPlayerViewController) {
        MainActor.assumeIsolated { inPiP = true }
    }

    public nonisolated func playerViewControllerDidStopPictureInPicture(_ vc: AVPlayerViewController) {
        MainActor.assumeIsolated {
            inPiP = false
            if controller.presentingViewController == nil { tearDown() }
        }
    }

    public nonisolated func playerViewController(_ vc: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completion: @escaping (Bool) -> Void) {
        nonisolated(unsafe) let completion = completion
        MainActor.assumeIsolated {
            guard controller.presentingViewController == nil, let top = topViewController() else { return completion(true) }
            OrientationLock.rotate(to: .landscape)
            top.present(controller, animated: true) { completion(true) }
        }
    }

    private func metadata(_ id: AVMetadataIdentifier, _ value: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = id
        item.value = value as NSString
        item.extendedLanguageTag = "und"
        return item
    }

    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

extension Player {
    /// "Phát" / "Tiếp tục": resumes the last watched episode, else the first playable one.
    /// Returns false when the film has no playable link.
    @discardableResult
    public static func start(_ detail: FilmDetail) -> Bool {
        let servers = (detail.episodes ?? []).map { $0.serverData ?? [] }
        if let r = Library.record(detail.slug), servers.indices.contains(r.serverIndex),
           servers[r.serverIndex].indices.contains(r.episodeIndex), servers[r.serverIndex][r.episodeIndex].streamURL != nil {
            play(detail, server: r.serverIndex, episodes: servers[r.serverIndex], at: r.episodeIndex)
            return true
        }
        for (s, list) in servers.enumerated() {
            if let i = list.firstIndex(where: { $0.streamURL != nil }) {
                play(detail, server: s, episodes: list, at: i)
                return true
            }
        }
        return false
    }
}
