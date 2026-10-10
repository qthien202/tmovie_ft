import Foundation

/// TMDB image from `/phim/{slug}/images`.
public struct FilmImage: Codable, Hashable, Sendable {
    public let width: Int?
    public let height: Int?
    public let aspectRatio: Double?
    public let type: String?  // "backdrop" | "poster"
    public let filePath: String?
    public let iso6391: String?

    public func url(size: String = "w780") -> URL? { tmdbImageURL(filePath, size: size) }
}

/// Cast member from `/phim/{slug}/peoples`.
public struct FilmPerson: Codable, Hashable, Sendable {
    public let tmdbPeopleId: Int?
    public let name: String?
    public let originalName: String?
    public let character: String?
    public let knownForDepartment: String?
    public let profilePath: String?
    public let gender: Int?
    public let genderName: String?

    public func profileURL(size: String = "w185") -> URL? { tmdbImageURL(profilePath, size: size) }
}

/// TMDB `/tv/{id}/season/{n}` episode, used for per-episode stills.
public struct TmdbEpisode: Codable, Hashable, Sendable {
    public let id: Int?
    public let name: String?
    public let overview: String?
    public let episodeNumber: Int?
    public let seasonNumber: Int?
    public let stillPath: String?
    public let airDate: String?
    public let voteAverage: Double?
    public let runtime: Int?

    public func stillURL(size: String = "w300") -> URL? { tmdbImageURL(stillPath, size: size) }
}
