# Changelog

English is the source of truth for the repo. Each version also carries a
Vietnamese block between `<!-- app:vi -->` ... `<!-- /app:vi -->` markers — the
release CI publishes THAT block as the GitHub release body, which the in-app
updater shows to users. The dialog renders it as plain text, so keep the
Vietnamese block free of Markdown styling (use emoji + "•" bullets).

Every new feature/release must add a `## vX.Y.Z` section with both parts.

## v1.2.1

Player bug fixes on Android.
- Fix: video frequently failed on the first play on Android — HLS (.m3u8) streams now tell ExoPlayer the format up front and retry on transient cold-starts.
- Fix: the screen no longer sleeps while a video is playing (wakelock held during playback, released on pause/exit).

<!-- app:vi -->
🛠 Sửa lỗi
• Khắc phục video không phát được ở lần bấm play đầu tiên trên Android.
• Màn hình không còn tự tắt khi đang xem phim.
<!-- /app:vi -->

## v1.2.0

Cinematic immersive redesign of the mobile app.
- Home & Detail open with full-bleed, edge-to-edge immersive hero artwork and a white circular Play button beside the title; the whole hero is tappable.
- Search redesigned into a content-led Discover state; Profile gets an immersive teal-washed header.
- Category tab bar is notch-safe; on Android the bottom nav clears the system gesture bar (iOS unchanged).
- Posters/backdrops decode at display resolution (lower memory, fixes occasional Android OOM crashes); app-wide crash guards around startup and Firebase init.

<!-- app:vi -->
✨ Giao diện mới
• Trang chủ và chi tiết phim chuyển sang phong cách điện ảnh, ảnh tràn viền, nút Play tròn ngay cạnh tên phim.

⚡ Mượt & ổn định hơn
• Tải ảnh nhẹ hơn, giảm giật và sửa lỗi văng app trên Android.
<!-- /app:vi -->
