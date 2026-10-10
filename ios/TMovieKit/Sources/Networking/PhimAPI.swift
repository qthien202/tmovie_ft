import Foundation
import Models

public enum APIError: Error, Equatable {
    case http(Int)
}

/// Port of `ApiService` (retrofit) for https://phimapi.com/v1/api.
public struct PhimAPI: Sendable {
    public static let shared = PhimAPI()

    /// Paginated list sources, same as Flutter's `PaginatedSource`.
    public enum Source: Hashable, Sendable {
        case type(String)     // /danh-sach/{slug}: phim-moi-cap-nhat, phim-bo, phim-le, ...
        case genre(String)    // /the-loai/{slug}
        case country(String)  // /quoc-gia/{slug}
        case search(String)   // /tim-kiem?keyword=
    }

    public struct Filter: Hashable, Sendable {
        public var category: String?
        public var country: String?
        public var year: Int?
        public var sortField: String?
        public init(category: String? = nil, country: String? = nil, year: Int? = nil, sortField: String? = nil) {
            self.category = category; self.country = country; self.year = year; self.sortField = sortField
        }
    }

    let baseURL: URL
    let session: URLSession

    public init(baseURL: URL = URL(string: "https://phimapi.com/v1/api")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func list(_ source: Source, page: Int = 1, filter: Filter = .init()) async throws -> FilmPage {
        // "Sắp chiếu" is all trailers by definition, so only that list keeps them.
        try Self.page(from: await session.json(listURL(source, page: page, filter: filter)), keepTrailers: source == .type("phim-sap-chieu"))
    }

    public func detail(slug: String) async throws -> FilmDetail {
        let res: Envelope<DetailData> = try await session.json(baseURL.appending(path: "phim/\(slug)"))
        return res.data.item
    }

    public func images(slug: String) async throws -> [FilmImage] {
        let res: Envelope<ImagesData> = try await session.json(baseURL.appending(path: "phim/\(slug)/images"))
        return res.data.images ?? []
    }

    public func peoples(slug: String) async throws -> [FilmPerson] {
        let res: Envelope<PeoplesData> = try await session.json(baseURL.appending(path: "phim/\(slug)/peoples"))
        return res.data.peoples ?? []
    }

    /// All genres (`/the-loai`) or countries (`/quoc-gia`). These live at the site root, not under /v1/api.
    public func taxonomy(_ kind: Taxonomy) async throws -> [FilmCategory] {
        let root = baseURL.deletingLastPathComponent().deletingLastPathComponent()
        let res: Envelope<TaxonomyData> = try await session.json(root.appending(path: kind.rawValue))
        return res.data.items.filter { !FilmCategory.adultSlugs.contains($0.slug ?? "") }
    }

    public enum Taxonomy: String, Sendable { case genres = "the-loai", countries = "quoc-gia" }

    func listURL(_ source: Source, page: Int, filter: Filter) -> URL {
        var query = [URLQueryItem(name: "page", value: String(page))]
        let path: String
        switch source {
        case .type(let slug): path = "danh-sach/\(slug)"
        case .genre(let slug): path = "the-loai/\(slug)"
        case .country(let slug): path = "quoc-gia/\(slug)"
        case .search(let keyword):
            path = "tim-kiem"
            query.append(URLQueryItem(name: "keyword", value: keyword))
        }
        let filters: [(String, String?)] = [
            ("category", filter.category), ("country", filter.country),
            ("year", filter.year.map(String.init)), ("sort_field", filter.sortField),
        ]
        query += filters.compactMap { name, value in value.map { URLQueryItem(name: name, value: $0) } }
        return baseURL.appending(path: path).appending(queryItems: query)
    }

    static func page(from res: Envelope<ListData>, keepTrailers: Bool = false) -> FilmPage {
        let p = res.data.params?.pagination
        let perPage = p?.totalItemsPerPage ?? 0
        let computed = perPage > 0 ? ((p?.totalItems ?? 0) + perPage - 1) / perPage : 0
        return FilmPage(
            items: res.data.items.filter { !$0.isAdult && (keepTrailers || !$0.isTrailer) },
            currentPage: p?.currentPage ?? 1,
            totalPages: p?.totalPages ?? computed
        )
    }

    struct Envelope<T: Decodable>: Decodable { let data: T }
    struct ListData: Decodable {
        let items: [FilmItem]
        let params: Params?
        struct Params: Decodable { let pagination: Pagination? }
        struct Pagination: Decodable {
            let totalItems: Int?, totalItemsPerPage: Int?, currentPage: Int?, totalPages: Int?
        }
    }
    struct DetailData: Decodable { let item: FilmDetail }
    struct TaxonomyData: Decodable { let items: [FilmCategory] }
    struct ImagesData: Decodable { let images: [FilmImage]? }
    struct PeoplesData: Decodable { let peoples: [FilmPerson]? }
}

/// One page of a list endpoint, with adult/trailer-only entries removed.
public struct FilmPage: Hashable, Sendable {
    public let items: [FilmItem]
    public let currentPage: Int
    public let totalPages: Int
    public var hasMore: Bool { currentPage < totalPages }
}
