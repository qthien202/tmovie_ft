//! Google sign-in (Firebase, same project as the phone apps), `members/{uid}`, `entitlements/{uid}.allowAdult`,
//! and the library sync, as the Android `Account` + `LibrarySync`: `users/{uid}/favorites/{slug}` and
//! `history/{slug}` hold `{slug, name, originName, thumbUrl, episode, timestamp}`, `playback/{slug}_{episodeName}`
//! holds `{position}` in seconds. On sign-in the remote entries are merged in (newest wins) and local-only ones
//! pushed; afterwards each change is pushed.

use std::cell::RefCell;
use std::collections::HashMap;

use leptos::prelude::*;
use leptos::task::spawn_local;
use serde::Deserialize;
use serde_json::{json, Value};
use wasm_bindgen::prelude::*;

use crate::api::Film;
use crate::store::{self, Watch};

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = tm, js_name = fbUser)]
    fn fb_user(cb: &Closure<dyn FnMut(String)>);
    #[wasm_bindgen(js_namespace = tm, js_name = fbSignIn)]
    fn fb_sign_in() -> js_sys::Promise;
    #[wasm_bindgen(js_namespace = tm, js_name = fbSignOut)]
    fn fb_sign_out() -> js_sys::Promise;
    #[wasm_bindgen(js_namespace = tm, js_name = fbMember)]
    fn fb_member(uid: &str, cb: &js_sys::Function);
    #[wasm_bindgen(js_namespace = tm, js_name = fbGet)]
    fn fb_get(path: &str) -> js_sys::Promise;
    #[wasm_bindgen(js_namespace = tm, js_name = fbPull)]
    fn fb_pull(uid: &str) -> js_sys::Promise;
    #[wasm_bindgen(js_namespace = tm, js_name = fbSet)]
    fn fb_set(path: &str, json: &str) -> js_sys::Promise;
    #[wasm_bindgen(js_namespace = tm, js_name = fbDel)]
    fn fb_del(path: &str) -> js_sys::Promise;
}

async fn text(p: js_sys::Promise) -> String { wasm_bindgen_futures::JsFuture::from(p).await.ok().and_then(|v| v.as_string()).unwrap_or_default() }

#[derive(Clone, Debug, Default, PartialEq, Deserialize)]
pub struct User {
    pub uid: String,
    pub name: Option<String>,
    pub email: Option<String>,
    pub photo: Option<String>,
}

#[derive(Clone, Copy)]
pub struct Account {
    pub user: RwSignal<Option<User>>,
    /// False until Firebase has said whether someone is signed in.
    pub ready: RwSignal<bool>,
    /// Whether `members/{uid}` exists; None while unknown (the last answer is kept in `tm.member`).
    pub member: RwSignal<Option<bool>>,
    pub error: RwSignal<Option<String>>,
    /// Bumped whenever history or "Danh sách của tôi" changes (the shell's `Nav.lib`).
    pub lib: RwSignal<u32>,
}

thread_local! {
    static UID: RefCell<Option<String>> = const { RefCell::new(None) };
    static PUSHED: RefCell<HashMap<String, f64>> = RefCell::new(HashMap::new());
}

pub fn account() -> Account { expect_context::<Account>() }

