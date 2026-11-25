# TMovie Android phone app: implementation spec for the web PWA

All paths below are relative to `android/`. Shorthand:
- `app/` = `app/src/main/kotlin/com/thientech/tmovie/`
- `home/`, `browse/`, `detail/`, `profile/`, `onboarding/` = `feature/<x>/src/main/kotlin/com/thientech/tmovie/feature/<x>/`
- `ui/`, `ds/`, `player/`, `data/`, `model/` = `core/<x>/src/main/kotlin/com/thientech/tmovie/core/<x>/` (`ds` is designsystem)
- `net/` = `private/android/core/network/src/main/kotlin/com/thientech/tmovie/core/network/`

Unless a color is given, text is `Color.White`. "Secondary" is `#B3FFFFFF` (white at 70%).

**Things that don't exist on the phone app** (useful for scoping):
- No download feature, no "Báo tập mới" button, no logout row in settings (logout is the icon on the account card), and no search history.
- `LiveRoute` / `LiveTvScreen` is registered in the NavHost (`app/AppNavHost.kt:166`), but no tab and no link navigates to it. It can't be reached.
- `NewHotScreen()` (`browse/NewHotScreen.kt:66`) is never shown on its own. Only its `Feed` enum and `FeedCard` are used, inside Khám phá.

---

## 0. Design tokens (`ds/`)

**Colors** (`ds/Theme.kt:16-22`)
| Token | Value |
|---|---|
| Brand | `#3D8BFF` |
| BrandLight | `#8ABCFF` |
| Canvas | `#05080A` |
| Surface | `#12161A` |
| Secondary | `#B3FFFFFF` |
| Material `surfaceVariant` | `#1C2126` (`ds/Theme.kt:44`) |

The app is dark only.

Other colors that recur:
- Destructive red `#FF6B6B` (profile "Xoá", filter "Bỏ lọc")
- Error text `#FF8A80`
- Rating star `#FFD60A`
- Live dot `#FF3B30`
- Offline icon `#FFB74D`
- Glass panel backgrounds `#E6101418`, `#CC101418`, `#F20B0F12`, `#E60B0F12`

**Typography** (`ds/Theme.kt:27-31`). Everything else uses Material defaults (system sans).
- `TMovieType.Display`: Serif, Black (900), 36sp, line height 40sp. Not used on phone screens.
- `TMovieType.Title`: Serif, Bold, 28sp, line height 32sp. This is the page title for Khám phá, Tìm kiếm, Của tôi, the catalog, detail, and the featured card.
- `SectionTitle`: 20sp Bold white (`ds/Components.kt:139`).
- `Wordmark`: "TMOVIE", Black weight, default 26sp, letter-spacing `size × 0.06`sp, horizontal gradient Brand→BrandLight (`ds/Components.kt:124-135`).

**Shapes** (`ds/Glass.kt:36-37`)
- `CardShape` = 8dp radius
- `HeroShape` = 14dp radius

**Glass modifier** (`ds/Glass.kt:24-34`)
- Fill: vertical gradient, white 16% → 8%.
- If a tint is given, the fill is tint 30% → 18% instead.
- Border: 1dp, vertical gradient white 35% → 8%.
- No backdrop blur.

**Motion**
- `pressScale`: scales to 0.96 while pressed, default spring (`ds/Glass.kt:40-44`).
- `cinematic()`: spring with dampingRatio 0.85 and stiffness MediumLow (≈400) (`ds/Theme.kt:25`).
- Images crossfade in over 250ms on a white-6% placeholder background (`ds/Components.kt:41-50`).
- Average-color sampler (`ds/ColorSampler.kt`): decodes the image at 48px and averages the RGB. In HSV it then sets saturation to `min(1, s×1.6+0.15)` and value to `clamp(v×1.5, 0.55, 0.9)`.

**Shared buttons** (`ds/Components.kt`)
- `PlayCapsule` (:54-71):
  - White capsule, min height 50dp, horizontal padding 28dp, 6dp gap.
  - Black PlayArrow icon, or a 20dp black spinner (2dp stroke) while loading.
  - Label 17sp SemiBold black, 1 line.
- `PlayWide` (:75-92):
  - Full width, 46dp tall, radius 8, white background (white 50% when disabled).
  - Black play icon, 6dp gap, label 17sp SemiBold black.
- `Pill` (:97-113):
  - 34dp tall capsule, horizontal padding 14dp, 4dp gap before the trailing slot.
  - Unselected: glass background, white 15sp Medium text.
  - Selected: white background, black 15sp SemiBold text.
  - Supports long-press; has pressScale.
- `ProgressStrip` (:117-121): 3dp tall, white 25% track, Brand fill.

---

## 1. App shell

### Root flow (`app/MainActivity.kt`)
- Edge-to-edge (:37).
- `AccessGate("android") { … }` wraps everything (:45).
- Inside the gate, a Crossfade goes splash → onboarding (until `Settings.onboarded`) → main (:46-62).
- `UpdatePrompt` sits above everything, including the gate (:64).
- The notification permission is requested once, when the main screen first shows (Android 13+). It is gated by the prefs key `push.asked` (:76-89).

### Splash (`onboarding/SplashScreen.kt`)
- Canvas background, "TMOVIE" centered.
- Each letter is 54sp Black with a vertical Brand→BrandLight gradient.
- Letter i starts after `i×70ms` and springs in (MediumBouncy damping, stiffness 300).
- Each letter animates from: alpha 0 → 1, translateY 30dp → 0, scale 0.6 → 1, blur 8dp → 0.
- Done after 1400ms (600ms with reduce-motion).

### Onboarding (`onboarding/OnboardingScreen.kt`)
Three pages (:58-62), each with a title and body:
1. "Cả thế giới điện ảnh\ntrong túi bạn" / "Phim bộ, phim lẻ, TV Shows cập nhật mỗi ngày." (icon AutoAwesome)
2. "Sắc nét đến\ntừng khung hình" / "Phát Full HD, Hình trong hình và chọn tập ngay trong player." (icon PictureInPicture)
3. "Tiếp tục xem\nđúng chỗ bạn dừng" / "Lịch sử và danh sách của bạn luôn sẵn sàng." (icon History)

Background poster wall (:102-122):
- Posters from `phim-moi-cap-nhat`.
- 4 columns, 110dp wide, 10dp gaps, posters 2:3 with radius 8.
- The whole wall is rotated −12°, offset x −60dp and y −40dp.
- Even columns are offset y −40dp, odd columns −120dp.
- It drifts up 260dp over 40s, linear, reversing.

Overlay gradient: Canvas at 20% → 85% at 0.55 → 100% (:74).

Bottom stack (:75-96):
- Pager 300dp tall. Each page: 44dp Brand icon, Title style at 32sp/36sp, body 16sp Secondary, 14dp gaps, 32dp horizontal padding.
- Dots: 8dp each, 8dp gap, white when active, white 30% otherwise.
- Button: 52dp tall, radius 12, Brand background, 24dp horizontal margin. Label "Tiếp tục", or "Bắt đầu xem" on the last page, 17sp SemiBold.
- "Bỏ qua" text link in Secondary, 14dp top padding.
- 24dp bottom padding above the nav bar.

### NavHost and transitions (`app/AppNavHost.kt`)
- Routes (:163-175): Home (start), NewHot (renders ExploreScreen), Search, Profile, Film(slug, name, thumb, poster, sourceId), List(title, kind, slug).
- Everything is wrapped in `SharedTransitionLayout`. Poster → detail header uses `sharedBounds` keyed `"film-$sourceId"` (`ui/Navigation.kt:66-73`).
- Other transitions are the default NavHost fade.
- Tab switching pops to the start destination with saveState, launchSingleTop and restoreState, i.e. scroll state is preserved per tab (:189-193).
- The bottom bar shows only on the 4 tab routes. It slides in/out vertically by its own height, combined with a fade (:179-196). Detail and list pages are full screen.

