# Changelog

English is the source of truth for the repo. Each version also carries a
Vietnamese block between `<!-- app:vi -->` ... `<!-- /app:vi -->` markers — the
release CI publishes THAT block as the GitHub release body, which the in-app
updater shows to users. The dialog renders it as plain text, so keep the
Vietnamese block free of Markdown styling (use emoji + "•" bullets).

Every new feature/release must add a `## vX.Y.Z` section with both parts.

## v1.3.1

Video player and film-detail polish.
- Player: redesigned controls (center buttons grouped, no longer spread to the edges), now auto-plays the next episode when one ends — with a "next episode" card (countdown, play now / cancel) — plus a playback-speed control (1x–2x).
- Film detail redesigned into one immersive cinematic scroll (no more tabs): a bigger hero with a prominent "Xem ngay" button, an easy-to-scan episode grid, and a content-led layout.

<!-- app:vi -->
🎬 Trình phát mới
• Nút điều khiển gom gọn lại giữa màn hình, tự động phát tập tiếp theo khi hết tập (có thẻ "tập tiếp theo" đếm ngược), thêm chỉnh tốc độ phát 1x–2x.

✨ Trang phim đẹp hơn
• Trang chi tiết chuyển sang phong cách điện ảnh một mạch cuộn: ảnh lớn, nút Xem ngay nổi bật, danh sách tập dạng lưới dễ chọn.
<!-- /app:vi -->

## v1.3.0

Browse redesign, smarter hot-film hero, and cross-device sync.
- New bottom navigation: dedicated Phim bộ, Phim lẻ and TV Shows tabs (the Search tab is gone), each with its own layout — editorial rails, poster grid, and landscape cards.
- Category and Search are now one screen with an advanced filter: sort (mới cập nhật / phổ biến / năm), film type, multi-select genre & country, and release year.
- Home hero now surfaces genuinely trending Korean / Chinese / Western titles (sourced from Trakt), with animation excluded.
- Watch history and favorites sync both ways with the cloud, so they follow you across devices.
- Search is reachable from a top-bar icon on every browse tab and a floating button on Home.

<!-- app:vi -->
✨ Giao diện mới
• Thanh điều hướng mới: tách riêng tab Phim bộ, Phim lẻ và TV Shows, mỗi tab một bố cục riêng.
• Gộp Danh mục và Tìm kiếm thành một màn, thêm bộ lọc nâng cao: sắp xếp, loại phim, thể loại, quốc gia, năm.

🔥 Phim hot chuẩn hơn
• Mục nổi bật ở Trang chủ ưu tiên phim Hàn/Trung/Âu Mỹ đang thịnh hành, đã loại bỏ hoạt hình.

☁ Đồng bộ đa thiết bị
• Lịch sử xem và phim yêu thích đồng bộ hai chiều với đám mây, theo bạn trên mọi thiết bị.
<!-- /app:vi -->

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
