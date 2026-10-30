# Changelog

English is the source of truth for the repo. Each version also carries a
Vietnamese block between `<!-- app:vi -->` ... `<!-- /app:vi -->` markers — the
release CI publishes THAT block as the GitHub release body, which the in-app
updater shows to users. The dialog renders it as plain text, so keep the
Vietnamese block free of Markdown styling (use emoji + "•" bullets).

Every new feature/release must add a `## vX.Y.Z` section with both parts.

## v1.10.1

Android TV: posters load much faster. The image host (phimimg.com) holds every request ~8 s regardless of size, and OkHttp allowed only 5 requests per host, so a screen of 20 cards took over 30 s. The TV image loader now runs up to 32 requests per host and keeps a 200 MB disk cache, so a screen fills in one wait and revisits are instant. New Lịch sử tab (as the phone's "Của tôi"): everything watched with progress and time left, My List, and a two-press "Xoá lịch sử".

<!-- app:vi -->
⚡ Cải thiện (Android TV)
• Tab Lịch sử mới: xem lại phim đã xem (kèm tiến độ, số phút còn lại) và Danh sách của tôi.
• Ảnh phim tải nhanh hơn nhiều, mở lại các trang đã xem thì ảnh hiện ngay.
<!-- /app:vi -->

## v1.10.0

Native Android TV app (`android/:tv`) replaces the Flutter TV build, on the same core as the phone app (PhimAPI, ad-free HLS, library, OTA), styled after Netflix and Apple TV. Home opens on a full-screen billboard of the hot list (textless key art, TOP n tag, synopsis, Phát / Thông tin / +, rotating every 12 s while on screen), then rows on the plain canvas that pin to the top as focus moves: Xem tiếp (progress, minutes left), a Netflix-style Top 10 row with outlined rank numbers, hot series, My List and the genre rails, each ending in "Xem tất cả" (paginated grid). Landscape cards with titles underneath; focus is a scale + white ring. Film pages: full-bleed art with details and Play / Continue low on the left, dimming as the server, 50-episode block, episode and similar rows scroll up. Search with an on-screen A–Z / 0–9 keyboard (no system IME; the remote's search key lands on it). Live channels by country and category. Remote player: OK plays / pauses, ◀ ▶ seek (faster when held), ▼ opens episodes, quality, subtitles, audio and speed; Apple TV style scrubber with time left; auto-next and resume as on the phone. Back steps out page → nav → Home; a second Back within 2 s exits. Netflix-style side menu (icon rail; focusing it dims the screen and spells out the tabs). New Khám phá tab: browse every film by kind (all / series / movies / animation / TV shows), genre, country and year through Netflix-style full-screen pickers, with a paginated grid and a one-press reset. The home billboard's films are published as the app's "Phim nổi bật" channel on the TV home screen (same key art). Films being watched appear in the TV home screen's Watch Next row (`androidx.tvprovider`, searchable, 16:9 art) and open via `tmovie://film/<slug>`. New launcher banner and TV wordmark in the icon's cyan → lavender → pink. Built for low-end boxes: no shadows, blurs or per-focus backdrops, a small image cache (RGB 565 on low-RAM devices) and a baseline profile (also added to the phone app). On the Google TV emulator: ~5 % janky frames, p90 19 ms, ~75 MB PSS. Same package id and key as the Flutter TV app, so it installs over it; releases ship `tmovie-tv` again. Phone: the update dialog moved to `core:ui` and focuses its main button for remotes.

<!-- app:vi -->
📺 Mới (Android TV)
• Ứng dụng TV làm lại hoàn toàn theo phong cách Netflix / Apple TV, nhẹ và mượt cả trên TV box cấu hình yếu.
• Trang chủ mở đầu bằng phim hot toàn màn hình, có Top 10 tại Việt Nam, Xem tiếp, phim bộ hot và các thể loại (xem tất cả từng mục).
• Trang phim ảnh tràn màn hình, nút Phát / Tiếp tục, chọn nguồn và tập (phim dài chia theo từng 50 tập).
• Tìm kiếm có bàn phím ngay trên màn hình, gõ không cần dấu; nút tìm kiếm trên remote mở thẳng.
• Trình phát cho remote: OK dừng/phát, ◀ ▶ tua (giữ để tua nhanh), ▼ chọn tập, chất lượng, phụ đề, tốc độ; tự phát tập tiếp.
• Tab Khám phá mới: lọc phim theo loại, thể loại, quốc gia và năm.
• Màn hình chính của TV hiện phim nổi bật và phim đang xem dở của TMovie, bấm vào mở đúng phim.
• Truyền hình lọc theo quốc gia, thể loại. Nhấn Quay lại 2 lần để thoát app.
<!-- /app:vi -->

## v1.9.0

Android drops "Thuyết minh AI": the :core:voiceover module (ONNX Runtime, bundled ML Kit OCR, the `:voice` process) is out of the build, so the APK shrinks from ~19.7 MB to ~4.6 MB and playback runs one ExoPlayer instead of two. Voice models already downloaded are deleted on first launch. iOS keeps the feature. The Android tab bar now shows only on the five tab screens and slides away on detail and list pages.

<!-- app:vi -->
⚡ Tối ưu (Android)
• Bỏ Thuyết minh AI để app nhẹ và mượt hơn: dung lượng cài đặt giảm từ khoảng 20 MB còn 5 MB, giọng đọc đã tải trước đó được tự xoá để trả lại bộ nhớ.
🐛 Sửa lỗi
• Thanh tab dưới chỉ hiện ở các màn hình chính, không còn che trang chi tiết phim và danh sách.
<!-- /app:vi -->

## v1.8.2

Tab bars go icons-only. iOS keeps the system Liquid Glass bar with filled symbols (house, flame, play.tv, person; search stays its own glass button), titles kept for VoiceOver. Android keeps the floating glass capsule and its springy highlight, with thin line icons (Lucide paths) that turn teal with a bolder stroke when selected.

<!-- app:vi -->
✨ Mới
• Thanh tab dưới gọn hơn: chỉ còn icon, bộ icon mới mảnh và rõ ràng hơn.
<!-- /app:vi -->

## v1.8.1

"Truyền hình" now reads iptv-org's whole index (~11,200 channels, ~180 countries, 29 categories) with Quốc gia / Thể loại pickers (Việt Nam by default, picker overlay shared with Home) and search across every country; lists play as published (only DASH, unsupported, is skipped). Channels open in the film player's live mode: same controls, gestures, lock, quality, aspect, sleep timer and PiP, with a "TRỰC TIẾP" button instead of the seek bar, and no episodes, history or voice-over. Android's tab bar is redrawn: outlined icons that fill when selected, a springy highlight and a light haptic tick. iOS gets the same Truyền hình tab and live mode.

<!-- app:vi -->
✨ Mới
• Truyền hình: hơn 11.000 kênh từ khoảng 180 quốc gia. Lọc theo Quốc gia, Thể loại (29 thể loại), tìm kênh trong toàn bộ danh sách.
• Xem kênh bằng trình phát giống khi xem phim (khoá màn hình, chất lượng, hẹn giờ, hình trong hình), có nút TRỰC TIẾP để về đúng chỗ đang phát.
• Thanh tab dưới được làm mới: icon mảnh và gọn hơn, chuyển tab mượt hơn.
<!-- /app:vi -->

## v1.8.0

Android "Truyền hình" tab: live channels from iptv-org's public playlists (Việt Nam, Thể thao, Tin tức), with logos and search, played full screen by a new LiveActivity (HLS, per-channel User-Agent / Referer, jumps back to the live edge after a stall). Our lists skip restreams of paid services (FPT Play, SCTV) and re-hosting sites, plus geo-blocked foreign channels; "+" adds any M3U playlist URL, played as it is (long-press removes it). The tab bar now has five tabs.

<!-- app:vi -->
✨ Mới
• Tab Truyền hình: xem kênh truyền hình trực tiếp, gồm kênh Việt Nam, kênh thể thao và tin tức quốc tế phát miễn phí. Có logo và ô tìm kênh.
• Bấm "+" để thêm danh sách kênh (.m3u) của riêng bạn, giữ lâu để xoá.
<!-- /app:vi -->

## v1.7.2

Android "Thuyết minh AI" can no longer close the film. Synthesis runs in its own process (`:voice`), so running out of memory or a crash in the voice runtime kills only the voice; Android restarts it and the film plays on (three deaths turn the voice-over off). Any error in the voice-over on the player's side turns it off with a message instead of crashing. And if the app is still closed abruptly while it runs, the next launch starts with it off and shows the exit reason, so there's no crash loop and the cause can be reported.

<!-- app:vi -->
🛠 Sửa lỗi
• Thuyết minh AI không còn làm văng khỏi phim: phần tạo giọng đọc giờ chạy tách riêng, máy thiếu RAM thì chỉ tạm mất giọng đọc, phim vẫn phát bình thường.
• Nếu Thuyết minh AI gặp lỗi, app sẽ tự tắt nó và báo lý do thay vì đóng phim.
<!-- /app:vi -->

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
