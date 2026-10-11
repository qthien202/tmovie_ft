import Foundation
import Models
import Networking
import Observation
import UIKit

/// One episode saved (or being saved) for offline viewing.
public struct DownloadItem: Codable, Identifiable, Hashable, Sendable {
    public enum State: String, Codable, Sendable { case queued, downloading, done, failed }

    public let slug: String
    public let server: Int
    public let index: Int
    public let filmName: String
    public let episodeName: String
    public let posterURL: URL?
    public internal(set) var state: State
    public internal(set) var progress: Double
    public internal(set) var bytes: Int64

    public var id: String { Self.id(slug, server, index) }
    static func id(_ slug: String, _ server: Int, _ index: Int) -> String { "\(slug)~\(server)~\(index)" }
}

/// Offline episodes. HLS is fetched by hand rather than with `AVAssetDownloadURLSession`, so the
/// playlist goes through `HLSAdFilter` first: segments land in `Application Support/Downloads/<id>/`
/// next to a rewritten `index.m3u8`, and `LocalHLSServer` serves them back to AVPlayer.
/// Downloads run one episode at a time while the app is open.
@MainActor @Observable
public final class Downloads {
    public static let shared = Downloads()

    /// Starts the local server and resumes queued downloads; call at launch.
    public static func start() { _ = shared }

    public private(set) var items: [DownloadItem] = []
    @ObservationIgnored private var worker: Task<Void, Never>?
    @ObservationIgnored private var workingID: String?
    @ObservationIgnored let root: URL

