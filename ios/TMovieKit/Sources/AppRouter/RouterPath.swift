import Observation
import SwiftUI

/// One per tab's NavigationStack, injected through the environment, so any screen (or a sheet
/// presented from it) can push `FilmRoute` / `ListRoute` without owning navigation state.
@MainActor @Observable
public final class RouterPath {
    public var path = NavigationPath()

    public init() {}

    public func push(_ route: some Hashable) { path.append(route) }
}
