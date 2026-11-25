//! PhimAPI (https://phimapi.com/v1/api) and the hot list, same endpoints and filters as the apps' PhimApi.

use std::cell::RefCell;
use std::collections::HashMap;

use serde::{Deserialize, Deserializer, Serialize};
use serde_json::Value;

pub const API: &str = "https://phimapi.com/v1/api";
const HOT: &str = "https://raw.githubusercontent.com/qthien202/tmovie_ft/hot-data/hot.json";

/// Accepts a number, a numeric string or nothing.
fn loose_i64<'de, D: Deserializer<'de>>(d: D) -> Result<Option<i64>, D::Error> {
    Ok(match Value::deserialize(d)? {
        Value::Number(n) => n.as_i64(),
        Value::String(s) => s.trim().parse().ok(),
        _ => None,
    })
}

fn loose_string<'de, D: Deserializer<'de>>(d: D) -> Result<Option<String>, D::Error> {
    Ok(match Value::deserialize(d)? {
        Value::String(s) => Some(s),
        Value::Number(n) => Some(n.to_string()),
        _ => None,
    })
}

#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
pub struct Category {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub slug: Option<String>,
}

#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
pub struct Rating {
    #[serde(default, deserialize_with = "loose_string")]
    pub id: Option<String>,
    #[serde(default, rename = "type")]
    pub kind: Option<String>,
    #[serde(default)]
    pub vote_average: Option<f64>,
}

/// A list item (`/danh-sach`, `/the-loai`, `/quoc-gia`, `/tim-kiem`).
#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
pub struct Film {
    pub name: String,
    pub slug: String,
    #[serde(default)]
    pub origin_name: Option<String>,
    #[serde(default, rename = "type")]
    pub kind: Option<String>,
    #[serde(default)]
    pub thumb_url: Option<String>,
    #[serde(default)]
    pub poster_url: Option<String>,
    #[serde(default)]
    pub time: Option<String>,
    #[serde(default)]
    pub episode_current: Option<String>,
    #[serde(default)]
    pub quality: Option<String>,
    #[serde(default)]
    pub lang: Option<String>,
    #[serde(default, deserialize_with = "loose_i64")]
    pub year: Option<i64>,
    #[serde(default)]
    pub category: Vec<Category>,
    #[serde(default)]
    pub country: Vec<Category>,
    #[serde(default)]
    pub tmdb: Option<Rating>,
    #[serde(default)]
    pub imdb: Option<Rating>,
}

#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
pub struct Episode {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub slug: Option<String>,
    #[serde(default)]
    pub link_m3u8: Option<String>,
}

#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
pub struct Server {
    #[serde(default)]
    pub server_name: Option<String>,
    #[serde(default)]
    pub server_data: Vec<Episode>,
}

/// `/phim/{slug}` → `data.item`.
#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
pub struct Detail {
    #[serde(flatten)]
    pub film: Film,
    #[serde(default)]
    pub content: Option<String>,
    #[serde(default)]
    pub status: Option<String>,
    #[serde(default)]
    pub trailer_url: Option<String>,
    #[serde(default, deserialize_with = "loose_string")]
    pub episode_total: Option<String>,
    #[serde(default, deserialize_with = "loose_i64")]
    pub view: Option<i64>,
    #[serde(default)]
    pub actor: Vec<String>,
    #[serde(default)]
    pub director: Vec<String>,
    #[serde(default)]
    pub episodes: Vec<Server>,
}

impl Detail {
    /// Servers that have at least one playable (HLS) episode.
    pub fn servers(&self) -> Vec<Server> {
        self.episodes.iter().filter(|s| s.server_data.iter().any(|e| e.stream().is_some())).cloned().collect()
    }
}

impl Episode {
    pub fn stream(&self) -> Option<&str> {
        self.link_m3u8.as_deref().filter(|s| !s.trim().is_empty())
    }
}

#[derive(Clone, Debug, Default)]
pub struct Page {
    pub items: Vec<Film>,
    pub total_pages: i64,
}

#[derive(Clone, Debug, Default)]
pub struct Hot {
    pub week: Option<String>,
    /// All hot titles, ranked (series and films interleaved by rank).
    pub films: Vec<Film>,
    /// Series only, ranked: the Top 10 row.
    pub series: Vec<Film>,
}

/// Where a list comes from, same as the apps' `Source`.
#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub enum Source {
    Type(String),
    Genre(String),
    Country(String),
    Search(String),
}

