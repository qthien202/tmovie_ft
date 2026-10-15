# Changelog

English is the source of truth for the repo. Each version also carries a
Vietnamese block between `<!-- app:vi -->` ... `<!-- /app:vi -->` markers — the
release CI publishes THAT block as the GitHub release body, which the in-app
updater shows to users. The dialog renders it as plain text, so keep the
Vietnamese block free of Markdown styling (use emoji + "•" bullets).

Every new feature/release must add a `## vX.Y.Z` section with both parts.

## v1.7.1

Android "Thuyết minh AI" fixes. The voice model is now int8-quantized (282 → 84 MB graphs, ~147 MB download, ~3× faster), so 4 GB phones can run it; 3 GB phones don't offer it. OCR is bundled (sideloaded installs never got Play Services' module, so subtitles were never read). The model loads with the first line and the scout starts once the film plays, the voice runs at background priority on two threads, OCR reads only the subtitle band, and slow phones drop to 8 flow steps, which fixes the stutter and the player being killed on low-memory phones. v1.7.0's 345 MB model is deleted; the scout starts 5 s ahead, so the first lines after a seek are voiced too.

<!-- app:vi -->
🛠 Sửa lỗi
• Thuyết minh AI: hết bị giật, không còn văng khỏi phim khi bật thuyết minh.
• Gói giọng đọc gọn hơn nhiều: chỉ còn khoảng 150 MB (trước 345 MB), đọc nhanh gấp 3 lần, chạy được trên máy 4 GB RAM. Gói cũ được tự xoá, cần tải lại gói mới một lần.
• Sửa lỗi không đọc được phụ đề trên một số máy.
<!-- /app:vi -->

## v1.7.0

"Thuyết minh AI": on-device Vietnamese voice-over for Vietsub films. A muted scout copy of the episode runs ahead of the film, its burned-in subtitles are read by OCR, and VieNeu-TTS v3 Nano speaks each line as it comes up, ducking the film while it talks. Off by default; the player settings panel turns it on, downloads the voice model once (~345 MB, Android 10+ on 64-bit) and picks one of 11 voices.

<!-- app:vi -->
✨ Mới
• Thuyết minh AI (thử nghiệm): phim Vietsub giờ có thể nghe thuyết minh tiếng Việt, giọng đọc được tạo ngay trên máy theo phụ đề.
• Bật trong phần Cài đặt của trình phát. Lần đầu cần tải gói giọng đọc khoảng 345 MB (Android 10 trở lên, máy 64-bit). Máy càng mạnh thì giọng đọc càng theo kịp lời thoại.
• Có 11 giọng đọc để chọn, mặc định là giọng Ái Hân.
<!-- /app:vi -->

## v1.6.1

Country first. The "Quốc gia" picker now leads the home pills, the category pills and the filter menu, and Home gets a "Phim theo quốc gia" shelf of flag tiles (plus "Tất cả" for the full list).

<!-- app:vi -->
✨ Mới
• Thêm mục "Phim theo quốc gia" ở trang chủ: bấm cờ là vào thẳng phim của nước đó.
• Bộ lọc Quốc gia được đưa lên đầu, chọn quốc gia trước rồi mới chọn thể loại cũng được.
<!-- /app:vi -->

## v1.6.0

Combined filters, country picker and a way back to the film from the player.
- Category pages filter in place: genre, country and year combine, each pill shows its pick, and one tap clears them. The home row gets a "Quốc gia" picker next to "Thể loại".
- The player has a film-info button that opens the detail page when playback started elsewhere (history, hero, downloads).
- The skip-intro button is gone.
- iOS: offline downloads (ad-free, served from the device), a cleaner Netflix-style player with working Close, edge brightness/volume bars, the splash animation, and shimmer / scroll motion across the app.

<!-- app:vi -->
✨ Mới
• Lọc phim cùng lúc theo thể loại, quốc gia và năm ngay trong trang danh mục.
• Thêm mục chọn Quốc gia ở trang chủ.
• Trong trình phát có nút ⓘ để mở trang thông tin phim khi xem từ lịch sử.

🧹 Gọn hơn
• Bỏ nút "Bỏ qua giới thiệu" trong trình phát.
<!-- /app:vi -->

## v1.5.1

Android: the new player no longer crashes when playback starts. The `WAKE_LOCK` permission was missing for ExoPlayer's network wake mode. An emulator smoke test now plays a film on every Android change, so a crash like this can't ship again.

<!-- app:vi -->
🛠 Sửa lỗi
• Sửa lỗi trình phát mới bị thoát khi bắt đầu xem phim.
<!-- /app:vi -->

