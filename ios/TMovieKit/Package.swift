// swift-tools-version: 6.0
import PackageDescription

// Layered modules: foundation (Models → Networking/Persistence, DesignSystem, AppRouter),
// shared UI (FilmUI, PlayerFeature), then one module per feature. The app target only
// composes features and registers navigation destinations.
let featureDeps: [Target.Dependency] = [
    "Models", "Networking", "Persistence", "DesignSystem", "AppRouter", "FilmUI", "PlayerFeature",
]

let package = Package(
    name: "TMovieKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TMovieKit", targets: [
            "Models", "Networking", "Persistence", "DesignSystem", "AppRouter", "FilmUI", "PlayerFeature",
            "HomeFeature", "DetailFeature", "BrowseFeature", "ProfileFeature", "OnboardingFeature",
        ]),
    ],
    targets: [
        // Foundation
        .target(name: "Models"),
        .target(name: "Networking", dependencies: ["Models"]),
        .target(name: "Persistence", dependencies: ["Models"]),
        .target(name: "DesignSystem"),
        .target(name: "AppRouter", dependencies: ["Models", "Networking"]),

        // Shared UI
        .target(name: "PlayerFeature", dependencies: ["Models", "Networking", "Persistence", "DesignSystem"]),
        .target(name: "FilmUI", dependencies: ["Models", "Networking", "Persistence", "DesignSystem", "AppRouter", "PlayerFeature"]),

        // Features
        .target(name: "HomeFeature", dependencies: featureDeps),
        .target(name: "DetailFeature", dependencies: featureDeps),
        .target(name: "BrowseFeature", dependencies: featureDeps),
        .target(name: "ProfileFeature", dependencies: featureDeps),
        .target(name: "OnboardingFeature", dependencies: ["Models", "Networking", "DesignSystem"]),

        .testTarget(name: "TMovieKitTests", dependencies: ["Models", "Networking"], resources: [.copy("Fixtures")]),
    ]
)
