import AVFoundation
import Models
import Persistence
import SwiftUI
import UIKit

/// Opens the custom full-screen player (landscape) for a film's episode.
@MainActor
public enum Player {
    /// Posted before the full-screen player appears, so inline previews can stop.
    public static let willPresent = Notification.Name("TMoviePlayerWillPresent")

    /// The open player's controller, kept so a new episode replaces it.
    private static weak var current: PlayerHostingController?

    /// Plays `episodes[index]` of `server`, resuming at the saved second.
    public static func play(_ film: FilmDetail, server: Int, episodes: [ServerData], at index: Int) {
        NotificationCenter.default.post(name: willPresent, object: nil)
        current?.closePlayer(animated: false)
        let model = PlayerModel(film: film, server: server, index: index)
        let host = PlayerHostingController(model: model)
        current = host
        OrientationLock.rotate(to: .landscape)
        topViewController()?.present(host, animated: true)
    }

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

    static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

/// Hosts `PlayerScreen` full screen in landscape, hiding the home indicator.
final class PlayerHostingController: UIHostingController<PlayerScreen> {
    private let model: PlayerModel

    init(model: PlayerModel) {
        self.model = model
        var close: () -> Void = {}
        super.init(rootView: PlayerScreen(model: model, close: { close() }))
        close = { [weak self] in self?.closePlayer(animated: true) }
        rootView = PlayerScreen(model: model, close: close)
        modalPresentationStyle = .fullScreen
        view.backgroundColor = .black
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { true }

    func closePlayer(animated: Bool) {
        model.pip?.stopPictureInPicture()
        model.tearDown()
        OrientationLock.rotate(to: .portrait)
        dismiss(animated: animated)
    }
}