## v1.5.0

New player, ad-free streams and a redesigned update dialog (Android). The iOS app gets the same player.
- New player:
  - Custom controls; gestures for double-tap seek, scrub, brightness, volume and pinch-zoom.
  - Lock; quality, audio, subtitles, speed and aspect settings; sleep timer; skip intro.
  - Next-episode countdown card, in-player episode list, PiP button and MediaSession.
- Streams: ads spliced into HLS playlists are stripped.
  - Deeper buffers, more retries, cross-protocol redirects.
  - Playback resumes on its own when the network comes back.
- The screen no longer turns off while a film is playing.
- Redesigned update dialog: app icon, version jump, formatted release notes, and in-place download progress (percent and MB) leading to install.

<!-- app:vi -->
🎬 Trình phát hoàn toàn mới
• Chạm 2 lần để tua, vuốt chỉnh độ sáng/âm lượng/tua, khoá màn hình, chọn chất lượng, tốc độ, khung hình, hẹn giờ tắt, bỏ qua giới thiệu.
• Chọn tập ngay trong trình phát, đếm ngược sang tập tiếp theo.

🚫 Không còn quảng cáo chèn giữa phim
• Tự lọc các đoạn quảng cáo bị chèn vào phim, phát mượt và ổn định hơn.
• Mất mạng sẽ tự phát lại khi có mạng.
• Màn hình không còn tự tắt khi đang xem.

✨ Cập nhật đẹp hơn
• Hộp thoại cập nhật mới: hiện rõ phiên bản, ghi chú dễ đọc và tiến trình tải ngay trong app.
<!-- /app:vi -->

## v1.4.1

Android fixes.
- The hero's autoplay preview no longer spills out below the page dots. It now renders into a clipped TextureView sized to aspect-fill, instead of a SurfaceView that ignores Compose clipping.
- Smoother Home:
  - JSON is decoded off the main thread.
  - Hero animations (Ken Burns, tilt, paging) redraw layers instead of recomposing every frame.
  - The hero appears with its final key art, and placeholders keep the layout stable while loading.
  - Shelves animate in only once.

<!-- app:vi -->
⚡️ Trang chủ mượt hơn
• Tải nhanh, không còn giật khi mở app; ảnh hiện mượt, bố cục không nhảy khi đang tải.

🛠 Sửa lỗi
• Đoạn xem trước ở trang chủ không còn bị lộ ra bên dưới thanh chuyển trang.
<!-- /app:vi -->

## v1.4.0

The mobile app is rebuilt natively in Kotlin + Jetpack Compose (android/), replacing the Flutter build; it installs over it as a normal update.
- Home: Apple TV-style hero following Netflix's weekly Top 10 for Vietnam (crawled every 6h), with textless key art, parallax, tilt depth and a muted autoplay preview; Continue Watching, My List and Top 10 shelves.
- Netflix-style category pages with a full-screen genre picker and filters; New & Hot (upcoming / airing / completed) now works on PhimAPI; Search with genre chips.
- Player: Media3 with Picture-in-Picture, resume, next episode and an in-player episode panel.
- Fixes: content filtering works on PhimAPI's genre tags; images under `upload/vod/` no longer 404.

<!-- app:vi -->
✨ TMovie hoàn toàn mới
• Ứng dụng được viết lại native cho Android: mượt hơn, nhẹ hơn, giao diện mới phong cách Apple TV.

🔥 Phim hot thật sự
• Trang chủ hiển thị Top 10 phim đang hot nhất tuần ở Việt Nam, tự cập nhật mỗi 6 giờ, kèm đoạn xem trước tự phát.

🎬 Xem phim đã hơn
• Hình trong hình (PiP), xem tiếp đúng chỗ đã dừng, tự chuyển tập và chọn tập ngay trong trình phát.

📺 Khám phá dễ hơn
• Trang thể loại mới, mục Mới & Hot (sắp chiếu, đang chiếu, trọn bộ) và tìm kiếm theo thể loại.
<!-- /app:vi -->

## v1.3.2

Switch movie data and stream provider to PhimAPI.
- Core: migrated API base URL and image CDN to PhimAPI (phimapi.com / phimimg.com) for faster loading and updated movie catalogue.

<!-- app:vi -->
🚀 Nâng cấp nguồn phim
• Chuyển đổi nguồn phim sang PhimAPI mới giúp tải phim nhanh hơn, hình ảnh sắc nét và danh sách phim cập nhật liên tục.
<!-- /app:vi -->

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