### Deep links (`app/AppNavHost.kt:140-157`)
- `tmovie://phim/{slug}`: fetches the detail, pushes FilmRoute with sourceId `link/{slug}`. With `?play=1` it also starts playback.
- `tmovie://the-loai/{slug}`: looks up the genre name from the taxonomy (falls back to the slug) and pushes `ListRoute.genre`.
- MainActivity is `singleTask` (manifest :17).

### Floating glass tab bar (`app/AppNavHost.kt:95-254`)
- Four tabs, icons only. Labels are only for accessibility (role Tab, selected state):
  1. "Trang chủ" (Home)
  2. "Khám phá" (NewHotRoute)
  3. "Tìm kiếm"
  4. "Của tôi"
- Icons are Lucide paths on a 24-unit grid, drawn at 25dp, white stroke, round caps and joins. Stroke width is 1.6 normally and 2.3 when selected (:105-108).

| Tab | SVG paths (:114-121) |
|---|---|
| Home | `M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8` and `M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z` |
| Khám phá | `M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0` and `M16.2 7.8l-2 6.4-6.4 2 2-6.4z` |
| Tìm kiếm | `M3 11a8 8 0 1 0 16 0a8 8 0 1 0-16 0` and `M21 21l-4.3-4.3` |
| Của tôi | `M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2` and `M8 7a4 4 0 1 0 8 0a4 4 0 1 0-8 0` |

- Each tab is 62×48dp with a 4dp gap (:110-112).
- Container (:212-220): bottom-center, above the nav-bar inset, 10dp bottom margin, full capsule, `#E60B0F12` background plus glass, 6dp inner padding.
- Highlight (:211, :222): a 62×48 capsule in white 12%, at x = `(62+4)×index` dp. It moves with a spring (damping 0.75, stiffness 500).
- Icon tint (:227): BrandLight when selected, white 85% otherwise. The change is a 180ms tween.
- Tapping a different tab fires a light haptic tick; there is no ripple (:232-235).
- Signed in, the profile tab shows the Google photo instead of the icon (:240-246). It is a 28dp circle with a border: 2dp BrandLight when selected, 1dp white 50% otherwise.
- Every scrolling screen adds 120dp bottom padding to clear the bar.

### Update prompt (`ui/UpdatePrompt.kt`)
- Release builds only. Checks GitHub `https://api.github.com/repos/qthien202/tmovie_ft/releases/latest` with keyword "mobile" (`data/AppUpdater.kt:22`).
- Dialog (:109-200):
  - Black 55% scrim. Tapping outside dismisses, except while downloading.
  - Card: max width 420, 24dp margin, radius 28, Surface background plus a Brand 45% radial glow from the top-left (radius 700px), 1dp border white 25%→5%, 24dp padding.
  - Entrance (:96, :123-128): spring (damping 0.8). Animates alpha, scale 0.9→1 and translateY 40dp→0.
- Contents, top to bottom:
  - App icon in a 76dp tile, radius 20, background `#0A0D14`.
  - "Đã có bản mới" (22sp Bold).
  - Version jump: two chips with an arrow between. "from" is Secondary 13sp SemiBold on white 8%; "to" is white 13sp Bold on Brand; padding 10×4.
  - Release notes box: max height 260, radius 16, white 5%, 16dp padding.
    - Lines starting with "•" render as a bullet row: 5dp BrandLight dot, 14sp/20sp text in white 85%.
    - Other lines are 16sp Bold headings.
    - Empty notes show "Bản mới đã sẵn sàng." (:220).
- Download progress (:235-249): 8dp bar with a Brand→BrandLight fill, plus the label "Đang tải {pct}% · {x} / {y} MB" (or "Đang tải…").
- On failure: "Tải thất bại, kiểm tra mạng rồi thử lại nhé." (13sp `#FF8A80`).
- Primary button labels: "Cập nhật ngay" / "Đang tải…" / "Cài đặt" / "Thử lại".
- `PrimaryButton` style (:252-269): 52dp tall, radius 16, gradient Brand → `#14B8A6`. Disabled: white 12%. Focused: 2dp white border. Label 17sp SemiBold.
- "Để sau" (15sp Secondary) below the button, hidden while busy.

---

## 2. Home (`home/HomeScreen.kt`, `Hero.kt`, `HeroPreview.kt`, `HomeViewModel.kt`)

### Structure (`HomeScreen.kt:105-144`)
- `PullToRefreshBox` (Material3) calls `vm.load(refresh=true)`.
- Background: vertical gradient from `wash` at 0 to Canvas at 0.5.
  - `wash` = the hero art's sampled tint at 35% alpha, animated over 800ms (:101-103).
  - The tint is re-sampled whenever `pager.settledPage` changes. It uses the hero art (TMDB backdrop), falling back to the thumb, then to Brand.
- LazyColumn: 26dp gap between sections, 120dp bottom padding.
- `HomeHeader` is overlaid on top.

### Section order and conditions
1. **Hero** (:108-117). While empty, a placeholder box at 0.74 × screen height in white 4%. Note the real hero is 0.78 × screen height, so these don't match.
2. **"Xem tiếp"**, if history is non-empty: `Shelf("Xem tiếp", spacing=14dp)` with the first 15 history items as `ContinueCard`s (:118-120).
3. **"Danh sách của tôi"**, if saved is non-empty: all saved films as `PosterCard`s, sourceId `mylist/{slug}` (:121-123).
4. **Top 10 deck**, if top10 is non-empty (:124).
5. **CountryShelf "Phim theo quốc gia"**, always shown (:125).
6. **Rails** (`HomeViewModel.kt:27-37`). Each rail is a `Shelf(title, more=route)` with "Tất cả" linking to the route. In order (title → source):
   1. "Mới cập nhật" → type `phim-moi-cap-nhat`
   2. "Phim Hàn Quốc" → country `han-quoc` (list title "Hàn Quốc")
   3. "Phim Trung Quốc" → country `trung-quoc` (list title "Trung Quốc")
   4. "Phim lẻ" → type `phim-le`
   5. "TV Shows" → type `tv-shows`
   6. "Hành động" → genre `hanh-dong`
   7. "Tình cảm" → genre `tinh-cam`
   8. "Kinh dị" → genre `kinh-di`
   9. "Hoạt hình" → type `hoat-hinh`
   - While a rail loads it shows 5 placeholders (112×168, radius 8, white 6%). A rail that loads empty is hidden (:126-134).
7. **Error**, when the hero and all rails are empty (:135-140): "Không tải được phim" plus a Material Button "Thử lại", 32dp padding, centered.

### HomeHeader (:153-173)
- Overlaid at the top over a vertical gradient: black 85% → 40% → transparent.
- Below the status bar, 10dp bottom padding, 12dp gap between rows.
- Row 1: `Wordmark` at 26sp, padding 16dp horizontal and 4dp vertical.
- Row 2: horizontally scrolling pills, 16dp horizontal padding, 8dp gaps:
  1. `GenrePickerPill(Countries)` → "Quốc gia ⌄"
  2. `GenrePickerPill()` → "Thể loại ⌄"
  3. Pill "Phim bộ" → type `phim-bo`
  4. Pill "Phim lẻ" → `phim-le`
  5. Pill "TV Shows" → `tv-shows`
