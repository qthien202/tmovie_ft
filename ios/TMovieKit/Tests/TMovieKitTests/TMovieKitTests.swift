import Foundation
import Testing
@testable import Models
@testable import Networking

/// Fixtures recorded from https://phimapi.com/v1/api on 2026-10-10.
private func fixture<T: Decodable>(_ name: String, as type: T.Type = T.self) throws -> T {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try JSONDecoder.api.decode(T.self, from: Data(contentsOf: url))
}

@Test func homeListDecodes() throws {
    let page = PhimAPI.page(from: try fixture("list"))
    #expect(page.items.count > 20)
    #expect(page.currentPage == 1)
    #expect(page.totalPages > 1000)
    #expect(page.hasMore)
    let first = try #require(page.items.first)
    #expect(!first.slug.isEmpty && !first.name.isEmpty)
    #expect(first.thumbURL?.host() == "phimimg.com")
}

@Test func searchDecodes() throws {
    let page = PhimAPI.page(from: try fixture("search"))
    #expect(!page.items.isEmpty)
}

@Test func detailDecodes() throws {
    let detail = try fixture("detail", as: PhimAPI.Envelope<PhimAPI.DetailData>.self).data.item
    #expect(detail.slug == "nguoi-tinh-mang-mat-na-phan-1")
    #expect(detail.episodeTotal?.value == "24")  // sent as a number
    #expect(detail.tmdb?.id?.value == "336183")
    let ep = try #require(detail.episodes?.first?.serverData?.first)
    #expect(ep.linkM3U8?.hasSuffix(".m3u8") == true)
    #expect(detail.content?.isEmpty == false)
}

@Test func imagesAndPeoplesDecode() throws {
    let images = try fixture("images", as: PhimAPI.Envelope<PhimAPI.ImagesData>.self).data.images ?? []
    #expect(images.first?.url()?.absoluteString.hasPrefix("https://image.tmdb.org/t/p/w780/") == true)
    let people = try fixture("peoples", as: PhimAPI.Envelope<PhimAPI.PeoplesData>.self).data.peoples ?? []
    #expect(people.first?.name == "Wang Ruichang")
    #expect(people.first?.profileURL() != nil)
}

@Test func imageURLRules() {
    #expect(phimImageURL("upload/vod/a.jpg")?.absoluteString == "https://phimimg.com/upload/vod/a.jpg")
    #expect(phimImageURL("/uploads/movies/a.jpg")?.absoluteString == "https://phimimg.com/uploads/movies/a.jpg")
    #expect(phimImageURL("a-thumb.jpg")?.absoluteString == "https://phimimg.com/uploads/movies/a-thumb.jpg")
    #expect(phimImageURL("https://x.com/a.jpg")?.absoluteString == "https://x.com/a.jpg")
    #expect(phimImageURL("") == nil)
}

@Test func listURLs() {
    let api = PhimAPI()
    #expect(api.listURL(.type("phim-bo"), page: 2, filter: .init(country: "han-quoc", year: 2026)).absoluteString
        == "https://phimapi.com/v1/api/danh-sach/phim-bo?page=2&country=han-quoc&year=2026")
    #expect(api.listURL(.search("tình yêu"), page: 1, filter: .init()).absoluteString
        == "https://phimapi.com/v1/api/tim-kiem?page=1&keyword=t%C3%ACnh%20y%C3%AAu")
}

@Test func hidesAdultAndTrailers() throws {
    let json = """
    {"data":{"items":[
      {"name":"A","slug":"a","category":[{"slug":"18-plus"}]},
      {"name":"B","slug":"b","episode_current":"Trailer"},
      {"name":"C","slug":"c"}
    ],"params":{"pagination":{"totalItems":49,"totalItemsPerPage":24,"currentPage":1}}}}
    """
    let page = PhimAPI.page(from: try JSONDecoder.api.decode(PhimAPI.Envelope<PhimAPI.ListData>.self, from: Data(json.utf8)))
    #expect(page.items.map(\.slug) == ["c"])
    let upcoming = PhimAPI.page(from: try JSONDecoder.api.decode(PhimAPI.Envelope<PhimAPI.ListData>.self, from: Data(json.utf8)), keepTrailers: true)
    #expect(upcoming.items.map(\.slug) == ["b", "c"])
    #expect(page.totalPages == 3)  // computed when the API omits it
}

@Test func traktParsesAndMerges() {
    // Hand-written in Trakt v2's shape: the bundled client id now returns 403, so nothing to record.
    let json = """
    [{"watchers":9,"show":{"title":"K1","year":2026,"language":"ko","genres":["drama"]}},
     {"watchers":8,"show":{"title":"Anime","year":2026,"language":"ja","genres":["anime"]}},
     {"watchers":7,"movie":{"title":"","language":"en"}},
     {"watchers":6,"movie":{"title":"M1","year":2025,"language":"en"}}]
    """
    let titles = TraktAPI.titles(from: Data(json.utf8))
    #expect(titles.map(\.name) == ["K1", "M1"])
    let k = TraktTitle(name: "K", language: "ko", year: nil), z = TraktTitle(name: "Z", language: "zh", year: nil)
    let merged = TraktAPI.merge(ko: [k, k], zh: [z], global: titles)
    #expect(merged.map(\.name) == ["K", "Z", "K", "M1"])  // interleaved Asia first, ko/zh dropped from the tail
}

@Test func genresDecodeAndFilmItemFromDetail() throws {
    let genres = try fixture("genres", as: PhimAPI.Envelope<PhimAPI.TaxonomyData>.self).data.items
    #expect(genres.contains { $0.slug == "hanh-dong" })
    let detail = try fixture("detail", as: PhimAPI.Envelope<PhimAPI.DetailData>.self).data.item
    let item = FilmItem(detail)
    #expect(item.slug == detail.slug && item.thumbURL == detail.thumbURL)
}
