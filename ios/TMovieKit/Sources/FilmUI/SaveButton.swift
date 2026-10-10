import DesignSystem
import Models
import Persistence
import SwiftData
import SwiftUI

/// "+ Danh sách" ↔ "✓ Danh sách", backed by SwiftData so every copy on screen updates together.
public struct SaveButton: View {
    public enum Style { case column, wide, circle }

    let film: FilmItem
    let style: Style
    @Query private var saved: [SavedFilm]

    public init(film: FilmItem, style: Style = .column) {
        self.film = film
        self.style = style
        let slug = film.slug
        _saved = Query(filter: #Predicate<SavedFilm> { $0.slug == slug })
    }

    private var isSaved: Bool { !saved.isEmpty }

    public var body: some View {
        Button { Library.toggleSaved(film) } label: {
            switch style {
            case .column:
                VStack(spacing: 6) {
                    icon.font(.title3.weight(.semibold))
                    Text("Danh sách").font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }
                .frame(minWidth: 64, minHeight: 48)
            case .wide:
                Label { Text("Danh sách") } icon: { icon }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .glassSurface(in: .rect(cornerRadius: 8), interactive: true)
            case .circle:
                icon.font(.title3.weight(.semibold))
                    .frame(width: 50, height: 50)
                    .glassSurface(in: .circle, interactive: true)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isSaved)
        .accessibilityLabel(isSaved ? "Bỏ khỏi danh sách" : "Thêm vào danh sách")
    }

    private var icon: some View {
        Image(systemName: isSaved ? "checkmark" : "plus")
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.bounce, value: isSaved)
    }
}