- The header doesn't change on scroll; content scrolls under it.

### Hero data (`HomeViewModel.kt:89-130`)
- **Source 1**: HotList JSON `https://raw.githubusercontent.com/qthien202/tmovie_ft/hot-data/hot.json` (`net/HotList.kt:16`).
  - Hero = films that aren't animation, first 12 (requires at least 5).
  - top10 = `hot.series`, first 10.
- **Fallback**: rank by KKPhim views over `phim-bo` p1+p2 and `phim-le` p1.
  - Films from han-quoc, trung-quoc or au-my get a 1.5× boost.
  - Cached per day in prefs `home` under keys `hero.day` and `hero.v6`.
  - Below 5 results, falls back to "freshest": `phim-moi-cap-nhat` p1–2, those three countries first, top 10.
- **Key art**: the TMDB backdrop with no language (iso_639_1 null), else any backdrop, at w1280. Waited on for up to 2.5s before the hero is published (:59).

### HeroPager (`Hero.kt:83-149`)
- Height = 0.78 × screen height (:94).
- Parallax on scroll: translateY = scrollOffset × 0.35 (:117-120).
- Auto-advance (:99-104): after 8000ms, or 30000ms when preview autoplay is on, go to `(settled+1) % n`.
  - Uses `cinematic()` motion.
  - Skipped while the user is dragging.
  - The timer restarts on every settled page.
- Haptic tick on each page change (:105).
- Ken Burns: scale 1→1.12 over 12000ms, FastOutSlowIn, reversing. The art is also always scaled ×1.08 (:107-110, :176).
- Paging parallax: art translateX = pageOffset × width × 0.4 (:179).
- Device tilt adds art −tilt.x×22dp horizontally and −tilt.y×14dp vertically. Tilt is clamped ±0.4 and low-pass filtered at 0.12 (`Motion.kt:38-63`). Optional on web.
- Page indicator (:138-147): vertical, bottom-end, 12dp from the right and 40dp from the bottom.
  - Glass capsule with padding 5dp horizontal, 8dp vertical, 5dp gaps.
  - Each dot is 5dp wide. Height animates to 24dp when selected, 6dp otherwise. Color white when selected, white 40% otherwise.
- Autoplay requires `Settings.heroAutoplay && !reduceMotion && !powerSave` (:89).

### HeroPage (`Hero.kt:151-261`)
- Tapping the art opens the film with sourceId `hero/{slug}`.
- Scrim gradient (:188-196), stop → color:
  | Stop | Color |
  |---|---|
  | 0 | black 70% |
  | 0.16 | black 25% |
  | 0.30 | transparent |
  | 0.46 | transparent |
  | 0.62 | black 38% |
  | 0.80 | tint 10% composited over black 72% |
  | 1.0 | Canvas |
- Caption (:201-259): bottom-start, padding start 20, end 48, bottom 30.
  - Fades out as `1 − |offset|×1.4` and shifts x by offset×60dp while paging.
- Caption rows, top to bottom:
  1. Badge "TOP {rank}": black 10.5sp Black, letter-spacing 0.6, white background, radius 6, padding 7×2. Followed (8dp gap) by "Đang hot tuần này" in white 85%, 12sp SemiBold.
  2. Title, 10dp top padding, ExtraBold, letter-spacing −0.8, shadow black 35% blur 28. Size depends on name length:
     | Length | Size / line height | Max lines |
     |---|---|---|
     | ≤16 | 40/41sp | 2 |
     | >16 | 34/36sp | 2 |
     | >26 | 28/31sp | 3 |
  3. Facts row, 10dp top, 6dp gap:
     - Text in white 85%, 13sp, 1 line: type label ("Phim bộ" / "Phim lẻ" / "TV Show" / "Hoạt hình"), the first 2 genres, and the year, joined with " · " (:272-282).
     - Then a quality badge, if any.
     - Then a language badge: "TM" if lang contains "thuyết" or "lồng", else "VS".
     - Badge style (:264-269): 10sp Bold, 1dp border white 55%, radius 4, padding 5×1.
  4. Story (:239-242): detail `content` with HTML stripped, white 72%, 14/19sp, 2 lines, min height 38dp, 8dp top.
  5. Buttons row, 16dp top, 12dp gap:
     - `PlayFilmButton(capsule)`: "Xem ngay", or "Xem tiếp" if the film is in history.
     - `SaveButton(Circle)`: 50dp glass circle with a + or ✓ icon.
     - Mute button, only while a preview plays: 50dp glass circle with VolumeOff/VolumeUp. Toggles `Settings.heroMuted` (default true). Accessibility labels "Bật tiếng xem trước" / "Tắt tiếng xem trước". Enters with fade+scale.

### HeroPreview (`HeroPreview.kt`)
- Runs only on the settled page.
- Waits 1500ms, then plays episode 1 of the first server that has an m3u8.
- Waits until the duration is known, then seeks to 240000ms if the duration is over 10 minutes, else to duration/10.
- Loops a 45s window: polls every 500ms and seeks back to the start once position > start+45000.
- Fades in over 1200ms once playing and more than 300ms past the start.
- Video is aspect-filled and clipped.
- Volume is 0 when muted.
- Pauses when the page is hidden.

### Top 10 deck (`HomeScreen.kt:180-265`)
- `RailHeader("Top 10 phim bộ tuần này", more = type phim-bo "Phim bộ")`, 10dp gap to the deck.
- Deck box: full width, 262dp tall, clipped.
- Cards: 162×243dp, radius 18, 1dp border white 16%, transform origin bottom-left.
- For each card, `k = (i − top + n) % n` and `v = min(k, 4)`:
  - x = 18 + v×64 dp
  - y = v×7 dp
  - scale = 1 − v×0.075
  - dim overlay = black at `min(0.5, v×0.13)`
  - z-index = 20 − k
  - Cards with k > 4 have alpha 0.
- Card contents:
  - Poster image.
  - Gradient: transparent at 0.55 → black 75% at the bottom.
  - Rank "{i+1}": 64sp Black, letter-spacing −3, shadow black 60% blur 20, bottom-start, 10dp start, offset y +12dp.
    - Rank fill: #1 gradient `#FFF3CC`→`#F0B84D`, #2 white→`#B9C2CC`, #3 `#FFE0BF`→`#D08A4C`, others white.
  - Episode badge at the top-left, same as PosterCard but radius 9 and padding 7×3.
- Swipe (threshold 40dp) steps the deck by one, endlessly. The top card follows the drag at 0.6×.
  - The card leaving animates to x −150, y −6, scale 0.96, rotation −12°.
  - After 260ms its z-order flips (it tucks under the deck when swiping left, or comes back on top when swiping right).
  - Springs: damping 0.9 for the moving card, 0.82 for the others, stiffness MediumLow.
  - Haptic tick on each step.
- Tapping the top card opens the film (sourceId `top10/{slug}`). Tapping a card behind (k ≤ 4) brings it to the top.

### CountryShelf (`ui/GenrePicker.kt:80-122`)
- `Shelf("Phim theo quốc gia")` with these tiles in order:
  - 🇰🇷 Hàn Quốc `han-quoc`
  - 🇨🇳 Trung Quốc `trung-quoc`
  - 🇺🇸 Âu Mỹ `au-my`
  - 🇯🇵 Nhật Bản `nhat-ban`
  - 🇹🇭 Thái Lan `thai-lan`
  - 🇻🇳 Việt Nam `viet-nam`
  - 🇹🇼 Đài Loan `dai-loan`
  - 🇭🇰 Hồng Kông `hong-kong`
  - 🇮🇳 Ấn Độ `an-do`
  - 🌏 "Tất cả", which opens the full country picker overlay.
