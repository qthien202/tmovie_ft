# API Documentation

## PhimAPI V1 API (KKPhim)

**Base URL**: `https://phimapi.com/v1/api`
**Image CDN**: `https://phimimg.com/` (or `https://phimimg.com/uploads/movies/`)

## Endpoints

### 1. Film List by Type

```
GET /v1/api/danh-sach/{type_slug}?page={N}
```

**Type slugs**: `phim-moi-cap-nhat`, `phim-bo`, `phim-le`, `tv-shows`, `hoat-hinh`, `phim-vietsub`, `phim-thuyet-minh`, `phim-long-tieng`, `phim-bo-dang-chieu`, `phim-bo-hoan-thanh`, `phim-sap-chieu`

**Response**: `FilmListResponse`

### 2. Film Detail

```
GET /v1/api/phim/{slug}
```

**Response**: `FilmDetailResponse` (includes episodes with streaming links)

### 3. Search Films

```
GET /v1/api/tim-kiem?keyword={keyword}&page={N}
```

**Response**: `FilmListResponse`

### 4. Films by Genre

```
GET /v1/api/the-loai/{slug}?page={N}
```

**Response**: `FilmListResponse`

### 5. Films by Country

```
GET /v1/api/quoc-gia/{slug}?page={N}
```

**Response**: `FilmListResponse`

## Response Models

### FilmListResponse

```json
{
  "status": "success",
  "msg": "",
  "data": {
    "seoOnPage": {...},
    "breadCrumb": [...],
    "titlePage": "...",
    "items": [
      {
        "_id": "...",
        "name": "Tên phim",
        "slug": "ten-phim",
        "origin_name": "Original Name",
        "type": "series",
        "thumb_url": "ten-phim-thumb.jpg",
        "poster_url": "ten-phim-poster.jpg",
        "sub_docquyen": false,
        "chieurap": false,
        "time": "45 phút/tập",
        "episode_current": "Hoàn Tất (16/16)",
        "quality": "HD",
        "lang": "Vietsub",
        "year": 2024,
        "category": [{"id": "...", "name": "Hành động", "slug": "hanh-dong"}],
        "country": [{"id": "...", "name": "Hàn Quốc", "slug": "han-quoc"}]
      }
    ],
    "params": {
      "type_slug": "phim-bo",
      "pagination": {
        "totalItems": 1000,
        "totalItemsPerPage": 24,
        "currentPage": 1
      }
    }
  }
}
```

### FilmDetailResponse

```json
{
  "status": true,
  "msg": "",
  "data": {
    "seoOnPage": {...},
    "breadCrumb": [...],
    "item": {
      "_id": "...",
      "name": "Tên phim",
      "slug": "ten-phim",
      "origin_name": "Original Name",
      "content": "<p>Mô tả phim...</p>",
      "type": "series",
      "status": "completed",
      "thumb_url": "...",
      "poster_url": "...",
      "trailer_url": "...",
      "time": "45 phút/tập",
      "episode_current": "Hoàn Tất (16/16)",
      "episode_total": "16 Tập",
      "quality": "HD",
      "lang": "Vietsub",
      "year": 2024,
      "view": 12345,
      "actor": ["Actor 1", "Actor 2"],
      "director": ["Director 1"],
      "category": [...],
      "country": [...],
      "episodes": [
        {
          "server_name": "Server #1",
          "server_data": [
            {
              "name": "Tập 1",
              "slug": "tap-1",
              "filename": "...",
              "link_embed": "https://...",
              "link_m3u8": "https://..."
            }
          ]
        }
      ]
    }
  }
}
```

## Image URLs

Thumbnail/poster URLs từ API có thể là:
- **Relative**: `ten-phim-thumb.jpg` → prepend CDN: `https://img.ophim.live/uploads/movies/ten-phim-thumb.jpg`
- **Absolute**: `https://...` → sử dụng trực tiếp

Logic xử lý nằm trong `FilmItem.fullThumbUrl` và `FilmDetail.fullThumbUrl`.
