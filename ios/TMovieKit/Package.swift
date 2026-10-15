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
        .target(name: "PlayerFeature", dependencies: ["Models", "Networking", "Persistence", "DesignSystem", "VoiceOver"]),
        .target(name: "FilmUI", dependencies: ["Models", "Networking", "Persistence", "DesignSystem", "AppRouter", "PlayerFeature"]),

        // "Thuyết minh AI" (private core): VieNeu-TTS Nano on ONNX Runtime + the sea-g2p phonemizer.
        .binaryTarget(
            name: "onnxruntime",
            url: "https://download.onnxruntime.ai/pod-archive-onnxruntime-c-1.24.2.zip",
            checksum: "f7100a992d2a8135168c8afd831e6a58b465349101982aa58b3e11d36e600b54"
        ),
        .binaryTarget(name: "SeaG2P", path: "Vendor/SeaG2P.xcframework"),  // private/ios/Tools/build-seag2p.sh
        .target(name: "NanoRuntime", dependencies: ["onnxruntime"], linkerSettings: [.linkedLibrary("c++")]),
        .target(name: "VoiceOver", dependencies: ["NanoRuntime", "SeaG2P"], resources: [.copy("Resources/nano_voices.json")]),

        // Features
        .target(name: "HomeFeature", dependencies: featureDeps),
        .target(name: "DetailFeature", dependencies: featureDeps),
        .target(name: "BrowseFeature", dependencies: featureDeps),
        .target(name: "ProfileFeature", dependencies: featureDeps),
        .target(name: "OnboardingFeature", dependencies: ["Models", "Networking", "DesignSystem"]),

        .testTarget(name: "TMovieKitTests", dependencies: ["Models", "Networking"], resources: [.copy("Fixtures")]),
    ]
)