- Tile: 124×84dp, radius 12, white 8% background, 1dp border white 10%, 12dp padding, content bottom-aligned with 4dp gap. Flag at 26sp, name 14sp SemiBold. Has pressScale.

---

## 3. Khám phá tab (`browse/ExploreScreen.kt`)
LazyColumn, 28dp gap between sections, 120dp bottom padding (:137). Data loads on entry; there is no pull-to-refresh.

1. **Header** (:138-143): below the status bar, 8dp top, 14dp gap.
   - "Khám phá" in Title style, 16dp horizontal.
   - **Stories** (:194-211): first 12 HotList films (films + series, deduplicated). LazyRow, 16dp horizontal padding, 14dp gaps.
     - Each item is 74dp wide.
     - Ring: 72dp circle with a sweep gradient [Brand, `#9D8CFF`, `#FF8FB1`, `#FFD36E`, Brand], then a 3dp inset, a Canvas gap, another 3dp inset, then the circular poster.
     - Label: 11sp Secondary, 1 line, ellipsis. The first 3 get a "🔥 " prefix. The name is cut at the first `:`, `/` or `(`.
     - Opens with sourceId `story/{slug}`.
2. **"Hôm nay bạn muốn xem gì?"** (:144-155). Section title 20sp Bold, 16dp horizontal, 12dp gap.
   - Mood cards (:77-86), name → route (list title = mood title) and gradient:
     | Mood | Route | Gradient |
     |---|---|---|
     | 😱 Hồi hộp | genre kinh-di | `#3A1C71`→`#D76D77` |
     | 💕 Lãng mạn | genre tinh-cam | `#FF8FB1`→`#9D5CFF` |
     | 😂 Cười xả láng | genre hai-huoc | `#F7971E`→`#FFD200` |
     | 🍿 Cày một đêm | type phim-le | `#1D976C`→`#93F9B9` |
     | 📺 Cày dài kỳ | type phim-bo | `#2B5876`→`#4E4376` |
     | 👨‍👩‍👧 Cả nhà cùng xem | type hoat-hinh | `#3D8BFF`→`#5BE0FF` |
     | 🤯 Mind-blowing | genre vien-tuong | `#0F2027`→`#2C7A8C` |
     | ⚔️ Cổ trang | genre co-trang | `#C79A3A`→`#8A3A1F` |
   - MoodCard (:232-254):
     - 150×178dp, radius 26, linear gradient background.
     - Border: 2.5dp white when selected, else 1dp white 18%. Selected card is also lifted 3dp.
     - A fan of 3 posters 62dp wide at the top (14dp top padding).
     - Bottom glass label: 8dp margin, radius 18, padding 10×8. Emoji 20sp, title 14sp Bold, 2 lines, line height 16.
     - LazyRow padding 16×4, 12dp gap.
   - Fan (:215-229): posters at width × [−0.55, 0, 0.55] horizontally, rotated [−14°, 0, 14°], y [10, −2, 10]dp, size w×1.48w, radius 10. The middle poster is on top.
   - Below the cards: `Shelf("{emoji} {title}", more=route)` showing posters for the selected mood, sourceId `mood/{slug}`. Mood 0 is selected by default.
3. **ShuffleCard** (:274-323)
   - 16dp horizontal margin, radius 30.
   - Background: linear gradient [Brand 28%, `#9D8CFF` 22%, `#FF8FB1` 20%] plus glass, 16dp padding, 16dp gap.
   - Left: a 124×186 poster with radius 18, blurred 1.5dp while spinning. Changes slide in from the bottom.
   - Right column, 6dp gap:
     - Label "KHÔNG BIẾT XEM GÌ?", or "TMOVIE CHỌN CHO BẠN" after a pick. BrandLight, 12sp Bold.
     - Title: "Để TMovie chọn giúp", or the picked name. 20sp ExtraBold, line height 23, 3 lines.
     - Subtitle: "Lắc một cái, ra một phim đang hot.", or "{year} · {country} · {episode}". 13sp Secondary, 2 lines.
     - After a pick: `PlayFilmButton(capsule)`.
     - Spin button: "🎲 Chọn giúp tôi" on a white background with black text, or after a pick "🎲 Chọn lại" on white 14% with white text. 14sp Bold, min height 44, padding 16×12, capsule.
   - Spin: 16 random steps with a delay of `60 + step²×2` ms, then lands on a random HotList item.
4. **"Mới & Hot"** (:157-175)
   - Section title, 14dp gap.
   - Segmented control: full width minus 16dp margins, glass capsule, 4dp padding. 3 equal-weight segments, 14sp SemiBold, vertical padding 9.
     - Selected segment: white background, black text.
     - Segments (`NewHotScreen.kt:53-61`):
       - "🍿 Sắp chiếu": type `phim-sap-chieu`
       - "🔥 Đang chiếu": `phim-bo` where episodeCurrent starts with "Tập"
       - "✅ Trọn bộ": `phim-bo` where episodeCurrent contains "hoàn tất"
   - Shows the first 5 items as FeedCards. While empty, a 120dp-tall box with a Brand spinner.
   - **FeedCard** (`NewHotScreen.kt:104-123`): 16dp horizontal, 10dp gap.
     - Thumb at 16:9, radius 10, opens with sourceId `feed/{slug}`.
     - Below it a row:
       - Column: name 20sp Bold, 2 lines; meta line 12sp Secondary; genre line 12sp Medium Secondary.
       - Right: `SaveButton` in Column style.
     - Meta line (`model/Support.kt:41-47`): "★ 8.4 · {year} · {quality} · Phụ đề (if lang contains vietsub) · {episodeCurrent}".
     - Genre line (:50): first 3 genres joined with " • ".
5. **"Bộ sưu tập"** (:176-185): 2×2 grid, 16dp margins, 12dp gaps.
   - Collections (:90-95), title / subtitle / route / gradient:
     | Title | Subtitle | Route | Gradient |
     |---|---|---|---|
     | Hàn Quốc đang gây sốt | Những bộ ai cũng bàn tuần này | country han-quoc | `#FF5F6D`→`#7B2FF7` |
     | Cày một lèo | Phim bộ đã trọn, khỏi chờ tập | type phim-bo | `#1D976C`→`#2B5876` |
     | Kinh dị nửa đêm | Tắt đèn rồi hãy bấm | genre kinh-di | `#200122`→`#6F0000` |
     | Hoạt hình cả nhà | Cuối tuần cho bé và bố mẹ | type hoat-hinh | `#3D8BFF`→`#5B8CFF` |
   - CollectionCard (:257-271): 236dp tall, radius 26, 1dp border white 16%.
     - Fan of posters 60dp wide (list items 2–4), 12dp top.
     - Bottom gradient → black 55%.
     - Text bottom-left, 12dp padding: title 15sp ExtraBold, line height 18, 2 lines; subtitle in white 80%, 11sp, line height 14.

---

## 4. Search (`browse/SearchScreen.kt`)
- Three-column grid, 16dp side padding, 8dp horizontal and 10dp vertical gaps, 120dp bottom (:86-92).
- **Header** (:93-112): below the status bar, 8dp top, 12dp gap.
  - "Tìm kiếm" in Title style.
  - Material `TextField`, full width, radius 12, container white 10% (focused and unfocused), no indicator line.
  - Placeholder "Phim, diễn viên, tên gốc…"; leading Search icon; trailing Close icon "Xoá" while non-empty.
  - The field scrolls with the content (not sticky).