#[derive(Clone, Debug, Default, PartialEq, Eq, Hash)]
pub struct Filter {
    pub category: Option<String>,
    pub country: Option<String>,
    pub year: Option<i64>,
    /// `sort_field`: None (mới cập nhật), "year", "_id".
    pub sort: Option<String>,
}

impl Film {
    pub fn thumb(&self) -> String { img_url(self.thumb_url.as_deref()) }
    pub fn poster(&self) -> String { img_url(self.poster_url.as_deref()) }
    pub fn is_trailer(&self) -> bool { self.episode_current.as_deref().map(|e| e.eq_ignore_ascii_case("trailer")).unwrap_or(false) }
    pub fn is_adult(&self) -> bool { self.category.iter().any(|c| matches!(c.slug.as_deref(), Some("phim-18") | Some("18-plus"))) }
    pub fn is_animation(&self) -> bool {
        self.kind.as_deref() == Some("hoathinh")
            || self.category.iter().any(|c| c.slug.as_deref() == Some("hoat-hinh") || c.name.as_deref().unwrap_or("").to_lowercase().contains("hoạt hình"))
    }
    pub fn rating(&self) -> Option<f64> {
        [self.tmdb.as_ref(), self.imdb.as_ref()].into_iter().flatten().filter_map(|r| r.vote_average).find(|v| *v > 0.0)
    }
    /// "Phim bộ", "Phim lẻ"…
    pub fn kind_label(&self) -> Option<&'static str> {
        match self.kind.as_deref() {
            Some("series") => Some("Phim bộ"),
            Some("single") => Some("Phim lẻ"),
            Some("tvshows") => Some("TV Show"),
            Some("hoathinh") => Some("Hoạt hình"),
            _ => None,
        }
    }
    /// Episode badge: "Tập 11", "Trọn bộ (8/8)"; none for "Full".
    pub fn badge(&self) -> Option<String> {
        self.episode_current.as_deref().filter(|e| !e.trim().is_empty() && !e.eq_ignore_ascii_case("full")).map(|e| e.replace("Hoàn Tất", "Trọn bộ"))
    }
    /// "Tình cảm • Cổ trang • Chính kịch"
    pub fn genre_line(&self) -> String {
        self.category.iter().take(3).filter_map(|c| c.name.clone()).collect::<Vec<_>>().join(" • ")
    }
    /// "★ 8.4 · 2026 · FHD · Phụ đề · Tập 12"
    pub fn meta_line(&self) -> String {
        let sub = self.lang.as_deref().unwrap_or("").to_lowercase().contains("vietsub").then(|| "Phụ đề".to_string());
        [self.rating().map(|r| format!("★ {r:.1}")), self.year.map(|y| y.to_string()), self.quality.clone(), sub, self.episode_current.clone()]
            .into_iter().flatten().filter(|s| !s.trim().is_empty()).collect::<Vec<_>>().join(" · ")
    }
}

/// PhimAPI images are sometimes relative to its CDN.
pub fn img_url(u: Option<&str>) -> String {
    match u {
        Some(u) if u.starts_with("http") => u.to_string(),
        Some(u) if !u.is_empty() => {
            let p = u.trim_start_matches('/');
            if p.contains('/') { format!("https://phimimg.com/{p}") } else { format!("https://phimimg.com/uploads/movies/{p}") }
        }
        _ => String::new(),
    }
}

/// Hidden unless the account allows it (web: never), and trailers outside "Sắp chiếu".
pub fn visible(f: &Film) -> bool { !f.is_adult() }

thread_local! {
    static CACHE: RefCell<HashMap<String, Value>> = RefCell::new(HashMap::new());
}

pub async fn get_json(url: &str) -> Result<Value, String> {
    if let Some(v) = CACHE.with(|c| c.borrow().get(url).cloned()) {
        return Ok(v);
    }
    let res = gloo_net::http::Request::get(url).send().await.map_err(|e| e.to_string())?;
    if !res.ok() {
        return Err(format!("HTTP {}", res.status()));
    }
    let v: Value = res.json().await.map_err(|e| e.to_string())?;
    CACHE.with(|c| c.borrow_mut().insert(url.to_string(), v.clone()));
    Ok(v)
}

pub fn enc(s: &str) -> String { js_sys::encode_uri_component(s).as_string().unwrap_or_default() }

pub fn list_url(source: &Source, page: i64, filter: &Filter) -> String {
    let mut url = match source {
        Source::Type(s) => format!("{API}/danh-sach/{s}?page={page}"),
        Source::Genre(s) => format!("{API}/the-loai/{s}?page={page}"),
        Source::Country(s) => format!("{API}/quoc-gia/{s}?page={page}"),
        Source::Search(k) => format!("{API}/tim-kiem?page={page}&keyword={}", enc(k)),
    };
    if let Some(c) = &filter.category { url += &format!("&category={c}"); }
    if let Some(c) = &filter.country { url += &format!("&country={c}"); }
    if let Some(y) = filter.year { url += &format!("&year={y}"); }
    if let Some(s) = &filter.sort { url += &format!("&sort_field={s}"); }
    url
}

