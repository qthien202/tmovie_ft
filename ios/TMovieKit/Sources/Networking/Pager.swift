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

    public init(_ source: PhimAPI.Source, api: PhimAPI = .shared) {
        self.source = source
        self.api = api
    }

    public func loadMore() async {
        guard hasMore, !loading else { return }
        loading = true
        failed = false
        let (source, filter, next) = (self.source, self.filter, page + 1)
        do {
            let result = try await api.list(source, page: next, filter: filter)
            guard source == self.source, filter == self.filter else { return }  // reset mid-flight
            var seen = Set(items.map(\.slug))
            items += result.items.filter { seen.insert($0.slug).inserted }
            page = next
            hasMore = result.hasMore
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