- **Behavior** (:79-84): only searches when the trimmed query is at least 2 characters, with a 400ms debounce. Uses `/tim-kiem?keyword=`. Query text is kept across navigation (rememberSaveable).
- **Results**: poster grid. Cells are PosterCards filling the cell, 2:3, sourceId `search/{slug}`. Pages load endlessly; the footer shows a spinner or an OutlinedButton "Thử lại" (`ui/Grids.kt:23-36`).
  - Empty state: "Không tìm thấy “{q}”" (curly quotes), Secondary, 24dp padding (:115-117).
- **Idle content** (:118-148):
  1. "Khám phá thể loại": all genres in two staggered rows (even indexes in row 0, odd in row 1). Horizontally scrolling, bleeding to the edges with 16dp padding, 8dp gaps.
     - Chip: 40dp tall, radius 10, glass, 16dp horizontal padding, SemiBold white text. Opens the genre list.
  2. "Tìm kiếm hàng đầu" (8dp top): list of `phim-moi-cap-nhat` page 1.
     - Row: thumb 140×78 radius 6 (shared element `top-search/{slug}`), name 15sp 2 lines with 12dp horizontal padding, PlayCircleOutline icon on the right. The whole row opens detail.

---

## 5. Catalog / list page (`browse/CatalogScreen.kt`, `FilterButton.kt`)
- Three-column grid, same paddings as Search.
- Background: wash = the featured film's tint at 40%, 800ms, gradient to Canvas at 0.5 (:100-110).
- **Top block** (:115-155): below the status bar, 12dp gap.
  1. Row: back button (40dp glass circle, ArrowBack, label "Quay lại") on the left, FilterButton on the right.
  2. `route.title` in Title style.
  3. Horizontally scrolling pills, 8dp gap:
     - Pill "{title}" with a 16dp ✕ ("Đóng"). Tapping it goes back.
     - On non-country pages, a country `GenrePickerPill` in filter mode. Shows the picked name with a filled white style.
     - On non-genre pages, a genre `GenrePickerPill` in filter mode.
     - Year pill: "Năm", or the year when picked (selected style). Opens a DropdownMenu with "Tất cả" then the current year down to 2000.
     - While any filter is set: a 34dp glass circle ✕ ("Bỏ lọc") that clears category, country and year.
- **Featured card**, when not filtering (:187-217):
  - First item of the list, 8dp horizontal padding, aspect 0.78, HeroShape (radius 14), 1dp border white 15%. Uses the thumb image. Gradient transparent at 0.4 → black 90%.
  - Bottom-center column, 16dp padding, 10dp gap: name in Title style centered, 2 lines; genre line in white 85% 13sp.
  - Then a row (10dp gap) of two equal buttons:
    - `PlayFilmButton(wide)`: "Phát", or "Tiếp tục".
    - `SaveButton(Wide)`: 46dp tall, radius 8, glass, icon plus " Danh sách" in 17sp SemiBold.
- **Shelves**, when not filtering (:173-185). Each slice that returns at least 4 films becomes a full-bleed `Shelf`:
  - Type/genre pages, by country: Hàn Quốc, Trung Quốc, Âu Mỹ, Nhật Bản, Thái Lan, Việt Nam.
  - Country pages, by genre: Hành động, Tình cảm, Cổ trang, Hài hước, Kinh dị.
- **Grid**: `RailHeader("Tất cả")`, or "Kết quả" while filtering, then an endless poster grid.
  - Pager: up to 4 pages per load, stopping once at least 8 new items are added (`ui/Pager.kt:46-71`).
  - Empty while filtered: "Không có phim · thử bỏ bớt bộ lọc" (Secondary, centered, 32dp padding).
- **FilterButton** (`FilterButton.kt:38-81`):
  - 40dp glass circle with a FilterList icon ("Bộ lọc"). Brand-tinted glass when any filter is set.
  - DropdownMenu root:
    - Sort options, ✓ on the active one: "Mới cập nhật" (sort_field null), "Năm phát hành" (`year`), "Mới thêm" (`_id`).
    - Divider.
    - "Năm[: y]" →
    - "Quốc gia" → (hidden on country pages)
    - "Thể loại" → (hidden on genre pages)
    - "Bỏ lọc" in `#FF6B6B`, while filtered.
  - Each submenu starts with "Tất cả" followed by its items (years: current down to 2000).
- **GenrePickerPill / PickerOverlay** (`ui/GenrePicker.kt:57-177`):
  - Label "Thể loại" / "Quốc gia" plus an 18dp KeyboardArrowDown.
  - Opens a full-screen dialog over black 88%. Centered list, 96dp top and 160dp bottom padding, 22dp gaps.
    - Selected option: 24sp Bold white. Others: 20sp Medium, white 60%.
    - Options rise in staggered: delay `min(i,14)×25ms`, 16dp rise, `cinematic()` motion.
  - Close button: 60dp white circle with a black ✕ ("Đóng"), bottom-center, 32dp above the nav bar.
  - In filter mode the first option is "Tất cả" (null).
  - Outside filter mode, picking an option opens that genre or country page.

---

## 6. Film detail (`detail/DetailScreen.kt`, `EpisodeList.kt`)
Three-column grid on a Canvas background, 120dp bottom padding, 8/10dp gaps (:120-127). Loads the detail, people (TMDB) and images in parallel. Similar = genre list of the first category, excluding this film (:98-110).

Top to bottom:
1. **Header art** (:128-146):
   - Full width at 16:10. Shared element keyed by the route's sourceId.
   - Parallax: translateY = scrollOffset × 0.3.
   - Image: the thumb, falling back to `route.thumb` (shown before the detail loads).
   - Gradient: black 60% at 0 → transparent at 0.3 → transparent at 0.6 → Canvas at 1.
2. **Title block** (:147-173): 16dp horizontal, 10dp gap.
   - Name in Title style, using `route.name` until the detail loads.
   - originName in Secondary 15sp, if not blank.
   - **MetaRow** (:240-252), 8dp gap:
     - "★ {x.x}" in `#FFD60A` 13sp.
     - Year in Secondary 13sp.
     - Quality badge: Secondary 11sp Bold, 1dp Secondary border, radius 3, padding 5×1.
     - episodeCurrent, 13sp.
     - time, 13sp.
   - **PlayWide**: "Phát", or "Tiếp tục {episodeName}" if the film is in history. Disabled until the detail loads.
     - Toast if nothing plays: "Phim này chưa có link phát".
   - On load failure: "Không tải được phim · Thử lại" in BrandLight. Tapping retries.
   - Synopsis: HTML converted to text, 15sp white, 3 lines. Tap toggles expanded, with an animated size change.
   - **Credits** (:255-273), 12sp, 1 line each, label in Secondary and names in white 55%:
     - "Diễn viên: {first 4 actors}", skipping "Đang cập nhật".
     - "Đạo diễn: {TMDB Directing names, else director[]}".
3. **Actions row** (:174-185): 16dp horizontal, 28dp gap.
   - `SaveButton(Column)`: icon plus "Danh sách" in 11sp Secondary, min 64×48, 4dp gap. Accessibility label "Thêm vào danh sách" / "Bỏ khỏi danh sách".
   - "Chia sẻ" (Send icon): shares the text "{name} ({originName}) — đang xem trên TMovie".
   - "Trailer" (Movie icon): only when trailerUrl is set; opens it externally.
   - Action style (:276-281): icon over an 11sp Secondary label, 4dp padding.
