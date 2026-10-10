import Foundation

/// `/phim/{slug}` → `data.item`.
public struct FilmDetail: Codable, Hashable, Sendable, Identifiable {
    public var id: String { slug }
    public let name: String
    public let slug: String
    public let originName: String?
    public let content: String?
    public let type: String?
    public let status: String?
    public let thumbUrl: String?
    public let posterUrl: String?
    public let trailerUrl: String?
    public let time: String?
    public let episodeCurrent: String?
    public let episodeTotal: LooseString?
    public let quality: String?
    public let lang: String?
    public let year: Int?
    public let view: Int?
    public let actor: [String]?
    public let director: [String]?
    public let category: [FilmCategory]?
    public let country: [FilmCountry]?
    public let episodes: [Episode]?
    public let tmdb: TmdbInfo?
    public let imdb: ImdbInfo?

    public var thumbURL: URL? { phimImageURL(thumbUrl) }
    public var posterURL: URL? { phimImageURL(posterUrl) }
}

extension FilmItem {
    /// The list-item view of a detail, for saving to My List / history and for routing.
    public init(_ d: FilmDetail) {
        self.init(name: d.name, slug: d.slug, originName: d.originName, type: d.type, thumbUrl: d.thumbUrl,
                  posterUrl: d.posterUrl, subDocquyen: nil, chieurap: nil, time: d.time, episodeCurrent: d.episodeCurrent,
                  quality: d.quality, lang: d.lang, year: d.year, category: d.category, country: d.country, tmdb: d.tmdb, imdb: d.imdb)
    }
}

/// One server (Vietsub, Thuyết minh, ...) with its episode list.
public struct Episode: Codable, Hashable, Sendable {
    public let serverName: String?
    public let serverData: [ServerData]?
}

public struct ServerData: Codable, Hashable, Sendable {
    public let name: String?
    public let slug: String?
    public let filename: String?
    public let linkEmbed: String?
    public let linkM3U8: String?

    /// HLS only. `link_embed` is a web page AVPlayer cannot play (the Flutter player failed on it too).
    public var streamURL: URL? {
        linkM3U8.flatMap { $0.isEmpty ? nil : URL(string: $0) }
    }
}
