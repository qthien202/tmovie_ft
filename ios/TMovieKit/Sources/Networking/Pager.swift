import Models
import Observation

/// Page-by-page loader for grids and feeds. Stops after the last page.
@MainActor @Observable
public final class Pager {
    public private(set) var items: [FilmItem] = []
    public private(set) var loading = false
    public private(set) var failed = false
    private var page = 0
    private var hasMore = true
    private let api: PhimAPI

    public var source: PhimAPI.Source { didSet { if source != oldValue { reset() } } }
    public var filter = PhimAPI.Filter() { didSet { if filter != oldValue { reset() } } }
    /// Client-side filter for lists the API can't slice (e.g. airing vs completed series).
    @ObservationIgnored private let include: @Sendable (FilmItem) -> Bool

    public init(_ source: PhimAPI.Source, api: PhimAPI = .shared, include: @escaping @Sendable (FilmItem) -> Bool = { _ in true }) {
        self.source = source
        self.api = api
        self.include = include
    }

    public func loadMore() async {
        guard hasMore, !loading else { return }
        loading = true
        failed = false
        let (source, filter) = (self.source, self.filter)
        do {
            // Keep paging (up to 4 pages) until the client filter leaves enough to show.
            var added = 0
            for _ in 0..<4 where hasMore && added < 8 {
                let next = page + 1
                let result = try await api.list(source, page: next, filter: filter)
                guard source == self.source, filter == self.filter else { return }  // reset mid-flight
                var seen = Set(items.map(\.slug))
                let fresh = result.items.filter { include($0) && seen.insert($0.slug).inserted }
                items += fresh
                added += fresh.count
                page = next
                hasMore = result.hasMore
            }
        } catch {
            failed = !(error is CancellationError)
        }
        loading = false
    }

    private func reset() {
        items = []
        page = 0
        hasMore = true
        loading = false
        failed = false
    }
}
