import ProjectDescription

let project = Project(
    name: "TMovie",
    packages: [.local(path: "TMovieKit")],
    settings: .settings(base: [
        "DEVELOPMENT_TEAM": "FABGKHLB8G",  // Personal Team only, never a company team
        "CODE_SIGN_STYLE": "Automatic",
        "SWIFT_VERSION": "6.0",
        "TARGETED_DEVICE_FAMILY": "1",
    ]),
    targets: [
        .target(
            name: "TMovie",
            destinations: [.iPhone],
            product: .app,
            bundleId: "io.pebblecove.vista",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "TMovie",
                "UILaunchScreen": [:],
                // Portrait at runtime (AppDelegate); landscape is listed so the player can rotate.
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
                "UIBackgroundModes": ["audio"],
                // Downloaded episodes are served to AVPlayer from http://127.0.0.1 (LocalHLSServer).
                "NSAppTransportSecurity": ["NSAllowsLocalNetworking": true],
                "CFBundleURLTypes": [["CFBundleURLSchemes": ["tmovie"]]],  // tmovie://phim/{slug}  // AVKit PiP / background audio in phase 2
            ]),
            sources: ["App/Sources/**"],
            resources: [
                "App/Resources/**",
                // "Thuyết minh AI" voice model, ~345 MB (private/ios/Tools/fetch-vieneu.sh).
                .folderReference(path: "TMovieKit/Vendor/VieNeu"),
            ],
            dependencies: [.package(product: "TMovieKit")]
        ),
    ]
)
