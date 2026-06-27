# Changelog

English is the source of truth for the repo. Each version also carries a
Vietnamese block between `<!-- app:vi -->` ... `<!-- /app:vi -->` markers — the
release CI publishes THAT block as the GitHub release body, which the in-app
updater shows to users. The dialog renders it as plain text, so keep the
Vietnamese block free of Markdown styling (use emoji + "•" bullets).

Every new feature/release must add a `## vX.Y.Z` section with both parts.

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
