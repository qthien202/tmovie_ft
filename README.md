# TMovie

Ứng dụng xem phim online hỗ trợ **Mobile** (iOS/Android) và **Android TV**.

## Screenshots

<table width="100%">
  <tbody>
    <tr>
      <td width="1%"><img src="https://github.com/user-attachments/assets/386219d4-56bd-4eb8-bd85-76fffda7388d"/></td>
      <td width="1%"><img src="https://github.com/user-attachments/assets/05613dc3-f1e0-43ab-af07-5dead8661e9a"/></td>
       <td width="1%"><img src="https://github.com/user-attachments/assets/4ba8dcf9-4f92-4bd6-91c2-b37eb25a5507"/></td>
    </tr>
    <tr>
      <td width="1%"><img src="https://github.com/user-attachments/assets/3597f03e-3fc3-4183-82eb-4dba8cae101e"/></td>
      <td width="1%"><img src="https://github.com/user-attachments/assets/8b22f485-96e5-4d2f-bf8b-e559fa8d8a6c"/></td>
       <td width="1%"><img src="https://github.com/user-attachments/assets/eaa2ee0a-53e1-4181-846a-8c7d3825c2b8"/></td>
    </tr>
  </tbody>
</table>

## Tech Stack

| Concern          | Package                              |
|------------------|--------------------------------------|
| State Management | `flutter_riverpod`                   |
| Networking       | `dio` + `retrofit`                   |
| Navigation       | `go_router`                          |
| Monorepo         | `melos` 7.x (Dart Pub Workspaces)   |
| Video            | `video_player` + `chewie`            |
| Models           | `json_serializable`                  |

## Project Structure

```
tmovie_ft/
├── apps/
│   ├── mobile/          # iOS + Android app
│   └── tv/              # Android TV app (Leanback)
├── packages/
│   └── core/            # Shared: models, API, providers, widgets
└── docs/                # Documentation
```

## Getting Started

### Prerequisites

- Flutter SDK >= 3.38.0
- Dart SDK >= 3.8.0
- Melos (`dart pub global activate melos`)

### Setup

```bash
# Clone
git clone https://github.com/qthien202/tmovie_ft.git
cd tmovie_ft

# Bootstrap (resolve dependencies)
melos bootstrap

# Generate code (models, retrofit)
melos run build_runner

# Analyze
melos run analyze
```

### Run

```bash
# Mobile
cd apps/mobile
flutter run

# TV (Android TV emulator)
cd apps/tv
flutter run
```

## Documentation

- [Architecture](docs/architecture.md) - Project structure, patterns, tech stack
- [API](docs/api.md) - OPhim V1 API endpoints and response models
- [Features](docs/features.md) - Feature list for mobile and TV
