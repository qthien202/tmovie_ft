//! The access gate, as the phone's GoogleGate: sign in with Google, ask for access under the Firebase uid, and
//! open as soon as the owner's approval writes `members/{uid}` (watched live, see `account`).
//! Browsers that were let in earlier by the old name + email form keep their access (`member` action).

use leptos::prelude::*;
use leptos::task::spawn_local;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

use crate::account::{self, Account};
use crate::store;

const URL: &str = "https://script.google.com/macros/s/AKfycbzM71C8tRgkWqKWYBpr97IcZCOkouZTTU55rWiU1n4g3MZHEq8dm9B9pHd6SC4kicSk-Q/exec";
/// 24 h to approve + 24 h to pick it up; the script decides.
const TTL_MS: f64 = 48.0 * 3600.0 * 1000.0;

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Access {
    /// Let in by the old form (request id in `member`).
    pub unlocked: bool,
    pub name: String,
    pub email: String,
    /// The uid a Google request was filed under.
    pub request: String,
    pub requested_at: f64,
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

/// Old form access: locks again if the owner removed this browser from `members`. Offline keeps it open.
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

fn device() -> &'static str {
    let ua = web_sys::window().and_then(|w| w.navigator().user_agent().ok()).unwrap_or_default();
    if ua.contains("iPhone") { "iPhone (web)" } else if ua.contains("iPad") { "iPad (web)" } else if ua.contains("Android") { "Android (web)" } else { "Máy tính (web)" }
}

#[component]
pub fn Gate() -> impl IntoView {
    let acct: Account = account::account();
    let busy = RwSignal::new(false);
    let error = RwSignal::new(None::<String>);
    let requested = RwSignal::new(access());
    let pending = move || {
        let a = requested.get();
        acct.user.with(|u| u.as_ref().is_some_and(|u| u.uid == a.request)) && js_sys::Date::now() - a.requested_at < TTL_MS
    };
    Effect::new(move |_| if acct.error.get().is_some() { error.set(Some("Chưa đăng nhập được, thử lại nhé.".into())) });

    let sign_in = move || {
        busy.set(true);
        error.set(None);
        spawn_local(async move {
            let r = account::sign_in().await;
            if !r.is_empty() && r != "cancelled" { error.set(Some("Chưa đăng nhập được, thử lại nhé.".into())) }
            busy.set(false);
        });
    };
    let send = move || {
        let Some(u) = acct.user.get_untracked() else { return };
        busy.set(true);
        error.set(None);
        spawn_local(async move {
            let email = u.email.clone().unwrap_or_default();
            let name = u.name.clone().unwrap_or_else(|| email.clone());
            match post(json!({ "action": "request", "name": name, "email": email, "platform": "web", "device": device(), "uid": u.uid })).await {
                Ok(v) if v["ok"] == Value::Bool(true) => {
                    let a = Access { name, email, request: u.uid.clone(), requested_at: js_sys::Date::now(), ..access() };
                    save(&a);
                    requested.set(a);
                }
                _ => error.set(Some("Không gửi được, kiểm tra mạng rồi thử lại nhé.".into())),
            }
            busy.set(false);
        });
    };
    let other_account = move || {
        let a = Access { request: String::new(), ..access() };
        save(&a);
        requested.set(a);
        account::sign_out();
    };
    let email = move || acct.user.get().and_then(|u| u.email).unwrap_or_default();

    view! {
        <div class="gate">
            <div class="gate-in">
                <div class="wordmark">"TMOVIE"</div>
                {move || if !acct.ready.get() {
                    view! { <div class="spinner"></div> }.into_any()
                } else if acct.user.with(|u| u.is_none()) {
                    view! {
                        <h2>"App riêng tư"</h2>
                        <p>"TMovie chỉ dành cho bạn bè của chủ app. Đăng nhập Google rồi xin vào, chủ app duyệt là bạn xem được ngay."</p>
                        <div class="go press" class:off=move || busy.get() on:click=move |_| sign_in()>
                            {move || if busy.get() { "Đang đăng nhập…" } else { "Đăng nhập bằng Google" }}
                        </div>
                    }.into_any()
                } else if pending() {
                    view! {
                        <h2>"Đang chờ duyệt…"</h2>
                        <p>{move || format!("Đã gửi yêu cầu. Chủ app duyệt xong là app tự mở, và bạn nhận mail báo ở {}.", email())}</p>
                        <div class="spinner"></div>
                        <div class="tl" on:click=move |_| other_account()>"Huỷ yêu cầu, dùng tài khoản khác"</div>
                    }.into_any()
                } else {
                    view! {
                        <h2>"App riêng tư"</h2>
                        <p>{move || format!("Bạn đang đăng nhập bằng {}. Gửi yêu cầu để chủ app duyệt.", email())}</p>
                        <div class="go press" class:off=move || busy.get() on:click=move |_| send()>
                            {move || if busy.get() { "Đang gửi…" } else { "Gửi yêu cầu" }}
                        </div>
                        <div class="tl" on:click=move |_| other_account()>"Dùng tài khoản khác"</div>
                    }.into_any()
                }}
                {move || error.get().map(|e| view! { <div class="err">{e}</div> })}
            </div>
        </div>
    }
}
