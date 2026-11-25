//! The access gate, same flow as the apps' AccessGate: a new device asks for access with a name and an
//! email; the owner approves from the mail; the device, which alone holds the request id, opens.

use leptos::prelude::*;
use leptos::task::spawn_local;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

use crate::store;

const URL: &str = "https://script.google.com/macros/s/AKfycbzM71C8tRgkWqKWYBpr97IcZCOkouZTTU55rWiU1n4g3MZHEq8dm9B9pHd6SC4kicSk-Q/exec";
/// 24 h to approve + 24 h to pick it up; the script decides.
const TTL_MS: f64 = 48.0 * 3600.0 * 1000.0;

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Access {
    pub unlocked: bool,
    pub name: String,
    pub email: String,
    pub request: String,
    pub requested_at: f64,
    /// The member id the script lists in Firestore (the request id for web, as for TV and iOS).
    pub member: String,
}

pub fn access() -> Access { store::get("tm.access").unwrap_or_default() }
fn save(a: &Access) { store::set("tm.access", a) }

/// Apps Script answers a POST with a redirect to the result. `text/plain` keeps it a simple request (no preflight).
async fn post(body: Value) -> Result<Value, String> {
    let res = gloo_net::http::Request::post(URL)
        .header("Content-Type", "text/plain;charset=utf-8")
        .body(body.to_string())
        .map_err(|e| e.to_string())?
        .send()
        .await
        .map_err(|e| e.to_string())?;
    res.json().await.map_err(|e| e.to_string())
}

/// Locks the app again if the owner removed this device from `members`. Offline keeps it open.
pub async fn recheck(unlocked: RwSignal<bool>) {
    let a = access();
    if !a.unlocked || a.member.is_empty() { return; }
    if let Ok(v) = post(json!({ "action": "member", "id": a.member })).await {
        if v["ok"] != Value::Bool(true) {
            save(&Access { unlocked: false, ..a });
            unlocked.set(false);
        }
    }
}

/// `^[^@\s]+@[^@\s]+\.[^@\s]+$`
fn email_ok(e: &str) -> bool {
    let Some((user, host)) = e.split_once('@') else { return false };
    let ok = |s: &str| !s.is_empty() && !s.contains(['@', ' ', '\t', '\n']);
    ok(user) && host.rsplit_once('.').is_some_and(|(a, b)| ok(a) && ok(b))
}

fn pending(a: &Access) -> bool { !a.request.is_empty() && js_sys::Date::now() - a.requested_at < TTL_MS }

#[component]
pub fn Gate(unlocked: RwSignal<bool>) -> impl IntoView {
    let a = access();
    let name = RwSignal::new(a.name.clone());
    let email = RwSignal::new(a.email.clone());
    let waiting = RwSignal::new(pending(&a));
    let busy = RwSignal::new(false);
    let error = RwSignal::new(None::<String>);
    let valid = move || {
        let (n, e) = (name.get(), email.get());
        let (n, e) = (n.trim(), e.trim());
        !n.is_empty() && n.chars().count() <= 40 && e.chars().count() <= 100 && email_ok(e) && !busy.get()
    };

    let send = move || {
        if !valid() { return; }
        busy.set(true);
        error.set(None);
        let (n, e) = (name.get_untracked().trim().to_string(), email.get_untracked().trim().to_string());
        spawn_local(async move {
            let device = web_sys::window().and_then(|w| w.navigator().user_agent().ok()).unwrap_or_default();
            let device = if device.contains("iPhone") { "iPhone (web)" } else if device.contains("iPad") { "iPad (web)" } else if device.contains("Android") { "Android (web)" } else { "Trình duyệt" };
            match post(json!({ "action": "request", "name": n, "email": e, "platform": "web", "device": device })).await {
                Ok(v) if v["ok"] == Value::Bool(true) => {
                    save(&Access { name: n, email: e, request: v["id"].as_str().unwrap_or_default().into(), requested_at: js_sys::Date::now(), ..access() });
                    waiting.set(true);
                }
                _ => error.set(Some("Không gửi được, kiểm tra mạng rồi thử lại nhé.".into())),
            }
            busy.set(false);
        });
    };

    // While a request waits, ask every 10 s whether the owner approved it; the screen leaves on its own.
    let poll = move || {
        spawn_local(async move {
            loop {
                gloo_timers::future::TimeoutFuture::new(10_000).await;
                let a = access();
                if !waiting.get_untracked() || a.request.is_empty() { break; }
                let Ok(v) = post(json!({ "action": "status", "id": a.request })).await else { continue };
                if v["ok"] == Value::Bool(true) {
                    save(&Access { unlocked: true, member: a.request.clone(), request: String::new(), ..a });
                    unlocked.set(true);
                    break;
                } else if v["pending"] != Value::Bool(true) {
                    save(&Access { request: String::new(), ..a });
                    waiting.set(false);
                    error.set(Some("Yêu cầu đã hết hạn, gửi lại nhé.".into()));
                    break;
                }
            }
        });
    };
    Effect::new(move |_| { if waiting.get() { poll(); } });

    view! {
        <div class="gate">
            <div class="gate-in">
                <div class="wordmark">"TMOVIE"</div>
                <h2>{move || if waiting.get() { "Đang chờ duyệt…" } else { "App riêng tư" }}</h2>
                <p>{move || if waiting.get() {
                    format!("Đã gửi yêu cầu. Chủ app duyệt xong là app tự mở, và bạn nhận mail báo ở {}.", access().email)
                } else { "TMovie chỉ dành cho bạn bè của chủ app. Gửi yêu cầu, chủ app duyệt là bạn xem được ngay.".to_string() }}</p>
                <Show when=move || !waiting.get()>
                    <input placeholder="Tên của bạn" autocomplete="name" maxlength="40" prop:value=move || name.get()
                        on:input=move |e| name.set(event_target_value(&e)) />
                    <input placeholder="Email" type="email" maxlength="100" inputmode="email" autocomplete="email" autocapitalize="off" prop:value=move || email.get()
                        on:input=move |e| email.set(event_target_value(&e))
                        on:keydown=move |e| if e.key() == "Enter" { send() } />
                </Show>
                {move || error.get().map(|e| view! { <div class="err">{e}</div> })}
                <Show when=move || waiting.get() fallback=move || view! {
                    <div class="go press" class:off=move || !valid() on:click=move |_| send()>
                        {move || if busy.get() { "Đang gửi…" } else { "Gửi yêu cầu" }}
                    </div>
                }>
                    <div class="spinner"></div>
                    <div class="tl" on:click=move |_| { save(&Access { request: String::new(), ..access() }); waiting.set(false); }>"Gửi lại yêu cầu"</div>
                </Show>
            </div>
        </div>
    }
}
