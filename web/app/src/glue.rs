//! `window.tm` in index.html: the few browser calls that are shorter in JS.

use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = tm)]
    pub fn attach(v: &web_sys::HtmlVideoElement, url: &str);
    #[wasm_bindgen(js_namespace = tm)]
    pub fn detach(v: &web_sys::HtmlVideoElement);
    #[wasm_bindgen(js_namespace = tm)]
    pub fn snap(v: &web_sys::HtmlVideoElement) -> Option<String>;
    #[wasm_bindgen(js_namespace = tm)]
    fn tint(url: &str) -> js_sys::Promise;
    #[wasm_bindgen(js_namespace = tm)]
    pub fn pip(v: &web_sys::HtmlVideoElement);
    #[wasm_bindgen(js_namespace = tm)]
    pub fn wake(on: bool);
    #[wasm_bindgen(js_namespace = tm)]
    /// False when there is no share sheet and the link was copied instead.
    pub fn share(text: &str, url: &str) -> bool;
    #[wasm_bindgen(js_namespace = tm)]
    pub fn open(url: &str);
    #[wasm_bindgen(js_namespace = tm)]
    pub fn fullscreen(el: &web_sys::Element);
}

/// "r,g,b" of the image's tuned average colour, as ColorSampler.kt.
pub async fn tint_of(url: &str) -> Option<String> {
    wasm_bindgen_futures::JsFuture::from(tint(url)).await.ok()?.as_string()
}

pub fn now() -> f64 { js_sys::Date::now() }


/// iPhone/iPad (iPadOS reports a Mac with touch): films play in iOS's own player there.
pub fn ios() -> bool {
    let Some(n) = web_sys::window().map(|w| w.navigator()) else { return false };
    let ua = n.user_agent().unwrap_or_default();
    ua.contains("iPhone") || ua.contains("iPad") || ua.contains("iPod") || (ua.contains("Macintosh") && n.max_touch_points() > 1)
}

pub fn reduce_motion() -> bool {
    web_sys::window().and_then(|w| w.match_media("(prefers-reduced-motion: reduce)").ok().flatten()).map(|m| m.matches()).unwrap_or(false)
}

/// The app's own box (see #app in app.css), which on iOS is taller than `innerHeight`.
pub fn win() -> (f64, f64) {
    let w = web_sys::window().unwrap();
    if let Some(app) = w.document().and_then(|d| d.get_element_by_id("app")) {
        let (cw, ch) = (app.client_width() as f64, app.client_height() as f64);
        if cw > 0.0 && ch > 0.0 { return (cw, ch); }
    }
    (w.inner_width().ok().and_then(|v| v.as_f64()).unwrap_or(390.0), w.inner_height().ok().and_then(|v| v.as_f64()).unwrap_or(844.0))
}
