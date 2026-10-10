# TMovie iOS — SwiftUI port

Native iPhone port of `apps/mobile` (Flutter) with a **new UI**. Personal use, signed with the Personal Team.

## Decisions (accepted 2026-10-10)

- **Platform:** iPhone only. tvOS later, reusing the core package.
- **Minimum iOS 17:** `@Observable`, SwiftData, `NavigationStack`, `PhaseAnimator`/`KeyframeAnimator`.
- **Design:** Apple TV app style, more premium. **Liquid Glass** (iOS 26 `glassEffect`, `GlassEffectContainer`) with an iOS 17 fallback (`.ultraThinMaterial`), plus lots of motion. Build with the local skills: `swiftui-liquid-glass`, `ios-app-beauty`, `swiftui-expert-skill`, `swiftui-ui-patterns`.
- **Location:** `tmovie_ft/ios/`, next to the Flutter workspace.
- **Dependencies:** Apple frameworks only, except the Firebase iOS SDK (Auth, Firestore) and Google Sign-In, both via SPM.

## Flutter → SwiftUI

| Flutter | SwiftUI |
| --- | --- |
| chewie | AVKit (`AVPlayerViewController`: PiP, AirPlay, subtitles) |
| dio + retrofit + json_serializable | URLSession + async/await + Codable |
| go_router | NavigationStack + typed routes |
| flutter_riverpod | `@Observable` stores |
| drift | SwiftData (favourites, history, resume position) |
| cached_network_image | AsyncImage + small `NSCache` image loader |
| carousel_slider / google_nav_bar | `TabView(.page)` / `TabView` with a glass tab bar |
| flutter_widget_from_html | `AttributedString(html:)` |
| connectivity_plus / package_info_plus | `NWPathMonitor` / `Bundle.main` |

## Screens (from `apps/mobile/lib/src/features`)

splash · onboarding · login · home (cinematic hero, category rails, tabs) · catalog + catalog tabs · genre · detail (film info, episode rail) · player · profile · favourites · history · update dialog. Main shell = tab bar.

## Data (from `packages/core`)

- PhimAPI `https://phimapi.com`: `/danh-sach/{type_slug}`, `/phim/{slug}` (+ `/images`, `/peoples`), `/the-loai/{slug}`, `/quoc-gia/{slug}`, `/tim-kiem`. Images: `https://phimimg.com/`.
- TMDB `https://api.themoviedb.org/3`, Trakt `https://api.trakt.tv` (`/movies/trending`, `/shows/trending`).
- Read `packages/core/lib/src/{models,network,repositories}` before writing models. Key handling follows the Flutter app.

## Motion

Poster → detail hero (`matchedGeometryEffect` / `navigationTransition(.zoom)` on iOS 18+), parallax and blur on the home hero tied to scroll, staggered rail entrances, glass morphing tab bar, `symbolEffect` on buttons, and the player chrome fading on idle. Respect Reduce Motion.

## Phases

| # | Scope | Done when |
| --- | --- | --- |
| 1 | Xcode project (Tuist or SwiftPM app), core package: models + API client + tests against recorded JSON | `swift test` green; home JSON decodes |
| 2 | Shell + home (hero, rails) + detail + player | Plays an episode on device; hero transition works |
| 3 | Catalog, genre, search | Every list paginates |
| 4 | SwiftData favourites, history, resume | Resume continues at the saved second |
| 5 | Firebase login + sync, profile, onboarding, splash, update check | Login on device with the Personal Team |
| 6 | Motion and Liquid Glass polish pass | Reviewed on device, Reduce Motion respected |

Distribution note: the content comes from a third-party aggregator API. That is fine for personal sideloading, but the App Store or public TestFlight would need licensed sources.

## Architecture (modular SPM, IceCubes-style)