pub fn init() -> Account {
    let a = Account { user: RwSignal::new(None), ready: RwSignal::new(false), member: RwSignal::new(None), error: RwSignal::new(None), lib: RwSignal::new(0) };
    // Lives as long as the page (JS keeps it for the members/{uid} listener).
    let on_member: js_sys::Function = Closure::<dyn FnMut(bool)>::new(move |m: bool| {
        store::set("tm.member", &m);
        a.member.set(Some(m));
    }).into_js_value().unchecked_into();
    let on_user = Closure::<dyn FnMut(String)>::new(move |s: String| {
        if let Some(code) = s.strip_prefix("error:") {
            if code != "offline" { a.error.set(Some(code.to_string())); }
            a.ready.set(true);
            return;
        }
        let user: Option<User> = serde_json::from_str(&s).ok();
        let uid = user.as_ref().map(|u| u.uid.clone());
        UID.with(|u| *u.borrow_mut() = uid.clone());
        a.user.set(user);
        a.ready.set(true);
        match uid {
            Some(uid) => {
                fb_member(&uid, &on_member);
                spawn_local(async move {
                    let e: Value = serde_json::from_str(&text(fb_get(&format!("entitlements/{uid}"))).await).unwrap_or_default();
                    crate::api::ADULT.with(|c| c.set(e["allowAdult"] == Value::Bool(true)));
                    pull(&uid).await;
                    a.lib.update(|v| *v += 1);
                });
            }
            None => {
                fb_member("", &on_member);
                crate::api::ADULT.with(|c| c.set(false));
                store::set("tm.member", &false);
                a.member.set(Some(false));
            }
        }
    });
    fb_user(&on_user);
    on_user.forget();
    a
}


/// "" when done; "cancelled" when the picker was closed; else an error code.
/// Starts right away (not on first poll) so the sign-in window opens inside the tap.
pub fn sign_in() -> impl std::future::Future<Output = String> {
    let p = fb_sign_in();
    async move { text(p).await }
}

pub fn sign_out() {
    UID.with(|u| *u.borrow_mut() = None);
    spawn_local(async { let _ = wasm_bindgen_futures::JsFuture::from(fb_sign_out()).await; });
}

fn uid() -> Option<String> { UID.with(|u| u.borrow().clone()) }

/// Episode names are synced; local progress is keyed by episode slug ("Tập 01" → "tap-01").
pub fn slugify(name: &str) -> String {
    let mut out = String::new();
    for c in name.to_lowercase().chars() {
        let c = match c {
            'à' | 'á' | 'ạ' | 'ả' | 'ã' | 'â' | 'ầ' | 'ấ' | 'ậ' | 'ẩ' | 'ẫ' | 'ă' | 'ằ' | 'ắ' | 'ặ' | 'ẳ' | 'ẵ' => 'a',
            'è' | 'é' | 'ẹ' | 'ẻ' | 'ẽ' | 'ê' | 'ề' | 'ế' | 'ệ' | 'ể' | 'ễ' => 'e',
            'ì' | 'í' | 'ị' | 'ỉ' | 'ĩ' => 'i',
            'ò' | 'ó' | 'ọ' | 'ỏ' | 'õ' | 'ô' | 'ồ' | 'ố' | 'ộ' | 'ổ' | 'ỗ' | 'ơ' | 'ờ' | 'ớ' | 'ợ' | 'ở' | 'ỡ' => 'o',
            'ù' | 'ú' | 'ụ' | 'ủ' | 'ũ' | 'ư' | 'ừ' | 'ứ' | 'ự' | 'ử' | 'ữ' => 'u',
            'ỳ' | 'ý' | 'ỵ' | 'ỷ' | 'ỹ' => 'y',
            'đ' => 'd',
            c => c,
        };
        if c.is_ascii_alphanumeric() { out.push(c) } else if !out.ends_with('-') && !out.is_empty() { out.push('-') }
    }
    out.trim_end_matches('-').to_string()
}

fn entry(film: &Film, episode: Option<&str>, timestamp: f64) -> String {
    json!({
        "slug": film.slug, "name": film.name, "originName": film.origin_name,
        "thumbUrl": film.thumb_url.clone().filter(|t| !t.is_empty()).or_else(|| film.poster_url.clone()),
        "episode": episode, "description": Value::Null, "timestamp": timestamp as i64,
    }).to_string()
}

fn put(path: String, body: String) { spawn_local(async move { let _ = wasm_bindgen_futures::JsFuture::from(fb_set(&path, &body)).await; }) }
fn del(path: String) { spawn_local(async move { let _ = wasm_bindgen_futures::JsFuture::from(fb_del(&path)).await; }) }

pub fn push_saved(film: &Film, on: bool) {
    let Some(uid) = uid() else { return };
    let path = format!("users/{uid}/favorites/{}", film.slug);
    if on { put(path, entry(film, None, js_sys::Date::now())) } else { del(path) }
}

