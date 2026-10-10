import Networking
import SwiftUI

/// Infinite 3-column poster grid fed by a `Pager`.
public struct PosterGrid: View {
    let pager: Pager
    let idPrefix: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    public init(pager: Pager, idPrefix: String) {
        self.pager = pager
        self.idPrefix = idPrefix
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(pager.items) { film in
                PosterCard(film: film, sourceID: "\(idPrefix)/\(film.slug)", width: nil)
                    .onAppear { if film.slug == pager.items.last?.slug { Task { await pager.loadMore() } } }
            }
        }
        .padding(.horizontal, 16)
        if pager.loading {
            ProgressView().frame(maxWidth: .infinity).padding()
        } else if pager.failed {
            Button("Thử lại") { Task { await pager.loadMore() } }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
}