4. **Cast row**, if any TMDB Acting people (:186-197): LazyRow, 16dp padding, 14dp gap.
   - Each item 72dp wide: 64dp circular photo (w185), name 11sp SemiBold, character 11sp Secondary, 1 line each.
5. **Tabs** (:198-212): 16dp horizontal, 8dp top, 24dp gap.
   - Tabs: "Tập phim" (only if any server has more than 1 episode), "Tương tự", "Hình ảnh" (only if backdrops exist).
   - Each tab: a 40×4dp bar on top (Brand when active, else transparent), then the Bold label 10dp below (white when active, else Secondary).
6. **Tab content**:
   - **Episodes** (`EpisodeList.kt`):
     - Opens on the last-watched server and its range.
     - Controls row (16dp horizontal, 10dp gap):
       - Server dropdown, only with more than 1 server. Label is the server name or "Server {n}".
       - Range dropdown, only with more than 50 episodes. Ranges are chunks of 50, labelled "Tập {a}–{b}" (en dash).
       - Dropdown style (:98-112): 36dp tall, radius 8, glass, 14dp horizontal padding, 15sp SemiBold plus a ⌄ icon.
     - Episode row (:72-92): 16dp horizontal, 12dp gap.
       - Still: 128×72 radius 6. Image is the TMDB backdrop `stills[i % n]` at w300, else the film thumb.
       - Centered 32dp glass circle with an 18dp play icon.
       - `ProgressStrip` at the bottom if there's progress.
       - Text: ep.name (or "Tập {i+1}"), 15sp SemiBold. Under it "Đang xem" in Brand 12sp SemiBold on the last-watched episode.
       - Episodes without an m3u8 are at alpha 0.4 and can't be tapped.
       - Tapping plays that server and index.
   - **Similar** (:217-224): rows of 3 PosterCards filling equal widths, 16dp padding, 8dp gaps.
   - **Images** (:225-229): backdrops at w780, full width at 16:9, radius 8, 16dp padding.
7. **Floating back button** (:232-235): below the status bar, 12dp padding, 44dp glass circle, ArrowBack ("Quay lại"). Stays fixed while scrolling.

---

## 7. Của tôi / Profile (`profile/ProfileScreen.kt`, `ui/AccountCard.kt`)
Three-column grid, 16dp side padding, 120dp bottom padding.

1. **Header** (:83-103): below the status bar, 8dp top, 12dp bottom, 16dp gap.
   - "Của tôi" in Title style.
   - Avatar row:
     - 64dp square avatar, radius 12, linear gradient Brand → `#5B5BD6`. Shows the first letter of the name, uppercased, 28sp Bold.
     - 14dp to the right, a column:
       - An inline editable name (BasicTextField, 22sp Bold, Brand cursor). Saved to `Settings.profileName`, default "Bạn".
       - "{saved} phim đã lưu · {history} phim đã xem" in Secondary 14sp.
   - **AccountCard** (`ui/AccountCard.kt`). Hidden entirely when Firebase isn't configured.
     - Signed out (:55-71): full width, 52dp tall, radius 14, white background. A "G" in `#4285F4` 20sp Black, then "  Đăng nhập với Google để đồng bộ" in black SemiBold. A spinner while busy.
       - Failure toast: "Đăng nhập chưa hoàn tất, thử lại nhé."
     - Signed in (:73-86): glass, radius 14, 12dp padding.
       - 40dp circular photo (falls back to an AccountCircle icon).
       - Name (or "Tài khoản Google"), SemiBold, 1 line.
       - "Đã đồng bộ · {email}" in Secondary 12sp.
       - Logout icon button on the right ("Đăng xuất", 8dp padding). This is the only logout control.
2. **"Xem gần đây"**, if history is non-empty (:104-106): full-bleed Shelf with up to 20 ContinueCards.
3. **"Danh sách của tôi"** header (`RailHeader`, no "Tất cả") (:107).
   - Empty: "Nhấn + Danh sách ở một bộ phim để lưu lại." (Secondary 14sp).
   - Otherwise a 3-column PosterCard grid, sourceId `profile-list/{slug}`.
4. **Settings card** (:111-129): 16dp top, radius 16, glass. Rows are separated by dividers inset 52dp from the start, white 10%.
   - Slideshow icon, "Tự phát xem trước", Switch (checked track Brand). Bound to `Settings.heroAutoplay`, prefs `settings`, key `heroAutoplay`, default true. Row padding 16×8.
   - History icon, "Xoá lịch sử xem", chevron (white 40%).
   - DeleteOutline icon, "Xoá danh sách của tôi", chevron.
   - Info icon, "Phiên bản", with the versionName right-aligned in Secondary.
   - SettingRow style (:147-154): 16dp padding, icon, 12dp, title.
5. **Confirm dialog** (:132-143), Material AlertDialog:
   - Title "Xoá lịch sử xem?" or "Xoá danh sách của tôi?".
   - Confirm "Xoá" in `#FF6B6B`; dismiss "Huỷ".

All Settings keys (`data/Settings.kt`, prefs file `settings`):
| Key | Default |
|---|---|
| `heroAutoplay` | true |
| `heroMuted` | true |
| `onboarded` | false |
| `profileName` | "Bạn" |

---

