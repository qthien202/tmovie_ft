import Models
import Networking
import SwiftUI

/// A film pushed onto a NavigationStack. `sourceID` keeps zoom sources unique when the
/// same film sits in the hero and in several rails at once.
public struct FilmRoute: Hashable, Sendable {
    public let film: FilmItem
    public let sourceID: String

    public init(film: FilmItem, sourceID: String) {
        self.film = film
        self.sourceID = sourceID
    }
}

/// A paginated grid: a type list, genre or country.
public struct ListRoute: Hashable, Sendable {
    public let title: String
    public let source: PhimAPI.Source

    public init(title: String, source: PhimAPI.Source) {
        self.title = title
        self.source = source
    }
}

extension EnvironmentValues {
    /// Set by the app per NavigationStack; posters zoom from it into detail.
    @Entry public var zoomNamespace: Namespace.ID?
}

extension View {
    /// Marks a view as the zoom source for `id` (iOS 18+; no-op before).
    public func zoomSource(id: String) -> some View { modifier(ZoomSource(id: id)) }

    /// The pushed view's side of the zoom transition (iOS 18+; plain push before).
    @ViewBuilder
    public func zoomDestination(id: String, in ns: Namespace.ID) -> some View {
        if #available(iOS 18, *) { navigationTransition(.zoom(sourceID: id, in: ns)) } else { self }
    }
}

private struct ZoomSource: ViewModifier {
    let id: String
    @Environment(\.zoomNamespace) private var ns

    func body(content: Content) -> some View {
        if #available(iOS 18, *), let ns { content.matchedTransitionSource(id: id, in: ns) } else { content }
    }
}
