import AppRouter
import BrowseFeature
import DetailFeature
import SwiftUI

extension View {
    /// Registers every pushable screen on a tab's NavigationStack and gives it a zoom namespace.
    /// Features only push `FilmRoute` / `ListRoute` values, so they never import each other.
    func withAppDestinations() -> some View { modifier(AppDestinations()) }
}

private struct AppDestinations: ViewModifier {
    @Namespace private var zoom

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: FilmRoute.self) { route in
                DetailView(route: route)
                    .zoomDestination(id: route.sourceID, in: zoom)
                    .environment(\.zoomNamespace, zoom)
            }
            .navigationDestination(for: ListRoute.self) { route in
                CatalogView(route: route).environment(\.zoomNamespace, zoom)
            }
            .environment(\.zoomNamespace, zoom)
    }
}
