import AVFoundation
import AVKit
import MediaPlayer
import Models
import Network
import Observation
import Persistence
import UIKit

/// Everything the custom player screen shows and does: playback state, episode switching,
/// resume + progress saving, quality / audio / subtitles / speed / aspect, sleep timer,
/// network-loss recovery, PiP and lock-screen info.
@MainActor @Observable
final class PlayerModel {
    enum Panel { case none, settings, episodes }

    let film: FilmDetail
    private(set) var server: Int
    private(set) var index: Int

    // Playback
    let player = AVPlayer()
    private(set) var isPlaying = false
    private(set) var buffering = true
    private(set) var failed = false
    private(set) var ended = false
    private(set) var position: Double = 0
    private(set) var duration: Double = 0
    private(set) var buffered: Double = 0
    private(set) var speed: Float = 1
    private(set) var offline = false
    /// Playing a downloaded copy: network changes don't matter.
    private(set) var playingLocal = false

    // UI
    var controlsVisible = true
    var locked = false
    var panel = Panel.none
    var fill = false  // aspect fill vs fit
    var nextCancelled = false
    var canShowDetail = false
    private(set) var sleepMinutes = 0  // -1 = end of this episode
    private(set) var variants: [Variant] = []
    private(set) var peakBitRate: Double = 0
    private var lastInteraction = Date()

    // Plumbing
    private var loader = AdFreeLoader()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var lastSave = Date.distantPast
    private var sleepTask: Task<Void, Never>?
    private var recoveries = 0
    private let pathMonitor = NWPathMonitor()
    var pip: AVPictureInPictureController?