    private init() {
        root = URL.applicationSupportDirectory.appending(path: "Downloads", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: root.appending(path: "films"), withIntermediateDirectories: true)
        var dir = root
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)
        items = (try? JSONDecoder().decode([DownloadItem].self, from: Data(contentsOf: indexFile))) ?? []
        for i in items.indices where items[i].state == .downloading { items[i].state = .queued }
        LocalHLSServer.shared.start(root: root, wait: true)
        pump()
    }

    // MARK: Queries

    public func item(_ slug: String, server: Int, index: Int) -> DownloadItem? {
        items.first { $0.id == DownloadItem.id(slug, server, index) }
    }

    /// The film details saved with its downloads, so they play with no network.
    public func film(_ slug: String) -> FilmDetail? {
        try? JSONDecoder().decode(FilmDetail.self, from: Data(contentsOf: filmFile(slug)))
    }

    /// Loopback URL of a finished episode's playlist.
    func localURL(slug: String, server: Int, index: Int) -> URL? {
        guard let item = item(slug, server: server, index: index), item.state == .done else { return nil }
        return LocalHLSServer.shared.url(for: "\(item.id)/index.m3u8")
    }

    public var totalBytes: Int64 { items.map(\.bytes).reduce(0, +) }

    // MARK: Actions

    public func enqueue(_ film: FilmDetail, server: Int, index: Int) {
        let servers = (film.episodes ?? []).map { $0.serverData ?? [] }
        guard servers.indices.contains(server), servers[server].indices.contains(index), item(film.slug, server: server, index: index) == nil else { return }
        let ep = servers[server][index]
        try? JSONEncoder().encode(film).write(to: filmFile(film.slug))
        items.append(DownloadItem(slug: film.slug, server: server, index: index, filmName: film.name,
                                  episodeName: ep.name ?? "Tập \(index + 1)", posterURL: film.posterURL,
                                  state: .queued, progress: 0, bytes: 0))
        persist()
        pump()
    }

    public func retry(_ item: DownloadItem) {
        update(item.id) { $0.state = .queued }
        pump()
    }

    public func remove(_ item: DownloadItem) {
        if workingID == item.id { worker?.cancel() }
        items.removeAll { $0.id == item.id }
        try? FileManager.default.removeItem(at: root.appending(path: item.id))
        if !items.contains(where: { $0.slug == item.slug }) { try? FileManager.default.removeItem(at: filmFile(item.slug)) }
        persist()
    }

    // MARK: Worker

    private func pump() {
        guard worker == nil, let next = items.first(where: { $0.state == .queued }) else { return }
        workingID = next.id
        update(next.id) { $0.state = .downloading }
        // Some extra time to finish a segment after the app goes to the background.
        // ponytail: foreground-only; a background URLSession would let long episodes finish in the background.
        let background = UIApplication.shared.beginBackgroundTask(withName: "download")
        worker = Task {
            do {
                try await download(next)
                update(next.id) { $0.state = .done; $0.progress = 1 }
            } catch {
                if !Task.isCancelled { update(next.id) { $0.state = .failed } }
            }
            UIApplication.shared.endBackgroundTask(background)
            worker = nil
            workingID = nil
            pump()
        }
    }

    private func download(_ item: DownloadItem) async throws {
        guard let film = film(item.slug),
              let url = film.episodes?[safe: item.server]?.serverData?[safe: item.index]?.streamURL
        else { throw URLError(.badURL) }
        let dir = root.appending(path: item.id, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var (text, base) = try await Self.fetchText(url)
        if text.contains("#EXT-X-STREAM-INF") {
            guard let variant = Self.pickVariant(text, base: base) else { throw URLError(.cannotParseResponse) }
            (text, base) = try await Self.fetchText(variant)
        }
        let plan = Self.plan(HLSAdFilter.clean(text), base: base)

        // Four segments at a time; files already on disk (an interrupted run) are skipped.
        var done = 0
        try await withThrowingTaskGroup(of: Int64.self) { group in
            var pending = plan.files.makeIterator()
            func addNext() -> Bool {
                guard let (remote, name) = pending.next() else { return false }
                group.addTask { try await Self.fetchFile(remote, to: dir.appending(path: name)) }
                return true
            }
            for _ in 0..<4 { _ = addNext() }
            var bytes: Int64 = 0
            while let size = try await group.next() {
                done += 1
                bytes += size
                let progress = Double(done) / Double(max(plan.files.count, 1))
                update(item.id) { $0.progress = progress; $0.bytes = bytes }
                _ = addNext()
            }
        }
        try Data(plan.playlist.utf8).write(to: dir.appending(path: "index.m3u8"))
    }

    // MARK: Helpers

    private var indexFile: URL { root.appending(path: "index.json") }
    private func filmFile(_ slug: String) -> URL { root.appending(path: "films/\(slug).json") }

    private func update(_ id: String, _ change: (inout DownloadItem) -> Void) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        change(&items[i])
        if items[i].state != .downloading || Int(items[i].progress * 100) % 5 == 0 { persist() }
    }

    private func persist() {
        try? JSONEncoder().encode(items).write(to: indexFile)
    }

    nonisolated private static func fetchText(_ url: URL) async throws -> (String, URL) {
        let (data, response) = try await URLSession.shared.data(from: url)
        return (String(decoding: data, as: UTF8.self), response.url ?? url)
    }

    /// Downloads to `dest` (with retries) unless it is already there; returns the file size.
    nonisolated private static func fetchFile(_ url: URL, to dest: URL) async throws -> Int64 {
        if let size = (try? dest.resourceValues(forKeys: [.fileSizeKey]))?.fileSize, size > 0 { return Int64(size) }
        var attempt = 0
        while true {
            do {
                let (temp, response) = try await URLSession.shared.download(from: url)
                guard (response as? HTTPURLResponse)?.statusCode ?? 200 < 400 else { throw URLError(.badServerResponse) }
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.moveItem(at: temp, to: dest)
                return Int64((try? dest.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            } catch {
                attempt += 1
                if attempt >= 3 || Task.isCancelled { throw error }
                try await Task.sleep(for: .seconds(attempt * 2))
            }
        }
    }

    /// The rendition to save: the tallest one up to 720p, else the smallest.
    nonisolated static func pickVariant(_ master: String, base: URL) -> URL? {
        let lines = master.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        var options: [(height: Int, url: URL)] = []
        for (i, line) in lines.enumerated() where line.hasPrefix("#EXT-X-STREAM-INF") {
            guard let uri = lines[(i + 1)...].first(where: { !$0.isEmpty && !$0.hasPrefix("#") }),
                  let url = URL(string: uri, relativeTo: base)?.absoluteURL else { continue }
            let height = line.range(of: #"RESOLUTION=\d+x(\d+)"#, options: .regularExpression)
                .flatMap { Int(line[$0].split(separator: "x").last ?? "") } ?? 0
            options.append((height, url))
        }
        return (options.filter { $0.height <= 720 }.max { $0.height < $1.height } ?? options.min { $0.height < $1.height })?.url
    }

    /// Local playlist (relative file names) plus the remote files it needs: segments, keys, init maps.
    nonisolated static func plan(_ playlist: String, base: URL) -> (playlist: String, files: [(URL, String)]) {
        var files: [(URL, String)] = []
        func local(_ uri: String) -> String? {
            guard let url = URL(string: uri, relativeTo: base)?.absoluteURL else { return nil }
            let ext = url.pathExtension.isEmpty ? "bin" : url.pathExtension
            let name = String(format: "f%05d.%@", files.count, ext)
            files.append((url, name))
            return name
        }
        let out = playlist.components(separatedBy: .newlines).compactMap { raw -> String? in
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { return nil }
            if !line.hasPrefix("#") { return local(line) }
            guard let range = line.range(of: #"URI="([^"]+)""#, options: .regularExpression),
                  let name = local(String(line[range].dropFirst(5).dropLast())) else { return line }
            return line.replacingCharacters(in: range, with: "URI=\"\(name)\"")
        }
        return (out.joined(separator: "\n") + "\n", files)
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
