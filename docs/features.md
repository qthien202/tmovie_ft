# Features

## Mobile App

### Trang chủ (Home)
- TabBar với 11 loại phim (Mới nhất, Phim bộ, Phim lẻ, TV Shows, Hoạt hình, ...)
- Carousel slider cho 6 phim đầu tiên mỗi tab
- Film grid hiển thị danh sách phim
- Pull-to-refresh
- Nút "Xem thêm" dẫn đến trang danh sách đầy đủ

### Tìm kiếm (Search)
- Debounced search (500ms delay)
- Hiển thị kết quả dạng grid
- Hỗ trợ pagination
- Nút xóa keyword

### Chi tiết phim (Detail)
- Poster/thumbnail lớn với gradient overlay
- Thông tin phim: tên, tên gốc, năm, chất lượng, ngôn ngữ, thời lượng
- Danh sách thể loại (chips)
- Đạo diễn, diễn viên
- Nội dung phim (HTML rendered)
- Chọn server (nếu có nhiều server)
- Danh sách tập phim với nút phát

### Video Player
- Chewie player (dựa trên video_player)
- Tự động chuyển landscape khi vào player
- Immersive mode (ẩn status bar)
- Controls: play/pause, seek, fullscreen
- Error handling với nút quay lại

### Danh sách phim (Film List)
- Hiển thị phim theo type slug
- Pagination bar

### Thể loại (Genre)
- Hiển thị phim theo genre slug
- Pagination bar

### Navigation
- Bottom navigation bar (GNav): Trang chủ, Tìm kiếm
- GoRouter với ShellRoute cho bottom nav persistence

## TV App

### Trang chủ (TV Home)
- Left sidebar: danh sách loại phim + nút tìm kiếm
- Main content: grid 5 cột
- Focus animation: scale 1.05x + primary border khi focus
- D-pad navigation support

### Chi tiết phim (TV Detail)
- Layout 2 cột: poster trái + info/episodes phải
- Focus-based episode selection
- Nút phát với D-pad select

### Video Player (TV)
- Fullscreen player
- Chewie controls
- Back button support

### Tìm kiếm (TV Search)
- Text field với autofocus
- Grid kết quả với focus animation
- D-pad navigation

## Shared Features (Core)

### Networking
- Dio HTTP client với PrettyDioLogger (debug)
- Retrofit auto-generated API client
- 5 API endpoints: films by type, detail, search, by genre, by country

### Data Models
- json_serializable auto-generated fromJson/toJson
- Image URL handling (relative → absolute CDN URL)

### Local Storage
- Watch history (SharedPreferences, max 50 entries)
- Playback position tracking

### UI Components
- AppImage: CachedNetworkImage với shimmer placeholder
- FilmCard: thumbnail + name + episode badge
- FilmGrid: responsive grid layout
- PaginationBar: page navigation
- ShimmerLoading: loading placeholder
