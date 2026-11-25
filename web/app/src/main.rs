//! TMovie for the web (an iOS home-screen app): the Android phone app's screens, 1:1, in Leptos.

mod api;
mod gate;
mod glue;
mod store;
mod ui;

use leptos::prelude::*;

fn main() {
    console_error_panic_hook_lite();
    if let Some(sw) = web_sys::window().map(|w| w.navigator().service_worker()) {
        let _ = sw.register("sw.js");
    }
    mount_to_body(ui::App);
}

/// Panics go to the console instead of failing silently.
fn console_error_panic_hook_lite() {
    std::panic::set_hook(Box::new(|info| web_sys::console::error_1(&info.to_string().into())));
}
