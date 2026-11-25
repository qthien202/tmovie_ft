//! What the apps keep in their library and settings, kept in this browser's localStorage.

use std::collections::HashMap;

use serde::{de::DeserializeOwned, Deserialize, Serialize};

use crate::api::Film;

fn storage() -> Option<web_sys::Storage> { web_sys::window()?.local_storage().ok().flatten() }

pub fn get<T: DeserializeOwned>(key: &str) -> Option<T> {
    serde_json::from_str(&storage()?.get_item(key).ok()??).ok()
}

pub fn set<T: Serialize>(key: &str, value: &T) {
    if let (Some(s), Ok(json)) = (storage(), serde_json::to_string(value)) {
        let _ = s.set_item(key, &json);
    }
}

pub fn remove(key: &str) {
    if let Some(s) = storage() { let _ = s.remove_item(key); }
}

/// Watch progress per film, as the apps' WatchRecord.
#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
pub struct Watch {
    pub film: Film,
    pub server: usize,
    pub episode: usize,
    pub episode_name: String,
    pub episode_slug: String,
    /// Seconds watched / total per episode slug.
    pub positions: HashMap<String, f64>,
    pub durations: HashMap<String, f64>,
    pub updated_at: f64,
}

impl Watch {
    pub fn progress(&self, ep: &str) -> f64 {
        match self.durations.get(ep) { Some(d) if *d > 0.0 => (self.positions.get(ep).copied().unwrap_or(0.0) / d).min(1.0), _ => 0.0 }
    }
    pub fn last_progress(&self) -> f64 { self.progress(&self.episode_slug) }
    pub fn minutes_left(&self) -> Option<i64> {
        let d = *self.durations.get(&self.episode_slug)?;
        (d > 0.0).then(|| (((d - self.positions.get(&self.episode_slug).copied().unwrap_or(0.0)) / 60.0) as i64).max(1))
    }
}

pub fn history() -> Vec<Watch> {
    let mut all: Vec<Watch> = get::<HashMap<String, Watch>>("tm.hist").unwrap_or_default().into_values().collect();
    all.sort_by(|a, b| b.updated_at.total_cmp(&a.updated_at));
    all
}

pub fn watch(slug: &str) -> Option<Watch> { get::<HashMap<String, Watch>>("tm.hist")?.remove(slug) }

#[allow(clippy::too_many_arguments)]
pub fn save_watch(film: &Film, server: usize, episode: usize, name: &str, ep_slug: &str, position: f64, duration: f64) {
    let mut all: HashMap<String, Watch> = get("tm.hist").unwrap_or_default();
    let w = all.entry(film.slug.clone()).or_insert_with(|| Watch { film: film.clone(), ..Default::default() });
    w.film = film.clone();
    w.server = server;
    w.episode = episode;
    w.episode_name = name.to_string();
    w.episode_slug = ep_slug.to_string();
    w.positions.insert(ep_slug.to_string(), position);
    if duration > 0.0 { w.durations.insert(ep_slug.to_string(), duration); }
    w.updated_at = js_sys::Date::now();
    set("tm.hist", &all);
}

pub fn forget(slug: &str) {
    let mut all: HashMap<String, Watch> = get("tm.hist").unwrap_or_default();
    all.remove(slug);
    set("tm.hist", &all);
    remove(&frame_key(slug));
}

/// "Danh sách của tôi", newest first.
pub fn saved() -> Vec<Film> { get("tm.list").unwrap_or_default() }

pub fn is_saved(slug: &str) -> bool { saved().iter().any(|f| f.slug == slug) }

/// Adds or removes; returns whether it is now saved.
pub fn toggle_saved(film: &Film) -> bool {
    let mut l = saved();
    let on = !l.iter().any(|f| f.slug == film.slug);
    if on { l.insert(0, film.clone()); } else { l.retain(|f| f.slug != film.slug); }
    set("tm.list", &l);
    on
}

/// The frame on screen when the viewer paused or left a film (a JPEG data URL), for "Xem tiếp".
pub fn frame_key(slug: &str) -> String { format!("tm.frame.{slug}") }

pub fn frame(slug: &str) -> Option<String> { storage()?.get_item(&frame_key(slug)).ok()? }

pub fn set_frame(slug: &str, data_url: &str) {
    if let Some(s) = storage() {
        // Full storage: drop the oldest frames and try once more.
        if s.set_item(&frame_key(slug), data_url).is_err() {
            for w in history().iter().skip(6) { let _ = s.remove_item(&frame_key(&w.film.slug)); }
            let _ = s.set_item(&frame_key(slug), data_url);
        }
    }
}

/// Settings, same keys and defaults as the apps.
pub fn flag(key: &str, default: bool) -> bool { get(key).unwrap_or(default) }
pub fn set_flag(key: &str, on: bool) { set(key, &on) }
