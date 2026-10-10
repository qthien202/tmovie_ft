import Foundation

// PhimAPI models. Decoded with `JSONDecoder.api` (`.convertFromSnakeCase`), so property names
// are the camelCase of the JSON keys. Only fields the app reads.

public struct FilmCategory: Codable, Hashable, Sendable {
    public let id: String?
    public let name: String?
    public let slug: String?

    /// The "Phim 18+" genre, which the app never lists or shows.
    public static let adultSlugs: Set<String> = ["phim-18", "18-plus"]
}

public typealias FilmCountry = FilmCategory

public struct TmdbInfo: Codable, Hashable, Sendable {
    public let type: String?
    public let id: LooseString?
    public let season: Int?
    public let voteAverage: Double?
    public let voteCount: Int?
}

public struct ImdbInfo: Codable, Hashable, Sendable {
    public let id: LooseString?
    public let voteAverage: Double?
    public let voteCount: Int?
}

/// List item from `/danh-sach`, `/the-loai`, `/quoc-gia`, `/tim-kiem`.
public struct FilmItem: Codable, Hashable, Sendable, Identifiable {
    public var id: String { slug }
    public let name: String
    public let slug: String
    public let originName: String?
    public let type: String?
    public let thumbUrl: String?
    public let posterUrl: String?
    public let subDocquyen: Bool?
    public let chieurap: Bool?
    public let time: String?
    public let episodeCurrent: String?
    public let quality: String?
    public let lang: String?
    public let year: Int?
    public let category: [FilmCategory]?
    public let country: [FilmCountry]?
    public let tmdb: TmdbInfo?
    public let imdb: ImdbInfo?

    public var thumbURL: URL? { phimImageURL(thumbUrl) }
    public var posterURL: URL? { phimImageURL(posterUrl) }

    /// Hidden everywhere. PhimAPI tags these `phim-18` (OPhim used `18-plus`).
    public var isAdult: Bool { (category ?? []).contains { FilmCategory.adultSlugs.contains($0.slug ?? "") } }
    /// Trailer-only entries, hidden except in the "Sắp chiếu" list.
    public var isTrailer: Bool { episodeCurrent?.lowercased() == "trailer" }
}

extension FilmItem {
    /// Donghua/anime: excluded from the hero, like the Flutter app.
    public var isAnimation: Bool {
        type?.lowercased() == "hoathinh" || (category ?? []).contains {
            $0.slug == "hoat-hinh" || ($0.name ?? "").lowercased().contains("hoạt hình")
        }
    }
}
