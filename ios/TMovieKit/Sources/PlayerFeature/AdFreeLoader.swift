import AVFoundation
import Foundation
import Networking

/// One HLS rendition from the master playlist, for the quality picker.
struct Variant: Hashable, Sendable {
    let height: Int
    let bandwidth: Double
}

/// Serves HLS playlists through `HLSAdFilter` before AVPlayer sees them.
///
/// Playlist URLs are handed to AVPlayer with a private scheme (`tmovie-https://…`), which routes
/// them here. Master playlists get their variant URIs rewritten to the private scheme too; media
/// playlists get ads stripped and every segment / key URI made absolute `https`, so the video
/// data itself still streams straight from the CDN.
final class AdFreeLoader: NSObject, AVAssetResourceLoaderDelegate, @unchecked Sendable {
    private static let prefix = "tmovie-"
    private let queue = DispatchQueue(label: "tmovie.adfree")
    /// Called (on any thread) with the renditions found in the master playlist.
    var onVariants: (@Sendable ([Variant]) -> Void)?

    /// An asset for `url` whose playlists load through this loader. Keep the loader alive with the asset.
    func asset(for url: URL) -> AVURLAsset {
        let asset = AVURLAsset(url: Self.wrap(url))
        asset.resourceLoader.setDelegate(self, queue: queue)
        return asset
    }

    static func wrap(_ url: URL) -> URL {
        guard var c = URLComponents(url: url, resolvingAgainstBaseURL: true), let scheme = c.scheme, !scheme.hasPrefix(prefix) else { return url }
        c.scheme = prefix + scheme
        return c.url ?? url
    }

    private static func unwrap(_ url: URL) -> URL? {
        guard var c = URLComponents(url: url, resolvingAgainstBaseURL: true), let scheme = c.scheme, scheme.hasPrefix(prefix) else { return nil }
        c.scheme = String(scheme.dropFirst(prefix.count))
        return c.url
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let wrapped = loadingRequest.request.url, let real = Self.unwrap(wrapped) else { return false }
        nonisolated(unsafe) let request = loadingRequest
        Task {
            do {
                var urlRequest = URLRequest(url: real)
                urlRequest.timeoutInterval = 20
                let (data, response) = try await URLSession.shared.data(for: urlRequest)
                let base = response.url ?? real
                let text = rewrite(String(decoding: data, as: UTF8.self), base: base)
                request.dataRequest?.respond(with: Data(text.utf8))
                request.finishLoading()
            } catch {
                request.finishLoading(with: error)
            }
        }
        return true
    }

    private func rewrite(_ playlist: String, base: URL) -> String {
        let isMaster = playlist.contains("#EXT-X-STREAM-INF")
        let body = isMaster ? playlist : HLSAdFilter.clean(playlist)
        if isMaster { onVariants?(Self.variants(in: playlist)) }

        // Sub-playlists keep the private scheme (so they come back here); everything else goes to https.
        func absolute(_ uri: String, playlist: Bool) -> String {
            guard let url = URL(string: uri, relativeTo: base)?.absoluteURL else { return uri }
            return (playlist ? Self.wrap(url) : url).absoluteString
        }
        return body.components(separatedBy: .newlines).map { line -> String in
            if line.isEmpty { return line }
            if !line.hasPrefix("#") { return absolute(line, playlist: isMaster) }
            guard let range = line.range(of: #"URI="([^"]+)""#, options: .regularExpression) else { return line }
            let uri = String(line[range].dropFirst(5).dropLast())
            let isPlaylist = line.hasPrefix("#EXT-X-MEDIA") || line.hasPrefix("#EXT-X-I-FRAME-STREAM-INF")
            return line.replacingCharacters(in: range, with: "URI=\"\(absolute(uri, playlist: isPlaylist))\"")
        }.joined(separator: "\n")
    }

    private static func variants(in master: String) -> [Variant] {
        master.components(separatedBy: .newlines).filter { $0.hasPrefix("#EXT-X-STREAM-INF") }.compactMap { line in
            let bandwidth = line.range(of: #"BANDWIDTH=(\d+)"#, options: .regularExpression).flatMap { Double(line[$0].dropFirst(10)) } ?? 0
            let height = line.range(of: #"RESOLUTION=\d+x(\d+)"#, options: .regularExpression)
                .flatMap { Int(line[$0].split(separator: "x").last ?? "") } ?? 0
            return bandwidth > 0 ? Variant(height: height, bandwidth: bandwidth) : nil
        }
    }
}
