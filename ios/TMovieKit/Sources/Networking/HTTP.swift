import Foundation

extension JSONDecoder {
    /// The decoder every PhimAPI / TMDB model expects.
    public static let api: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()
}

extension URLSession {
    func data(checked request: URLRequest) async throws -> Data {
        var request = request
        request.timeoutInterval = 30
        let (data, response) = try await data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw APIError.http(status) }
        return data
    }

    func json<T: Decodable>(_ url: URL) async throws -> T {
        try JSONDecoder.api.decode(T.self, from: await data(checked: URLRequest(url: url)))
    }
}
