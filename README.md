# <img src="apps/mobile/assets/app_icon.png" width="40" vertical-align="middle"> TMovie - Premium Cinema Experience

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-02569B?style=for-the-badge&logo=riverpod&logoColor=white)](https://riverpod.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**TMovie** is a high-end online movie streaming application, delivering a premium cinema experience directly to your mobile devices (iOS/Android) and Android TV. Built with a modern, smooth design philosophy centered around the user.

---

## ✨ Premium Features

- 🎨 **Glassmorphism UI**: Modern design with luxury frosted glass effects, providing a high-end and sophisticated feel.
- 🎬 **Cinematic Video Player**: 100% custom controller, supporting 10s seek, episode selection, and server switching directly while watching.
- 🔗 **Cloud Sync**: One-tap Google Sign-In to save watch history and favorite movie lists across all devices via Firestore.
- ⚡ **Exceptional Performance**: Built on Flutter with Riverpod State Management for instant response speeds.
- 📺 **Multi-platform Support**: Unified experience from compact mobile screens to sharp 4K TV displays.

---

## 📸 Screenshots

| <img src="screenshots/onboarding.png" width="220" /><br><sub><b>Onboarding</b></sub> | <img src="screenshots/login.png" width="220" /><br><sub><b>Google Login</b></sub> | <img src="screenshots/home.png" width="220" /><br><sub><b>Home Screen</b></sub> |
| :---: | :---: | :---: |
| <img src="screenshots/search.png" width="220" /><br><sub><b>Search & Filter</b></sub> | <img src="screenshots/detail_info.png" width="220" /><br><sub><b>Movie Info</b></sub> | <img src="screenshots/detail_cast.png" width="220" /><br><sub><b>Cast & Crew</b></sub> |
| <img src="screenshots/detail_episodes.png" width="220" /><br><sub><b>Episodes List</b></sub> | | |

---

## 🛠 Tech Stack

| App Layer | Technology |
| :--- | :--- |
| **State Management** | `flutter_riverpod` (v2.6+) |
| **Networking** | `dio` + `retrofit` |
| **Navigation** | `go_router` |
| **Video Engine** | `video_player` + `chewie` (Customized) |
| **Backend** | `Firebase Auth` + `Cloud Firestore` |
| **Monorepo** | `Melos` |

---

## 📂 Project Structure

```text
tmovie_ft/
├── apps/
│   ├── mobile/          # 📱 iOS & Android Application
│   └── tv/              # 📺 Android TV Application (Leanback)
├── packages/
│   └── core/            # 📦 Shared: models, API, providers, widgets
└── screenshots/         # 🖼 App Screenshot Gallery
```

---

## 🚀 Getting Started

### System Requirements
- Flutter SDK >= 3.38.0
- Dart SDK >= 3.8.0
- Melos (`dart pub global activate melos`)

### Setup Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/qthien202/tmovie_ft.git
   cd tmovie_ft
   ```

2. **Initialize dependencies:**
   ```bash
   melos bootstrap
   ```

3. **Auto-generate code (Models/Retrofit):**
   ```bash
   melos run build_runner
   ```

4. **Run the application:**
   ```bash
   # Mobile
   cd apps/mobile && flutter run

   # TV
   cd apps/tv && flutter run
   ```

---

## 📖 Documentation
- 🏗 [System Architecture](docs/architecture.md)
- 🔌 [API Details (OPhim)](docs/api.md)
- 📝 [Feature List](docs/features.md)

---

<p align="center">
  Made with ❤️ by <b>TMovie Team</b>
</p>
