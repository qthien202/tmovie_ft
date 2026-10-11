import Foundation
import Network

/// A tiny HTTP server on 127.0.0.1 for downloaded episodes: AVPlayer will not play HLS from
/// `file://` URLs, but it will from loopback. GET only, with byte ranges, one request per connection.
final class LocalHLSServer: @unchecked Sendable {
    static let shared = LocalHLSServer()

    private let queue = DispatchQueue(label: "tmovie.localhls")
    private var listener: NWListener?
    private var root: URL?
    /// Read from the main actor, written on `queue` once the listener is ready.
    nonisolated(unsafe) private var port: UInt16 = 0

    /// `wait` blocks (briefly) until the port is known, so the first `url(for:)` already works.
    func start(root: URL, wait: Bool = false) {
        guard listener == nil else { return }
        let ready = DispatchSemaphore(value: 0)
        self.root = root
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        guard let listener = try? NWListener(using: params) else { return }
        listener.stateUpdateHandler = { [weak self, weak listener] state in
            switch state {
            case .ready:
                if let port = listener?.port?.rawValue { self?.port = port }
                ready.signal()
            case .failed:
                // iOS can tear the socket down while the app is suspended; come back on a new port.
                listener?.cancel()
                self?.port = 0
                self?.listener = nil
                self?.start(root: root)
            default: break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: self?.queue ?? .main)
            self?.serve(connection)
        }
        listener.start(queue: queue)
        self.listener = listener
        if wait { _ = ready.wait(timeout: .now() + 0.5) }
    }

    /// nil until the listener is up.
    func url(for path: String) -> URL? {
        port == 0 ? nil : URL(string: "http://127.0.0.1:\(port)/\(path)")
    }

    private func serve(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16 * 1024) { [root] data, _, _, _ in
            let request = data.map { String(decoding: $0, as: UTF8.self) } ?? ""
            let response = Self.respond(to: request, root: root)
            connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
        }
    }

    static func respond(to request: String, root: URL?) -> Data {
        let lines = request.components(separatedBy: "\r\n")
        let parts = lines.first?.split(separator: " ") ?? []
        guard parts.count >= 2, parts[0] == "GET", let root,
              let path = String(parts[1]).removingPercentEncoding, !path.contains("..")
        else { return head(400, length: 0, type: "text/plain") }
        let file = root.appending(path: String(path.dropFirst()))
        guard let body = try? Data(contentsOf: file, options: .mappedIfSafe) else { return head(404, length: 0, type: "text/plain") }

        let type = switch file.pathExtension {
        case "m3u8": "application/vnd.apple.mpegurl"
        case "ts": "video/mp2t"
        case "mp4", "m4s": "video/mp4"
        default: "application/octet-stream"
        }
        // "Range: bytes=a-b" / "bytes=a-"
        if let range = lines.first(where: { $0.lowercased().hasPrefix("range: bytes=") }) {
            let spec = range.dropFirst("range: bytes=".count).split(separator: "-", omittingEmptySubsequences: false)
            let start = Int(spec.first ?? "") ?? 0
            let end = min(Int(spec.count > 1 ? spec[1] : "") ?? body.count - 1, body.count - 1)
            if start <= end {
                var out = head(206, length: end - start + 1, type: type, extra: "Content-Range: bytes \(start)-\(end)/\(body.count)\r\n")
                out.append(body[start...end])
                return out
            }
        }
        var out = head(200, length: body.count, type: type)
        out.append(body)
        return out
    }

    private static func head(_ status: Int, length: Int, type: String, extra: String = "") -> Data {
        let reason = [200: "OK", 206: "Partial Content", 400: "Bad Request", 404: "Not Found"][status] ?? ""
        return Data("HTTP/1.1 \(status) \(reason)\r\nContent-Type: \(type)\r\nContent-Length: \(length)\r\nAccept-Ranges: bytes\r\nConnection: close\r\n\r\n".utf8)
    }
}
