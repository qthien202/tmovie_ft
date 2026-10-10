import Foundation
import Models

/// Port of `TmdbService`: per-episode stills for the detail page's episode rail.
public struct TMDBAPI: Sendable {
    let apiKey: String
    let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func seasonEpisodes(tmdbID: String, season: Int) async throws -> [TmdbEpisode] {
        struct Season: Decodable { let episodes: [TmdbEpisode]? }
        let url = URL(string: "https://api.themoviedb.org/3/tv/\(tmdbID)/season/\(season)")!
            .appending(queryItems: [URLQueryItem(name: "api_key", value: apiKey), URLQueryItem(name: "language", value: "vi-VN")])
        let res: Season = try await session.json(url)
        return res.episodes ?? []
    }
}