    init(film: FilmDetail, server: Int, index: Int) {
        self.film = film
        self.server = server
        self.index = index
        player.allowsExternalPlayback = true
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 4), queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.networkChanged(online: online) }
        }
        pathMonitor.start(queue: DispatchQueue(label: "tmovie.path"))
        load()
    }

    // MARK: Episodes

    var servers: [[ServerData]] { (film.episodes ?? []).map { $0.serverData ?? [] } }
    var serverNames: [String] { (film.episodes ?? []).enumerated().map { $1.serverName ?? "Server \($0 + 1)" } }
    var episodes: [ServerData] { servers.indices.contains(server) ? servers[server] : [] }
    var episode: ServerData? { episodes.indices.contains(index) ? episodes[index] : nil }
    var nextIndex: Int? { episodes.indices.first { $0 > index && episodes[$0].streamURL != nil } }
    var hasEpisodeList: Bool { episodes.count > 1 || servers.count > 1 }

    func switchTo(server s: Int, index i: Int) {
        save()
        server = s
        index = i
        panel = .none
        load()
    }

    func playNext() {
        if sleepMinutes == -1 { player.pause(); sleepMinutes = 0; return }  // "end of this episode"
        if let next = nextIndex { switchTo(server: server, index: next) }
    }

    private func load(at resumeOverride: Double? = nil) {
        guard let ep = episode, let url = ep.streamURL else { return }
        failed = false
        ended = false
        nextCancelled = false
        buffering = true
        variants = []
        loader = AdFreeLoader()
        loader.onVariants = { [weak self] found in
            Task { @MainActor in self?.variants = Array(Set(found)).sorted { $0.bandwidth > $1.bandwidth } }
        }
        let local = Downloads.shared.localURL(slug: film.slug, server: server, index: index)
        playingLocal = local != nil
        let item = local.map { AVPlayerItem(url: $0) } ?? AVPlayerItem(asset: loader.asset(for: url))
        item.preferredForwardBufferDuration = 30
        item.preferredPeakBitRate = peakBitRate
        item.externalMetadata = [metadata(.commonIdentifierTitle, film.name), metadata(.iTunesMetadataTrackSubTitle, ep.name ?? "")]
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.ended = true
                self.save()
                if !self.nextCancelled { self.playNext() }
            }
        }
        player.replaceCurrentItem(with: item)

        // Resume unless the episode was basically finished. Synced Flutter positions are keyed by episode name.
        let record = Library.record(film.slug)
        let saved = record?.positions[ep.slug ?? ""] ?? record?.positions[ep.name ?? ""] ?? 0
        let total = record?.durations[ep.slug ?? ""] ?? 0
        let resume = resumeOverride ?? ((saved > 5 && (total == 0 || saved < total - 20)) ? saved : 0)
        if resume > 0 { item.seek(to: CMTime(seconds: resume, preferredTimescale: 600), completionHandler: nil) }
        player.playImmediately(atRate: speed)
        updateNowPlaying()
        save()
        interact()
    }

    // MARK: Transport

    func toggle() {
        if isPlaying { player.pause() } else {
            if ended { seek(to: 0); ended = false }
            player.playImmediately(atRate: speed)
        }
        interact()
    }

    func seek(to seconds: Double) {
        let target = max(0, duration > 0 ? min(seconds, duration - 1) : seconds)
        position = target
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        interact()
    }

    func seek(by seconds: Double) { seek(to: player.currentTime().seconds + seconds) }

    func setSpeed(_ value: Float) {
        speed = value
        player.defaultRate = value
        if isPlaying { player.rate = value }
    }

    func setQuality(_ variant: Variant?) {
        peakBitRate = variant?.bandwidth ?? 0
        player.currentItem?.preferredPeakBitRate = peakBitRate
    }

    func retry() {
        let at = position
        load(at: at > 0 ? at : nil)
    }

    // MARK: Audio / subtitles

    struct MediaOption: Identifiable {
        let id: String
        let name: String
        let selected: Bool
        let select: () -> Void
    }

    private(set) var audioOptions: [MediaOption] = []
    private(set) var subtitleOptions: [MediaOption] = []

    func loadMediaOptions() async {
        guard let item = player.currentItem else { return }
        audioOptions = await options(for: .audible, item: item, allowOff: false)
        subtitleOptions = await options(for: .legible, item: item, allowOff: true)
    }

    private func options(for characteristic: AVMediaCharacteristic, item: AVPlayerItem, allowOff: Bool) async -> [MediaOption] {
        guard let group = try? await item.asset.loadMediaSelectionGroup(for: characteristic), group.options.count > (allowOff ? 0 : 1) else { return [] }
        let current = item.currentMediaSelection.selectedMediaOption(in: group)
        var list = group.options.map { option in
            MediaOption(id: option.displayName, name: option.displayName, selected: option == current) { [weak self] in
                item.select(option, in: group)
                Task { await self?.loadMediaOptions() }
            }
        }
        if allowOff {
            list.insert(MediaOption(id: "off", name: "Tắt", selected: current == nil) { [weak self] in
                item.select(nil, in: group)
                Task { await self?.loadMediaOptions() }
            }, at: 0)
        }
        return list
    }

    // MARK: Sleep timer

    func setSleep(minutes: Int) {
        sleepMinutes = minutes
        sleepTask?.cancel()
        guard minutes > 0 else { return }
        sleepTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(minutes * 60))
            guard !Task.isCancelled else { return }
            self?.player.pause()
            self?.sleepMinutes = 0
            self?.controlsVisible = true
        }
    }

    // MARK: Controls visibility

    #if DEBUG
    private let keepControls = UserDefaults.standard.bool(forKey: "keepControls")
    #else
    private let keepControls = false
    #endif

    func interact() {
        lastInteraction = .now
        controlsVisible = true
    }

    // MARK: Ticks, saving, recovery

    private func tick() {
        let item = player.currentItem
        position = player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0
        duration = item?.duration.seconds.isFinite == true ? item!.duration.seconds : 0
        if let range = item?.loadedTimeRanges.first?.timeRangeValue { buffered = (range.start + range.duration).seconds }
        isPlaying = player.timeControlStatus == .playing
        buffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        if item?.status == .failed, !failed { streamFailed() }

        // Controls fade 3 s after the last touch while playing (`-keepControls YES` holds them, for screenshots).
        if isPlaying, !keepControls, panel == .none, controlsVisible, Date.now.timeIntervalSince(lastInteraction) > 3 { controlsVisible = false }
        if isPlaying, Date.now.timeIntervalSince(lastSave) >= 10 { save() }
        UIApplication.shared.isIdleTimerDisabled = isPlaying
    }

    /// Stream errors retry up to 3 times at the same spot; while offline we wait for the network instead.
    private func streamFailed() {
        failed = true
        guard !offline, recoveries < 3 else { return }
        recoveries += 1
        let at = position
        Task {
            try? await Task.sleep(for: .seconds(recoveries))
            self.load(at: at)
        }
    }

    private func networkChanged(online: Bool) {
        let wasOffline = offline
        offline = !online && !playingLocal
        // Back online: pick up where we were if the stream died or stalled meanwhile.
        if wasOffline, online, failed || buffering { recoveries = 0; load(at: position) }
    }

    func save() {
        guard let ep = episode else { return }
        lastSave = .now
        Library.save(
            film: FilmItem(film), server: server, episode: index, episodeName: ep.name ?? "", episodeSlug: ep.slug ?? "",
            position: player.currentTime().seconds, duration: player.currentItem?.duration.seconds ?? 0
        )
    }

    // MARK: System integration

    private func updateNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: film.name,
            MPMediaItemPropertyArtist: episode?.name ?? "",
        ]
    }

    /// System brightness (left-side drag).
    var brightness: CGFloat {
        get { (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.brightness ?? 0.5 }
        set { (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.brightness = min(1, max(0, newValue)) }
    }

    /// System volume (right-side drag), set through MPVolumeView's slider — the only public route.
    private let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
    var volume: Float {
        get { AVAudioSession.sharedInstance().outputVolume }
        set { (volumeView.subviews.first { $0 is UISlider } as? UISlider)?.value = min(1, max(0, newValue)) }
    }

    func attachVolumeView(to window: UIView) {
        if volumeView.superview == nil { window.addSubview(volumeView) }
    }

    func tearDown() {
        save()
        player.pause()
        player.replaceCurrentItem(with: nil)
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        timeObserver = nil
        endObserver = nil
        sleepTask?.cancel()
        pathMonitor.cancel()
        volumeView.removeFromSuperview()
        UIApplication.shared.isIdleTimerDisabled = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func metadata(_ id: AVMetadataIdentifier, _ value: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = id
        item.value = value as NSString
        item.extendedLanguageTag = "und"
        return item
    }
}

/// "1:15", "1:02:05".
func formatTime(_ seconds: Double) -> String {
    let total = Int(max(0, seconds.isFinite ? seconds : 0))
    let h = total / 3600, m = (total % 3600) / 60, s = total % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}