## 8. Player (`player/`)
- Full screen, forced landscape (`sensorLandscape`, singleTask; `core/player/src/main/AndroidManifest.xml:10-11`).
- System bars hidden, video drawn under the display cutout. Black background.
- `Player.start` resumes the last-watched episode (the history record's server and index), else plays the first playable episode. Returns false if nothing plays (`player/Player.kt:40-56`).

**Resume and save** (`PlayerActivity.kt:153-224`)
- Seeks to the saved position if it's over 5s and more than 20s before the end.
- Saves when the episode starts, every 10s while playing, on episode switch, on stop and on destroy.
- A paused frame (about 640px wide JPEG) becomes the "Xem tiếp" card still. Only taken past 3s.
- Keeps the screen awake while playing.

**Controls auto-hide** (:227-231): hide 3000ms after the last interaction, while playing and no panel is open.
- Tapping the surface: closes an open panel, else toggles the controls.
- Back: closes a panel, or unlocks if locked.

**Error recovery** (:192-207): network errors (codes 2000–2999) wait for connectivity, then seek to the same position and retry.

**Overlays** (`PlayerControls.kt:110-216`)
- Scrim while the controls are visible: black 70% at 0 → transparent at 0.25 → transparent at 0.7 → black 80% at 1.
- Offline banner (:117-120, :349-361):
  - Top-center, 72dp from the top, slides down.
  - Capsule `#E6101418` plus glass, padding 18×10.
  - WifiOff icon (20dp `#FFB74D`) pulsing alpha 0.4↔1 every 700ms.
  - Text "Mất kết nối mạng · sẽ tự phát lại khi có mạng" (14sp Medium).
- Buffering: centered 56dp BrandLight spinner, 3dp stroke.
- Locked (:129-134): everything is hidden except a 56dp lock button ("Mở khoá") at center-start, 32dp in. It fades with the controls.
- **Top bar** (:137-156): padding 24×16, slides down.
  - Back button (44dp RoundIcon, "Quay lại").
  - Title column (14dp horizontal padding): film name 17sp Bold, 1 line. Under it, episodeName and the sleep label joined with " · ", Secondary 13sp. Sleep label is "Hẹn giờ: {n} phút" or "Hẹn giờ: hết tập".
  - Right side, 10dp gaps:
    - Speed chip "{x}×", only when speed ≠ 1. Opens settings.
    - "Thông tin phim" (Info), only when the player wasn't opened from the detail page. Opens `tmovie://phim/{slug}` and closes the player.
    - "Khoá màn hình" (LockOpen)
    - "Hình trong hình" (PictureInPictureAlt)
    - "Cài đặt" (Settings)
    - "Danh sách tập" (VideoLibrary), only if the film has more than 1 episode or more than 1 server.
- **Center** (:159-177): 48dp gaps, fades and scales from 0.9.
  - Replay10 (56dp, "Lùi 10 giây"): −10s.
  - Play/Pause/Replay: 84dp glass circle with a 44dp icon, cross-fading by scale.
  - Forward10 (56dp, "Tới 10 giây"): +10s.
- **Error card** (:180-189): centered, glass, radius 20, 24dp padding, 12dp gaps.
  - "Không phát được tập này" (17sp SemiBold).
  - "Thử lại hoặc đổi server trong danh sách tập." (13sp Secondary).
  - Chips: "Thử lại" (highlighted) and "Đổi server" (opens the episodes panel).
- **Bottom bar** (:195-215): padding 24×16, slides up.
  - SeekBar (:233-271):
    - 32dp touch area, 4dp track.
    - Track white 20%, buffered white 35%, played gradient Brand→BrandLight.
    - Thumb: white circle, 12dp, growing to 18dp while dragging.
    - Tap seeks. While dragging, a bubble above the thumb shows the time: white background, black 13sp Bold, radius 8, y −30dp.
  - Row below (6dp top):
    - "{pos} / {dur}" (13sp). Format is `m:ss`, or `h:mm:ss` from one hour (`PlaybackState.kt:143-149`).
    - Right side: SkipNext icon (20dp) plus " Tập tiếp" (14sp SemiBold), when there's a next playable episode.
- **RoundIcon** (:364-368): glass circle, default 44dp, icon at 50% of the size.
- **Chip** (:371-382): 14sp SemiBold, padding 14×8, capsule. Highlighted: white background with black text. Otherwise white 14% with white text.

**Gestures** (`PlayerGestures.kt`)
- Single tap: toggles controls.
- Double-tap on the left or right half seeks ∓10s. Repeated taps within 900ms on the same side add up in the bubble (+10, +20…), and each tap seeks another 10s (:47-55).
  - Bubble (`PlayerControls.kt:301-321`): 35% of the screen width on that side, full height, the inner side rounded 50%, white 12%. Shows a 40dp Forward10/Replay10 icon and "+{n}s" or "−{n}s" in Bold. Disappears 700ms after the last tap.
- Horizontal drag scrubs: a full-width swipe is 90s. The HUD shows "{target}  (+{delta})" (18sp Bold), and the seek happens on release (:103-108, :119).
- Vertical drag: left half = brightness, right half = volume. Level = start − dy/(height×0.8), clamped 0–1.
  - HUD (:340-346): icon, a 160×6dp bar with a BrandLight fill, and "{pct}%".
  - HUD box: `#CC101418` plus glass, radius 16, padding 18×12.
- Pinch: zoom in above 1.15, back to fit below 0.87 (:120).
- Gestures are disabled while locked or while a panel is open.

**Next-episode card** (`PlayerControls.kt:274-297`)
- Shows during the last 18000ms, if there's a next episode, the duration is over 60s, and it hasn't been cancelled.
- When the episode ends it auto-plays the next one unless cancelled. If the sleep timer is set to "Hết tập này", it pauses instead (`PlayerActivity.kt:243-245`, :294).
- Position: bottom-end, 24dp from the right, 110dp from the bottom while controls show, else 32dp. Slides in horizontally.
- Card: 360dp wide, radius 18, `#E6101418` plus glass, 12dp padding.
  - Thumb 120×68 radius 10 with a black 30% overlay and the seconds remaining (22sp Black).
  - Column (12dp padding, 6dp gap):
    - "TẬP TIẾP THEO" (BrandLight 11sp Bold, letter-spacing 1).
    - Next episode name (15sp SemiBold).
    - Chips "Phát ngay" (highlighted) and "Huỷ".

**Panels** (`PlayerPanels.kt`)
- Slide in from the right: full height, 400dp wide, `#F20B0F12`, padding 20×16, 14dp gaps.
- Header: title (18sp Bold) plus a ✕ ("Đóng").
- Section style: title uppercased (12sp Bold Secondary, letter-spacing 1), then a horizontally scrolling row of option chips. Selected chip: white background, black text; others white 10%. 14sp SemiBold, padding 14×8.
- **"Cài đặt phát"** (:95-111), sections in order. Empty sections are hidden.
  1. "Tốc độ": 0.5×, 0.75×, "Bình thường", 1.25×, 1.5×, 2×.
  2. "Chất lượng": "Tự động" plus "{h}p" per rendition, highest first. Only if there are 2 or more renditions.
  3. "Âm thanh": track labels, or the language uppercased, or "Track n". Only if there are 2 or more tracks.
  4. "Phụ đề": "Tắt" plus the tracks.
  5. "Khung hình": "Vừa" (fit), "Phóng" (zoom/cover), "Giãn" (fill/stretch).
  6. "Hẹn giờ tắt": "Tắt", "15 phút", "30 phút", "45 phút", "60 phút", "Hết tập này" (:48).
- **"Danh sách tập"** (:114-156):
  - "Server" section, only with 2 or more servers.
  - 3-column grid with 8dp gaps. Cells are 44dp tall, radius 10. The current episode is Brand, others white 10%.
  - Cell label is ep.name or the number. Episodes without a link are at alpha 0.3 and disabled.
  - Opens scrolled to the current episode minus 6.

**PiP**: 16:9, auto-enters on Android 12+. On web, `requestPictureInPicture` is the equivalent.

**Live mode** (`LiveScreen`, :331-429): not reachable on the phone (see the top of this spec).

---

## 9. Shared components (`ui/FilmCards.kt`, `ui/Actions.kt`)
- **PosterCard** (:75-100):
  - 112dp wide by default (fills the cell in grids), 2:3, CardShape (radius 8), pressScale. Shared element `film-{sourceId}`.
  - Episode badge at the top-left when episodeCurrent isn't blank or "full": "Hoàn Tất" is replaced by "Trọn bộ". 10sp Bold white on Brand, bottom-end corner radius 8, padding 6×3.
  - No title under the poster.
- **RailHeader** (:104-115): 16dp horizontal; SectionTitle on the left. When the rail has a route, the right side shows "Tất cả" (Secondary 15sp) plus a KeyboardArrowRight icon, opening the list.
- **Shelf** (:119-131):
  - Column with a 10dp gap: RailHeader, then a LazyRow with 16dp content padding and 8dp item gaps (14dp for "Xem tiếp").
  - Rises once on first show: alpha 0→1 and translateY 28dp→0, `cinematic()` motion.
- **ContinueCard** (:139-198):
  - 286dp wide, 8dp gap between the image and the title.
  - Image: 16:9, radius 20, 1dp border white 12%. Uses the saved paused frame, else the thumb. Gradient from 0.5 → black 72%.
  - Centered 52dp glass play button with a 26dp icon ("Tiếp tục xem"), or a spinner while loading.
  - Episode chip at the top-left, 10dp margin: glass capsule, 12sp Bold, padding 9×3. A purely numeric episode name becomes "Tập {n}".
  - Bottom row (padding 12×10, 10dp gap): a 4dp white-30% track with a white fill of at least 3%, then "Còn {n} phút" (11sp SemiBold). Minutes left = max(1, floor((duration − position)/60)).
  - Title below: Secondary 14sp SemiBold, 1 line, 2dp start padding.
  - Tapping fetches the detail and resumes playback directly; it doesn't open the detail page.
- **SaveButton** (`Actions.kt:51-83`): toggles `Library.saved` with a LongPress haptic.
  - Icon is + or ✓. Accessibility label "Thêm vào danh sách" / "Bỏ khỏi danh sách".
  - Styles: Column (detail, feed), Wide (featured card), Circle (hero).
- **PlayFilmButton** (`Actions.kt:87-105`): fetches the detail, then `Player.start`. Failure toast: "Phim này chưa có link phát".
  - Capsule style: "Xem ngay" / "Xem tiếp".
  - Wide style: "Phát" / "Tiếp tục".
- **Content policy** (`net/../model/ContentPolicy.kt`): 18+ titles (genre slugs `phim-18`, `18-plus`) are hidden unless the account's Firestore `entitlements/{uid}.allowAdult` is true. Trailer-only items (episodeCurrent "trailer") are dropped everywhere except "Sắp chiếu" (`net/PhimApi.kt:43-45`, :111-121).
- **API** (`net/PhimApi.kt`):
  - Base `https://phimapi.com/v1/api`:
    - `/danh-sach/{slug}`, `/the-loai/{slug}`, `/quoc-gia/{slug}`, `/tim-kiem?keyword=`
    - Query params: `page`, `category`, `country`, `year`, `sort_field`
    - `/phim/{slug}`, `/phim/{slug}/images`, `/phim/{slug}/peoples`
  - Taxonomy at the site root: `/the-loai`, `/quoc-gia`.
  - Images (`model/Support.kt:30-38`): `https://phimimg.com/` + path (paths without a slash go under `uploads/movies/`). TMDB images: `https://image.tmdb.org/t/p/{size}{path}`.

---

## 10. Access gate (`ui/AccessGateScreen.kt`, `data/AccessGate.kt`)
- Wraps the whole app. While locked, shows GoogleGate on the phone (Firebase available), else the name + email form (:59-67).
- **GateFrame** (:116-137):
  - Canvas background plus a Brand 35% radial glow from the top-left (radius 1100px). Content centered, IME-aware.
  - Column: max width 440, 28dp padding, 14dp gap, scrollable.
  - Contents: Wordmark at 34sp; title 22sp Bold (8dp top); message Secondary 15/21sp centered; actions; error line in `#FF8A80` 14sp.
- **GoogleGate states** (:70-112):
  1. Signed out:
     - Title "App riêng tư".
     - Message "TMovie chỉ dành cho bạn bè của chủ app. Đăng nhập Google rồi xin vào, chủ app duyệt là bạn xem được ngay."
     - Button "Đăng nhập bằng Google" (or "Đang đăng nhập…").
     - Error: "Chưa đăng nhập được, thử lại nhé."
  2. Signed in, no request yet:
     - Title "App riêng tư".
     - Message "Bạn đang đăng nhập bằng {email}. Gửi yêu cầu để chủ app duyệt."
     - Button "Gửi yêu cầu" (or "Đang gửi…").
     - Error: "Không gửi được, kiểm tra mạng rồi thử lại nhé."
     - Text link "Dùng tài khoản khác".
  3. Pending:
     - Title "Đang chờ duyệt…".
     - Message "Đã gửi yêu cầu. Chủ app duyệt xong là app tự mở, và bạn nhận mail báo ở {email}."
     - Text link "Huỷ yêu cầu, dùng tài khoản khác". This forgets the request and signs out.
  - The gate unlocks when Firestore `members/{uid}` exists, via a live snapshot listener (`data/Account.kt:74-82`). There's no polling in this mode.
- **Form variant** (no Firebase, :157-215):
  - Fields "Tên của bạn" (max 40 chars) and "Email" (max 100, regex `^[^@\s]+@[^@\s]+\.[^@\s]+$`). OutlinedTextFields, focused border BrandLight, unfocused white 25%.
  - Button "Gửi yêu cầu", enabled only when both are valid.
  - Pending state shows the text link "Gửi lại yêu cầu".
  - Polls `check()` every 10000ms. On expiry: error "Yêu cầu đã hết hạn, gửi lại nhé."
  - TextLink style: 15sp Secondary, capsule, padding 16×10.
- **Endpoint** (`data/AccessGate.kt:31`): `https://script.google.com/macros/s/AKfycbzM71C8tRgkWqKWYBpr97IcZCOkouZTTU55rWiU1n4g3MZHEq8dm9B9pHd6SC4kicSk-Q/exec`. JSON POST; the redirect is followed.
  - `{action:"request", name, email, platform, device:"{MANUFACTURER} {MODEL}", uid?}` → `{ok, id}`. Stores email, id and requestedAt (:63-69).
  - `{action:"status", id}`:
    - `ok` → unlocked; stores `member=id`.
    - `pending` → Pending.
    - anything else → Expired; forgets the request (:72-84).
  - `{action:"member", id}`, at launch when Firebase isn't available. Re-locks if not `ok`; staying offline keeps it open (:58-61).
  - A request expires after 48h (TTL, :32).
  - Prefs file `access`, keys `unlocked`, `email`, `id`, `requestedAt`, `member`.
- Sync once signed in (`data/LibrarySync.kt`): Firestore `users/{uid}/favorites`, `history`, `playback` (docs keyed `{slug}_{episodeName}`, field `position`).

---

## Key files
- `android/app/src/main/kotlin/com/thientech/tmovie/AppNavHost.kt`
- `android/app/src/main/kotlin/com/thientech/tmovie/MainActivity.kt`
- `android/feature/home/src/main/kotlin/com/thientech/tmovie/feature/home/` (`HomeScreen.kt`, `Hero.kt`, `HeroPreview.kt`, `HomeViewModel.kt`, `Motion.kt`)
- `android/feature/browse/src/main/kotlin/com/thientech/tmovie/feature/browse/` (`ExploreScreen.kt`, `NewHotScreen.kt`, `SearchScreen.kt`, `CatalogScreen.kt`, `FilterButton.kt`)
- `android/feature/detail/src/main/kotlin/com/thientech/tmovie/feature/detail/` (`DetailScreen.kt`, `EpisodeList.kt`)
- `android/feature/profile/src/main/kotlin/com/thientech/tmovie/feature/profile/ProfileScreen.kt`
- `android/feature/onboarding/src/main/kotlin/com/thientech/tmovie/feature/onboarding/` (`SplashScreen.kt`, `OnboardingScreen.kt`)
- `android/core/ui/src/main/kotlin/com/thientech/tmovie/core/ui/` (`FilmCards.kt`, `Actions.kt`, `GenrePicker.kt`, `Grids.kt`, `Pager.kt`, `AccountCard.kt`, `AccessGateScreen.kt`, `UpdatePrompt.kt`, `Navigation.kt`)
- `android/core/designsystem/src/main/kotlin/com/thientech/tmovie/core/designsystem/` (`Theme.kt`, `Glass.kt`, `Components.kt`, `ColorSampler.kt`)
- `android/core/player/src/main/kotlin/com/thientech/tmovie/core/player/` (`PlayerActivity.kt`, `PlayerControls.kt`, `PlayerPanels.kt`, `PlayerGestures.kt`, `PlaybackState.kt`, `Player.kt`, `StreamPlayer.kt`)
- `android/core/data/src/main/kotlin/com/thientech/tmovie/core/data/` (`AccessGate.kt`, `Account.kt`, `Settings.kt`, `Library.kt`, `LibrarySync.kt`, `AppUpdater.kt`)
- `private/android/core/network/src/main/kotlin/com/thientech/tmovie/core/network/` (`PhimApi.kt`, `HotList.kt`)