```
ios/
├── Project.swift, Tuist.swift      # tuist generate → TMovie.xcworkspace (gitignored)
├── App/Sources/                    # thin app target
│   ├── TMovieApp.swift             # @main, AppDelegate (orientation)
│   ├── RootView.swift              # splash → onboarding → tabs, deep link tmovie://phim/{slug}
│   └── AppDestinations.swift       # registers DetailView / CatalogView + zoom namespace per stack
└── TMovieKit/                      # local Swift package, one module per folder
    ├── Sources/
    │   ├── Models/                 # Codable PhimAPI/TMDB models, image URL rules
    │   ├── Networking/             # PhimAPI, TraktAPI, TMDBAPI, Pager
    │   ├── Persistence/            # SwiftData: SavedFilm, WatchRecord, Library
    │   ├── DesignSystem/           # tokens, glassSurface, RemoteImage, buttons, Wordmark
    │   ├── AppRouter/              # FilmRoute, ListRoute, zoom source/destination
    │   ├── PlayerFeature/          # AVPlayerViewController player, resume, next episode, orientation
    │   ├── FilmUI/                 # shared film components: PosterCard, Shelf, PosterGrid, SaveButton, ...
    │   ├── HomeFeature/            # HomeView, HomeStore, Components/
    │   ├── DetailFeature/          # DetailView, Components/EpisodeList
    │   ├── BrowseFeature/          # CatalogView, SearchView, NewHotView
    │   ├── ProfileFeature/         # ProfileView
    │   └── OnboardingFeature/      # SplashView, OnboardingView, PosterWall
    └── Tests/TMovieKitTests/       # decoding + URL tests against recorded JSON
```

Features depend only on foundation + FilmUI and never on each other. They push `FilmRoute` / `ListRoute`, and the app target maps those to screens.
Run the tests with `cd TMovieKit && xcodebuild test -scheme TMovieKit -destination 'platform=iOS Simulator,name=iPhone 17'`.

## Progress

- **Phase 1 done (2026-10-10).** `TMovieKit/` (SwiftPM: `Models.swift`, `API.swift`, 8 tests against recorded PhimAPI JSON), Tuist app target `TMovie`, bundle ID `io.pebblecove.vista`, Personal Team `FABGKHLB8G`. Run `tuist generate` (the generated `.xcodeproj`/`.xcworkspace` are gitignored), then `cd TMovieKit && swift test`.
- Findings: the bundled Trakt client ID returns 403 and the TMDB key is invalid, so the Flutter hero silently falls back to "phim-moi-cap-nhat" and episode stills never load. New keys are needed before the hero work in phase 2. The Dart `fullThumbUrl` 404s on `upload/vod/...` paths; the Swift version fixes it.
- **Phase 2 built (2026-10-10), on device and awaiting a check:**
  - `App/Sources`: the tab shell (iOS 26 glass tab bar), and Home with an auto-advancing paged hero. The hero has stretch, parallax and blur, plus 8 staggered rails.
  - Detail has a parallax header, glass genre chips, an episode grid with a server picker, synopsis, cast and backdrops.
  - Poster → detail uses the zoom transition on iOS 18+.
  - The player is AVPlayerViewController presented full screen from UIKit, which rotates to landscape. A glass "Tập tiếp theo" button shows in the last 18s and the next episode auto-plays at the end. PiP restores.
  - The hero uses the Flutter "freshest" fallback until Trakt has a working client ID. The favourite button and resume wait for phase 4.
- **Phases 3–4 + Netflix redesign (2026-10-10):**
  - Tabs: Trang chủ / Mới & Hot / Của tôi / Tìm kiếm. On iOS 26 the search tab is its own glass button.
  - Home has an ambient colour wash, category pills, hero cards with Play/My List, and shelves for Continue Watching, My List, Top 10 and genres.
  - Detail has Play/Resume, synopsis, actions and cast, then Episodes / Similar / Images tabs. Long series are split into ranges of 50.
  - Catalog has filters for sort, year, genre and country. Search is debounced and also shows genre chips and top searches. New & Hot shows upcoming, airing and completed series.
  - Profile has history, My List and data reset. There is a splash animation and onboarding.
  - SwiftData stores My List, history and per-episode resume.
- Still open: Firebase login + sync (needs an iOS app registered in tmovie-1db06 for `io.pebblecove.vista`), the update dialog (not needed for sideloading), and an episode list inside the player.

- **Hero + category + icon (2026-10-10):**
  - The Home hero is now Apple TV style: full-bleed textless TMDB backdrops (w1280), paging parallax, Ken Burns drift, tilt depth (CoreMotion) and art-sampled tint. All motion is off with Reduce Motion.
  - The category page is Netflix style: a ✕ pill, a full-screen frosted genre picker, a featured card, shelves by country (or by genre on a country page), then an endless filtered grid.
  - Each tab has a `RouterPath` (`@Observable`).
  - Deep links: `tmovie://phim/{slug}` and `tmovie://the-loai/{slug}`.
  - The app icon is a "chromatic play" made by `Tools/make_icon.swift`.