/// History + position; at most every 30 s per film unless the episode changed (it's called every 10 s while playing).
pub fn push_watch(w: &Watch, force: bool) {
    let Some(uid) = uid() else { return };
    let key = format!("{}|{}", w.film.slug, w.episode_name);
    let last = PUSHED.with(|p| p.borrow().get(&key).copied());
    if !force && last.is_some_and(|t| w.updated_at - t < 30_000.0) { return; }
    PUSHED.with(|p| p.borrow_mut().insert(key, w.updated_at));
    put(format!("users/{uid}/history/{}", w.film.slug), entry(&w.film, Some(&w.episode_name), w.updated_at));
    if let Some(pos) = w.positions.get(&w.episode_slug) {
        put(format!("users/{uid}/playback/{}_{}", w.film.slug, w.episode_name), json!({ "position": *pos as i64 }).to_string());
    }
}

pub fn push_forget(slug: &str) {
    if let Some(uid) = uid() { del(format!("users/{uid}/history/{slug}")) }
}

#[derive(Deserialize)]
struct Remote {
    #[serde(default)]
    favorites: Vec<Value>,
    #[serde(default)]
    history: Vec<Value>,
    #[serde(default)]
    playback: HashMap<String, f64>,
}

fn film_of(v: &Value) -> Option<(Film, f64, String)> {
    let slug = v["slug"].as_str()?.to_string();
    let name = v["name"].as_str()?.to_string();
    let film = Film { slug, name, origin_name: v["originName"].as_str().map(String::from), thumb_url: v["thumbUrl"].as_str().map(String::from), ..Default::default() };
    Some((film, v["timestamp"].as_f64().unwrap_or(0.0), v["episode"].as_str().unwrap_or("").to_string()))
}

/// Merge the account's library into this browser's (newest wins), then push what only this browser had.
async fn pull(uid: &str) {
    let Ok(r) = serde_json::from_str::<Remote>(&text(fb_pull(uid)).await) else { return };
    let mut saved = store::saved();
    let known: Vec<String> = saved.iter().map(|f| f.slug.clone()).collect();
    let mut remote_favs: Vec<(Film, f64, String)> = r.favorites.iter().filter_map(film_of).collect();
    remote_favs.sort_by(|a, b| b.1.total_cmp(&a.1));
    let remote_fav_slugs: Vec<String> = remote_favs.iter().map(|f| f.0.slug.clone()).collect();
    saved.extend(remote_favs.into_iter().filter(|f| !known.contains(&f.0.slug)).map(|f| f.0));
    store::set("tm.list", &saved);
    for f in saved.iter().filter(|f| !remote_fav_slugs.contains(&f.slug)) { push_saved(f, true) }

    let mut hist: HashMap<String, Watch> = store::get("tm.hist").unwrap_or_default();
    let mut remote_ts = HashMap::new();
    for v in &r.history {
        let Some((film, ts, ep)) = film_of(v) else { continue };
        remote_ts.insert(film.slug.clone(), ts);
        if hist.get(&film.slug).is_some_and(|w| w.updated_at >= ts) { continue; }
        let prefix = format!("{}_", film.slug);
        let positions: HashMap<String, f64> = r.playback.iter().filter_map(|(k, p)| k.strip_prefix(&prefix).map(|n| (slugify(n), *p))).collect();
        let old = hist.remove(&film.slug).unwrap_or_default();
        let mut all = old.positions.clone();
        all.extend(positions);
        let w = Watch { film: if old.film.slug.is_empty() { film } else { old.film }, server: old.server, episode: old.episode,
            episode_slug: slugify(&ep), episode_name: ep, positions: all, durations: old.durations, updated_at: ts };
        hist.insert(w.film.slug.clone(), w);
    }
    store::set("tm.hist", &hist);
    for w in hist.values().filter(|w| remote_ts.get(&w.film.slug).is_none_or(|t| *t < w.updated_at)) { push_watch(w, true) }
}