/// One page; 18+ always dropped, trailers dropped unless the list is "Sắp chiếu".
pub async fn list(source: &Source, page: i64, filter: &Filter) -> Result<Page, String> {
    let v = get_json(&list_url(source, page, filter)).await?;
    let data = &v["data"];
    let keep_trailers = *source == Source::Type("phim-sap-chieu".into());
    let items: Vec<Film> = serde_json::from_value(data["items"].clone()).unwrap_or_default();
    let p = &data["params"]["pagination"];
    let per = p["totalItemsPerPage"].as_i64().unwrap_or(0);
    let total = p["totalPages"].as_i64().unwrap_or(if per > 0 { (p["totalItems"].as_i64().unwrap_or(0) + per - 1) / per } else { 0 });
    Ok(Page { items: items.into_iter().filter(|f| visible(f) && (keep_trailers || !f.is_trailer())).collect(), total_pages: total })
}

pub async fn detail(slug: &str) -> Result<Detail, String> {
    let v = get_json(&format!("{API}/phim/{}", enc(slug))).await?;
    serde_json::from_value(v["data"]["item"].clone()).map_err(|e| e.to_string())
}

pub fn tmdb(path: &str, size: &str) -> String { format!("https://image.tmdb.org/t/p/{size}{path}") }

/// TMDB backdrop paths, textless (no language) first.
pub async fn backdrops(slug: &str) -> Vec<String> {
    let Ok(v) = get_json(&format!("{API}/phim/{}/images", enc(slug))).await else { return vec![] };
    let mut imgs: Vec<&Value> = v["data"]["images"].as_array().map(|a| a.iter().filter(|i| i["type"] == "backdrop").collect()).unwrap_or_default();
    imgs.sort_by_key(|i| !i["iso_639_1"].is_null());
    imgs.iter().filter_map(|i| i["file_path"].as_str()).map(String::from).collect()
}

#[derive(Clone, Debug, Default, PartialEq, Deserialize)]
pub struct Person {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub character: Option<String>,
    #[serde(default)]
    pub known_for_department: Option<String>,
    #[serde(default)]
    pub profile_path: Option<String>,
}

pub async fn peoples(slug: &str) -> Vec<Person> {
    let Ok(v) = get_json(&format!("{API}/phim/{}/peoples", enc(slug))).await else { return vec![] };
    serde_json::from_value(v["data"]["peoples"].clone()).unwrap_or_default()
}

pub async fn taxonomy(kind: &str) -> Vec<Category> {
    let Ok(v) = get_json(&format!("https://phimapi.com/{kind}")).await else { return vec![] };
    let items: Vec<Category> = serde_json::from_value(v["data"]["items"].clone()).unwrap_or_default();
    items.into_iter().filter(|c| !matches!(c.slug.as_deref(), Some("phim-18") | Some("18-plus"))).collect()
}

/// Netflix Top 10 Vietnam, crawled every 6 h (tools/hot).
pub async fn hot() -> Option<Hot> {
    let v = get_json(HOT).await.ok()?;
    let mut films = vec![];
    let mut series = vec![];
    for e in v["items"].as_array()? {
        let Ok(f) = serde_json::from_value::<Film>(e["film"].clone()) else { continue };
        if !visible(&f) { continue; }
        if e["kind"] == "tv" { series.push(f.clone()); }
        films.push(f);
    }
    Some(Hot { week: v["week"].as_str().map(String::from), films, series })
}

/// "Tập 3" for "03", the name otherwise.
pub fn ep_label(name: &str) -> String {
    if !name.is_empty() && name.chars().all(|c| c.is_ascii_digit()) { format!("Tập {}", name.parse::<u32>().unwrap_or(0)) } else { name.to_string() }
}

/// Strips the HTML PhimAPI puts in synopses.
pub fn plain(html: &str) -> String {
    let mut out = String::with_capacity(html.len());
    let mut tag = false;
    for c in html.chars() {
        match c {
            '<' => tag = true,
            '>' => tag = false,
            _ if !tag => out.push(c),
            _ => {}
        }
    }
    out.replace("&nbsp;", " ").replace("&amp;", "&").replace("&quot;", "\"").replace("&#39;", "'").trim().to_string()
}
