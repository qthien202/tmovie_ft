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
    pub fn share(text: &str);
    #[wasm_bindgen(js_namespace = tm)]
    pub fn open(url: &str);
}

/// "r,g,b" of the image's tuned average colour, as ColorSampler.kt.
pub async fn tint_of(url: &str) -> Option<String> {
    wasm_bindgen_futures::JsFuture::from(tint(url)).await.ok()?.as_string()
}

pub fn now() -> f64 { js_sys::Date::now() }

pub fn reduce_motion() -> bool {
    web_sys::window().and_then(|w| w.match_media("(prefers-reduced-motion: reduce)").ok().flatten()).map(|m| m.matches()).unwrap_or(false)
}

pub fn win() -> (f64, f64) {
    let w = web_sys::window().unwrap();
    (w.inner_width().ok().and_then(|v| v.as_f64()).unwrap_or(390.0), w.inner_height().ok().and_then(|v| v.as_f64()).unwrap_or(844.0))
}
