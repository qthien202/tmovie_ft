# Architecture

## Monorepo Structure

TMovie sử dụng **Melos 7.x** để quản lý monorepo với **Dart Pub Workspaces**.

```
tmovie_ft/
├── pubspec.yaml              # Workspace root + Melos config
├── apps/
│   ├── mobile/               # Mobile app (iOS + Android)
│   └── tv/                   # Android TV app (Leanback)
└── packages/
    └── core/                 # Shared library
```

## Tech Stack

| Concern            | Package                                  |
|--------------------|------------------------------------------|
| State Management   | `flutter_riverpod`                       |
| Networking         | `dio` + `retrofit` + `retrofit_generator`|
| Models             | `json_annotation` + `json_serializable`  |
| Navigation         | `go_router`                              |
| Monorepo           | `melos` 7.x (pub workspaces)            |
| Video              | `video_player` + `chewie`                |
| Image              | `cached_network_image`                   |
| Local Storage      | `shared_preferences`                     |

## Core Package (`packages/core/`)

Shared library chứa tất cả logic dùng chung giữa mobile và TV:

- **constants/** - API URLs, film types, home categories
- **theme/** - AppColors, AppTheme (dark theme)
- **models/** - json_serializable models matching OPhim V1 API
- **network/** - Dio factory + Retrofit ApiService
- **repositories/** - FilmRepository, HistoryRepository (abstract + impl)
- **providers/** - Riverpod providers (singleton + family auto-dispose)
- **widgets/** - AppImage, FilmCard, FilmGrid, PaginationBar, ShimmerLoading

## Mobile App (`apps/mobile/`)

Feature-based architecture:

- **router/** - GoRouter config với ShellRoute cho bottom navigation
- **shell/** - MainShell (GNav bottom navigation bar)
- **features/**
  - `splash/` - Splash screen (2s delay)
  - `home/` - TabBar theo film types + Carousel + Film Grid
  - `search/` - Debounced search với pagination
  - `detail/` - Film info + Episode selector
  - `player/` - Chewie video player (landscape, immersive)
  - `film_list/` - Paginated film list theo type
  - `genre/` - Paginated films theo genre

## TV App (`apps/tv/`)

Android TV với D-pad navigation (Focus system):

- Leanback launcher (AndroidManifest)
- Left sidebar navigation (film types + search)
- Grid layout với focus animation (scale + border highlight)
- Fullscreen video player

## Pattern: Repository + Provider

```
ApiService (Retrofit) → FilmRepository → Riverpod Provider → UI (ConsumerWidget)
```

- **ApiService**: Retrofit interface, auto-generated HTTP client
- **FilmRepository**: Abstract interface, decouples UI from network implementation
- **Riverpod Provider**: FutureProvider.family.autoDispose cho data fetching
- **UI**: ConsumerWidget/ConsumerStatefulWidget watches providers
