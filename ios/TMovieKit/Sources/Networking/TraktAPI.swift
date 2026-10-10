import Foundation

/// One hot title from Trakt, matched against PhimAPI by name + year for the home hero.
public struct TraktTitle: Hashable, Sendable {
    public let name: String
    public let language: String
    public let year: Int?
}

/// Port of `TraktService`: Korean/Chinese trending shows interleaved first, then a
/// Western tail of global shows + movies. Animation is excluded. Errors → empty list,
/// so the hero falls back to the freshest PhimAPI list.
public struct TraktAPI: Sendable {
    let clientID: String
    let session: URLSession

    public init(clientID: String, session: URLSession = .shared) {
        self.clientID = clientID
        self.session = session
    }

    public func trending() async -> [TraktTitle] {
        guard !clientID.isEmpty else { return [] }
        async let ko = fetch("shows", language: "ko")
        async let zh = fetch("shows", language: "zh")
        async let shows = fetch("shows")
        async let movies = fetch("movies")
        return await Self.merge(ko: ko, zh: zh, global: shows + movies)
    }

    static func merge(ko: [TraktTitle], zh: [TraktTitle], global: [TraktTitle]) -> [TraktTitle] {
        var asia: [TraktTitle] = []
        for i in 0..<max(ko.count, zh.count) {
            if i < ko.count { asia.append(ko[i]) }
            if i < zh.count { asia.append(zh[i]) }
        }
        return asia + global.filter { $0.language != "ko" && $0.language != "zh" }
    }

    private func fetch(_ kind: String, language: String? = nil) async -> [TraktTitle] {
        var query = [URLQueryItem(name: "extended", value: "full"), URLQueryItem(name: "limit", value: "25")]
        if let language { query.append(URLQueryItem(name: "languages", value: language)) }
        var request = URLRequest(url: URL(string: "https://api.trakt.tv/\(kind)/trending")!.appending(queryItems: query))
        request.setValue("2", forHTTPHeaderField: "trakt-api-version")
        request.setValue(clientID, forHTTPHeaderField: "trakt-api-key")
        guard let data = try? await session.data(checked: request) else { return [] }
        return Self.titles(from: data)
    }

    /// Decodes `[{ "show": {...} }]` or `[{ "movie": {...} }]`, dropping animation and untitled rows.
    static func titles(from data: Data) -> [TraktTitle] {
        struct Row: Decodable { let show: Node?; let movie: Node? }
        struct Node: Decodable { let title: String?; let language: String?; let year: Int?; let genres: [String]? }
        let rows = (try? JSONDecoder().decode([Row].self, from: data)) ?? []
        return rows.compactMap { row in
            guard let node = row.show ?? row.movie, let title = node.title, !title.isEmpty,
                  !(node.genres ?? []).contains(where: { ["anime", "animation"].contains($0.lowercased()) })
            else { return nil }
            return TraktTitle(name: title, language: node.language ?? "", year: node.year)
        }
    }
}
