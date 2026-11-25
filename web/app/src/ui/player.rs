//! The player, as core/player: landscape (rotated by CSS while the phone is upright), controls that auto-hide,
//! gestures (tap, double-tap seek, scrub, brightness/volume, pinch), panels, next-episode card, resume + save.

use std::time::Duration;

use leptos::leptos_dom::helpers::set_interval_with_handle;
use leptos::prelude::*;

use super::*;
use crate::glue;

#[derive(Clone, Copy, PartialEq)]
enum Panel { Settings, Episodes }

#[derive(Clone, Copy, PartialEq)]
enum Sleep { At(f64, u32), EndOfEpisode }

#[derive(Clone, PartialEq)]
enum Hud { Scrub(f64, f64), Level(bool, f64) }

/// "m:ss", or "h:mm:ss" from one hour.
fn clock(s: f64) -> String {
    let s = s.max(0.0) as u64;
    if s >= 3600 { format!("{}:{:02}:{:02}", s / 3600, s / 60 % 60, s % 60) } else { format!("{}:{:02}", s / 60, s % 60) }
}

#[derive(Clone, Copy, Default)]
struct Touch { x: f64, y: f64, pos: f64, level: f64, axis: u8, left: bool }

#[component]
pub fn Player(p: Play) -> impl IntoView {
    let n = nav();
    let det = StoredValue::new(p.detail.clone());
    let film = p.detail.film.clone();
    let from_detail = p.from_detail;
    let server = RwSignal::new(p.server);
    let index = RwSignal::new(p.index);
    let video = NodeRef::<leptos::html::Video>::new();
    let root = NodeRef::<leptos::html::Div>::new();
    let full = || web_sys::window().and_then(|w| w.document()).and_then(|d| d.fullscreen_element()).is_some();
    let toggle_ref = StoredValue::new_local(None::<Box<dyn Fn()>>);
    let seek_ref = StoredValue::new_local(None::<Box<dyn Fn(f64)>>);
    let close_ref = StoredValue::new_local(None::<Box<dyn Fn()>>);
    let (playing, buffering, ended, error) = (RwSignal::new(false), RwSignal::new(true), RwSignal::new(false), RwSignal::new(false));
    let (pos, dur, buffered) = (RwSignal::new(0.0f64), RwSignal::new(0.0f64), RwSignal::new(0.0f64));
    let controls = RwSignal::new(true);
    let touched = StoredValue::new(glue::now());
    let locked = RwSignal::new(false);
    let panel = RwSignal::new(None::<Panel>);
    let speed = RwSignal::new(1.0f64);
    let fit = RwSignal::new(0u8);
    let sleep = RwSignal::new(None::<Sleep>);
    let cancelled = RwSignal::new(false);
    let offline = RwSignal::new(!web_sys::window().unwrap().navigator().on_line());
    let seek_drag = RwSignal::new(None::<f64>);
    let dbl = RwSignal::new(None::<(bool, i32, f64)>);
    let hud = RwSignal::new(None::<Hud>);
    let bright = RwSignal::new(1.0f64);
    let resume_at = StoredValue::new(0.0f64);
    let size = RwSignal::new(glue::win());
    let rotated = move || { let (w, h) = size.get(); h > w };

    let ep = move |s: usize, i: usize| det.with_value(|d| d.episodes.get(s).and_then(|sv| sv.server_data.get(i).cloned()));
    let cur = move || ep(server.get(), index.get());
    let ep_name = move || cur().map(|e| api::ep_label(e.name.as_deref().unwrap_or(""))).unwrap_or_default();
    let next_index = move || {
        let (s, i) = (server.get(), index.get());
        det.with_value(|d| d.episodes.get(s).and_then(|sv| sv.server_data.iter().enumerate().skip(i + 1).find(|(_, e)| e.stream().is_some()).map(|(k, _)| k)))
    };
    let many = det.with_value(|d| d.episodes.len() > 1 || d.episodes.iter().any(|s| s.server_data.len() > 1));
    let poke = move || { touched.set_value(glue::now()); controls.set(true); };

    let film_s = StoredValue::new(film.clone());
    let save = move || {
        let Some(el) = video.get_untracked() else { return };
        let (s, i) = (server.get_untracked(), index.get_untracked());
        let Some(e) = ep(s, i) else { return };
        let d = el.duration();
        film_s.with_value(|f| store::save_watch(f, s, i, e.name.as_deref().unwrap_or(""), e.slug.as_deref().unwrap_or(""), el.current_time(), if d.is_finite() { d } else { 0.0 }));
    };
    let snap = move || if let Some(el) = video.get_untracked() {
        if el.current_time() > 3.0 { if let Some(data) = glue::snap(&el) { store::set_frame(&film_s.with_value(|f| f.slug.clone()), &data) } }
    };
    let load = move |at: Option<f64>| {
        let Some(el) = video.get_untracked() else { return };
        let Some(e) = cur() else { return };
        let Some(url) = e.stream().map(String::from) else { error.set(true); return };
        error.set(false); ended.set(false); buffering.set(true); cancelled.set(false); pos.set(0.0); dur.set(0.0);
        let slug = e.slug.clone().unwrap_or_default();
        resume_at.set_value(at.unwrap_or_else(|| store::watch(&film_s.with_value(|f| f.slug.clone())).and_then(|w| w.positions.get(&slug).copied()).unwrap_or(0.0)));
        glue::attach(&el, &url);
        let _ = el.set_attribute("autoplay", "");
    };
    let switch = move |s: usize, i: usize| { save(); server.set(s); index.set(i); load(None); save(); };
    let close = move || { save(); snap(); glue::wake(false); n.play.set(None); n.bump(); };

    // Start once the <video> exists.
    Effect::new(move |done: Option<bool>| {
        if done == Some(true) { return true; }
        if video.get().is_some() { load(None); save(); true } else { false }
    });
    // Every second: auto-hide after 3 s, save every 10 s, the sleep timer.
    let tick = StoredValue::new(0u32);
    let h = set_interval_with_handle(move || {
        tick.update_value(|t| *t += 1);
        if playing.get_untracked() && panel.get_untracked().is_none() && glue::now() - touched.get_value() > 3000.0 && seek_drag.get_untracked().is_none() {
            controls.set(false);
        }
        if playing.get_untracked() && tick.get_value() % 10 == 0 { save(); }
        if let Some(Sleep::At(t, _)) = sleep.get_untracked() {
            if glue::now() >= t { if let Some(el) = video.get_untracked() { let _ = el.pause(); } sleep.set(None); }
        }
    }, Duration::from_secs(1)).ok();
    let on_resize = window_event_listener(leptos::ev::resize, move |_| size.set(glue::win()));
    let on_off = window_event_listener(leptos::ev::offline, move |_| offline.set(true));
    // Desktop: keys as in most web players; Esc closes a panel, then the player.
    let on_key = window_event_listener(leptos::ev::keydown, move |e| {
        let vol = |d: f64| if let Some(v) = video.get_untracked() { let l = (v.volume() + d).clamp(0.0, 1.0); v.set_volume(l); v.set_muted(false); hud.set(Some(Hud::Level(false, l))); set_timeout(move || hud.set(None), Duration::from_millis(700)); };
        match e.key().as_str() {
            " " | "k" | "K" => { e.prevent_default(); toggle_ref.with_value(|t| if let Some(t) = t { t() }); }
            "ArrowLeft" | "j" | "J" => seek_ref.with_value(|s| if let Some(s) = s { s(-10.0) }),
            "ArrowRight" | "l" | "L" => seek_ref.with_value(|s| if let Some(s) = s { s(10.0) }),
            "ArrowUp" => { e.prevent_default(); vol(0.1) }
            "ArrowDown" => { e.prevent_default(); vol(-0.1) }
            "m" | "M" => if let Some(v) = video.get_untracked() { v.set_muted(!v.muted()) },
            "f" | "F" => if let Some(p) = root.get_untracked() { glue::fullscreen(&p) },
            "Escape" => if panel.get_untracked().is_some() { panel.set(None) } else if !full() { close_ref.with_value(|c| if let Some(c) = c { c() }) },
            _ => return,
        }
        poke();
    });
    let on_on = window_event_listener(leptos::ev::online, move |_| {
        offline.set(false);
        if error.get_untracked() { load(Some(pos.get_untracked())); }
    });
    on_cleanup(move || {
        if let Some(h) = h { h.clear(); }
        on_resize.remove(); on_off.remove(); on_on.remove(); on_key.remove();
        if let Some(el) = video.get_untracked() { glue::detach(&el); }
        glue::wake(false);
    });

    let seek_to = move |t: f64| if let Some(el) = video.get_untracked() { el.set_current_time(t.clamp(0.0, dur.get_untracked().max(0.0))); pos.set(el.current_time()); };
    let seek_by = move |d: f64| if let Some(el) = video.get_untracked() { seek_to(el.current_time() + d) };
    let toggle = move || if let Some(el) = video.get_untracked() {
        if ended.get_untracked() { el.set_current_time(0.0); ended.set(false); let _ = el.play(); }
        else if el.paused() { let _ = el.play(); } else { let _ = el.pause(); }
    };

    toggle_ref.set_value(Some(Box::new(toggle)));
    seek_ref.set_value(Some(Box::new(seek_by)));
    close_ref.set_value(Some(Box::new(close)));

    // Local (landscape) coordinates, whether or not the player is rotated.
    let local = move |cx: f64, cy: f64| -> (f64, f64, f64, f64) {
        let (w, h) = size.get_untracked();
        if h > w { (cy, w - cx, h, w) } else { (cx, cy, w, h) }
    };
    let touch = StoredValue::new(None::<Touch>);
    let pointers = StoredValue::new(Vec::<(i32, f64, f64)>::new());
    let pinch0 = StoredValue::new(0.0f64);
    let last_tap = StoredValue::new((0.0f64, false));
    let single = StoredValue::new(None::<leptos::leptos_dom::helpers::TimeoutHandle>);
    let dist = |p: &[(i32, f64, f64)]| ((p[0].1 - p[1].1).powi(2) + (p[0].2 - p[1].2).powi(2)).sqrt();

    let down = move |e: web_sys::PointerEvent| {
        if locked.get_untracked() || panel.get_untracked().is_some() { return; }
        pointers.update_value(|p| { p.retain(|q| q.0 != e.pointer_id()); p.push((e.pointer_id(), e.client_x() as f64, e.client_y() as f64)); });
        if pointers.with_value(|p| p.len()) == 2 { pinch0.set_value(pointers.with_value(|p| dist(p))); touch.set_value(None); return; }
        let (x, y, w, _) = local(e.client_x() as f64, e.client_y() as f64);
        let left = x < w / 2.0;
        let level = if left { bright.get_untracked() } else { video.get_untracked().map(|v| v.volume()).unwrap_or(1.0) };
        touch.set_value(Some(Touch { x, y, pos: pos.get_untracked(), level, axis: 0, left }));
    };
    let mv = move |e: web_sys::PointerEvent| {
        pointers.update_value(|p| for q in p.iter_mut() { if q.0 == e.pointer_id() { q.1 = e.client_x() as f64; q.2 = e.client_y() as f64; } });
        if pointers.with_value(|p| p.len()) == 2 {
            let r = pointers.with_value(|p| dist(p)) / pinch0.get_value().max(1.0);
            if r > 1.15 { fit.set(1) } else if r < 0.87 { fit.set(0) }
            return;
        }
        let Some(mut t) = touch.get_value() else { return };
        let (x, y, w, h) = local(e.client_x() as f64, e.client_y() as f64);
        let (dx, dy) = (x - t.x, y - t.y);
        if t.axis == 0 && dx.hypot(dy) > 12.0 { t.axis = if dx.abs() > dy.abs() { 1 } else { 2 }; touch.set_value(Some(t)); }
        match t.axis {
            1 => { let target = (t.pos + dx / w * 90.0).clamp(0.0, dur.get_untracked()); hud.set(Some(Hud::Scrub(target, target - t.pos))); }
            2 => {
                let l = (t.level - dy / (h * 0.8)).clamp(0.0, 1.0);
                if t.left { bright.set(l) } else if let Some(v) = video.get_untracked() { v.set_volume(l) }
                hud.set(Some(Hud::Level(t.left, l)));
            }
            _ => {}
        }
    };
    let up = move |e: web_sys::PointerEvent| {
        pointers.update_value(|p| p.retain(|q| q.0 != e.pointer_id()));
        let Some(t) = touch.get_value() else { return };
        touch.set_value(None);
        if e.pointer_type() == "mouse" && t.axis == 0 {
            // Mouse: a click plays/pauses (a second one within 300 ms undoes it and goes full screen).
            let now = glue::now();
            let (prev, _) = last_tap.get_value();
            toggle();
            if now - prev < 300.0 { toggle(); if let Some(p) = root.get_untracked() { glue::fullscreen(&p) } last_tap.set_value((0.0, false)); } else { last_tap.set_value((now, false)); }
            poke();
            return;
        }
        if let Some(Hud::Scrub(target, _)) = hud.get_untracked() { seek_to(target); }
        let was_drag = t.axis != 0;
        set_timeout(move || hud.set(None), Duration::from_millis(if was_drag { 400 } else { 0 }));
        if was_drag { return; }
        let right = !t.left;
        let now = glue::now();
        // Inside a double-tap run on the same side: every tap adds 10 s.
        if let Some((side, secs, at)) = dbl.get_untracked() {
            if side == right && now - at < 900.0 {
                seek_by(if right { 10.0 } else { -10.0 });
                dbl.set(Some((right, secs + 10, now)));
                set_timeout(move || if dbl.get_untracked().is_some_and(|d| d.2 == now) { dbl.set(None) }, Duration::from_millis(700));
                return;
            }
        }
        let (prev, prev_right) = last_tap.get_value();
        if now - prev < 300.0 && prev_right == right {
            if let Some(h) = single.get_value() { h.clear(); }
            seek_by(if right { 10.0 } else { -10.0 });
            dbl.set(Some((right, 10, now)));
            set_timeout(move || if dbl.get_untracked().is_some_and(|d| d.2 == now) { dbl.set(None) }, Duration::from_millis(700));
            last_tap.set_value((0.0, false));
            return;
        }
        last_tap.set_value((now, right));
        single.set_value(leptos::leptos_dom::helpers::set_timeout_with_handle(move || {
            if controls.get_untracked() { controls.set(false) } else { poke() }
        }, Duration::from_millis(300)).ok());
    };

    let seek_frac = move |e: &web_sys::PointerEvent| -> Option<f64> {
        use wasm_bindgen::JsCast;
        let el = e.current_target()?.dyn_into::<web_sys::Element>().ok()?;
        let r = el.get_bounding_client_rect();
        Some(if rotated() { (e.client_y() as f64 - r.top()) / r.height() } else { (e.client_x() as f64 - r.left()) / r.width() }.clamp(0.0, 1.0))
    };
    let next_card = move || {
        let d = dur.get();
        next_index().is_some() && d > 60.0 && d - pos.get() <= 18.0 && !cancelled.get() && !ended.get()
    };
    let rot_style = move || {
        let (w, h) = size.get();
        if h > w {
            format!("width:{h}px;height:{w}px;right:auto;bottom:auto;transform-origin:0 0;transform:translateX({w}px) rotate(90deg);\
                --left:env(safe-area-inset-top,0px);--right:env(safe-area-inset-bottom,0px);--top:0px;--bottom:0px")
        } else { String::new() }
    };
    let poster = film.thumb();
    let title = film.name.clone();

    view! {
        <div class="player" node_ref=root style=rot_style class:idle=move || !controls.get()
            on:mousemove=move |e| if e.movement_x() != 0 || e.movement_y() != 0 { poke() }>
            <video node_ref=video playsinline=true crossorigin="anonymous" poster=poster
                class:zoom=move || fit.get() == 1 class:fill=move || fit.get() == 2
                prop:playbackRate=move || speed.get()
                on:loadedmetadata=move |_| if let Some(el) = video.get_untracked() {
                    let d = el.duration();
                    dur.set(if d.is_finite() { d } else { 0.0 });
                    let r = resume_at.get_value();
                    if r > 5.0 && r < d - 20.0 { el.set_current_time(r); }
                    el.set_playback_rate(speed.get_untracked());
                }
                on:durationchange=move |_| if let Some(el) = video.get_untracked() { let d = el.duration(); if d.is_finite() { dur.set(d) } }
                on:timeupdate=move |_| if let Some(el) = video.get_untracked() {
                    pos.set(el.current_time());
                    let b = el.buffered();
                    if b.length() > 0 { buffered.set(b.end(b.length() - 1).unwrap_or(0.0)); }
                }
                on:playing=move |_| { playing.set(true); buffering.set(false); ended.set(false); glue::wake(true); }
                on:pause=move |_| { playing.set(false); snap(); save(); poke(); glue::wake(false); }
                on:waiting=move |_| buffering.set(true)
                on:canplay=move |_| buffering.set(false)
                on:error=move |_| { error.set(true); buffering.set(false); }
                on:ended=move |_| {
                    save();
                    if sleep.get_untracked() == Some(Sleep::EndOfEpisode) { sleep.set(None); ended.set(true); return; }
                    match next_index() { Some(i) if !cancelled.get_untracked() => switch(server.get_untracked(), i), _ => ended.set(true) }
                }>
            </video>
            <div class="pscrim" style:opacity=move || if controls.get() && !locked.get() { "1" } else { "0" }></div>
            <div class="dimmer" style:opacity=move || ((1.0 - bright.get()) * 0.85).to_string()></div>
            <div class="surface" on:pointerdown=down on:pointermove=mv on:pointerup=up on:pointercancel=move |_| { touch.set_value(None); pointers.set_value(vec![]); hud.set(None); }
                on:click=move |_| if panel.get_untracked().is_some() { panel.set(None) } else if locked.get_untracked() { poke() }></div>

            {move || dbl.get().map(|(right, secs, _)| view! {
                <div class="dbl" class:r=right class:l=!right>
                    <Icon d=if right { ic::ROT_R } else { ic::ROT_L } />
                    {if right { format!("+{secs}s") } else { format!("−{secs}s") }}
                </div>
            })}
            {move || hud.get().map(|h| match h {
                Hud::Scrub(t, d) => view! { <div class="hud">{format!("{}  ({}{})", clock(t), if d >= 0.0 { "+" } else { "−" }, clock(d.abs()))}</div> }.into_any(),
                Hud::Level(b, l) => view! {
                    <div class="hud"><Icon d=if b { ic::SUN } else { ic::VOL_UP } /><div class="hb"><i style=format!("width:{}%", l * 100.0)></i></div>{format!("{}%", (l * 100.0).round())}</div>
                }.into_any(),
            })}
            {move || (buffering.get() && !error.get()).then(|| view! { <div class="pspin spinner"></div> })}

            {move || if locked.get() {
                view! {
                    <div class="p-ui" class:off=move || !controls.get()>
                        <div class="lockb ricon glass" style="width:56px;height:56px" aria-label="Mở khoá" on:click=move |_| { locked.set(false); poke(); }><Icon d=ic::LOCK /></div>
                    </div>
                }.into_any()
            } else {
                let title = title.clone();
                view! {
                    <div class="p-ui" class:off=move || !controls.get() on:pointerdown=move |_| touched.set_value(glue::now())>
                        <div class="ptop">
                            <div class="ricon glass" style="width:44px;height:44px" aria-label="Quay lại" on:click=move |_| close()><Icon d=ic::BACK /></div>
                            <div class="tc">
                                <b>{title}</b>
                                <span>{move || {
                                    let s = match sleep.get() {
                                        Some(Sleep::At(_, m)) => Some(format!("Hẹn giờ: {m} phút")),
                                        Some(Sleep::EndOfEpisode) => Some("Hẹn giờ: hết tập".into()),
                                        None => None,
                                    };
                                    [Some(ep_name()).filter(|e| !e.is_empty()), s].into_iter().flatten().collect::<Vec<_>>().join(" · ")
                                }}</span>
                            </div>
                            <div class="rt">
                                {move || (speed.get() != 1.0).then(|| view! { <span class="pchip" on:click=move |_| panel.set(Some(Panel::Settings))>{format!("{}×", speed.get())}</span> })}
                                {(!from_detail).then(|| view! {
                                    <div class="ricon glass" style="width:44px;height:44px" aria-label="Thông tin phim"
                                        on:click=move |_| { let f = film_s.get_value(); close(); n.open(f); }><Icon d=ic::INFO /></div>
                                })}
                                <div class="ricon glass" style="width:44px;height:44px" aria-label="Khoá màn hình" on:click=move |_| { locked.set(true); panel.set(None); }><Icon d=ic::LOCK_OPEN /></div>
                                <div class="ricon glass" style="width:44px;height:44px" aria-label="Hình trong hình" on:click=move |_| if let Some(v) = video.get_untracked() { glue::pip(&v) }><Icon d=ic::PIP /></div>
                                {glue::desktop().then(|| view! {
                                    <div class="ricon glass" style="width:44px;height:44px" aria-label="Toàn màn hình" on:click=move |_| if let Some(p) = root.get_untracked() { glue::fullscreen(&p) }><Icon d=ic::EXPAND /></div>
                                })}
                                <div class="ricon glass" style="width:44px;height:44px" aria-label="Cài đặt" on:click=move |_| panel.set(Some(Panel::Settings))><Icon d=ic::SETTINGS /></div>
                                {many.then(|| view! {
                                    <div class="ricon glass" style="width:44px;height:44px" aria-label="Danh sách tập" on:click=move |_| panel.set(Some(Panel::Episodes))><Icon d=ic::LIBRARY /></div>
                                })}
                            </div>
                        </div>
                        {move || (!error.get()).then(|| view! {
                            <div class="pmid">
                                <div class="ricon" style="width:56px;height:56px" aria-label="Lùi 10 giây" on:click=move |_| { seek_by(-10.0); poke(); }><Icon d=ic::ROT_L /><span class="ten">"10"</span></div>
                                <div class="big glass" on:click=move |_| { toggle(); poke(); }>
                                    <svg viewBox="0 0 24 24"><path d=move || if playing.get() { ic::PAUSE } else if ended.get() { ic::ROT_L } else { ic::PLAY } /></svg>
                                </div>
                                <div class="ricon" style="width:56px;height:56px" aria-label="Tới 10 giây" on:click=move |_| { seek_by(10.0); poke(); }><Icon d=ic::ROT_R /><span class="ten">"10"</span></div>
                            </div>
                        })}
                        <div class="pbot">
                            <div class="seek" class:drag=move || seek_drag.with(|s| s.is_some())
                                on:pointerdown=move |e| { e.stop_propagation(); if let Some(f) = seek_frac(&e) { seek_drag.set(Some(f)); } if let Some(t) = e.target() { use wasm_bindgen::JsCast; if let Ok(el) = t.dyn_into::<web_sys::Element>() { let _ = el.set_pointer_capture(e.pointer_id()); } } }
                                on:pointermove=move |e| if seek_drag.get_untracked().is_some() { if let Some(f) = seek_frac(&e) { seek_drag.set(Some(f)); poke(); } }
                                on:pointerup=move |_| if let Some(f) = seek_drag.get_untracked() { seek_to(f * dur.get_untracked()); seek_drag.set(None); poke(); }>
                                {move || {
                                    let d = dur.get().max(0.001);
                                    let f = seek_drag.get().unwrap_or(pos.get() / d).clamp(0.0, 1.0) * 100.0;
                                    let b = (buffered.get() / d).clamp(0.0, 1.0) * 100.0;
                                    view! {
                                        <div class="tr"><div class="bf" style=format!("width:{b}%")></div><div class="pl" style=format!("width:{f}%")></div></div>
                                        <div class="th" style=format!("left:{f}%")></div>
                                        {seek_drag.get().map(|s| view! { <div class="bub" style=format!("left:{f}%")>{clock(s * d)}</div> })}
                                    }
                                }}
                            </div>
                            <div class="prow">
                                <span>{move || format!("{} / {}", clock(pos.get()), clock(dur.get()))}</span>
                                <span class="sp"></span>
                                {move || next_index().map(|i| view! {
                                    <span class="nx" on:click=move |_| switch(server.get_untracked(), i)><Icon d=ic::SKIP_NEXT fill=true />" Tập tiếp"</span>
                                })}
                            </div>
                        </div>
                    </div>
                }.into_any()
            }}

            {move || error.get().then(|| view! {
                <div class="perr glass">
                    <b>"Không phát được tập này"</b>
                    <span>"Thử lại hoặc đổi server trong danh sách tập."</span>
                    <div class="two">
                        <span class="pchip hi" on:click=move |_| load(Some(pos.get_untracked()))>"Thử lại"</span>
                        <span class="pchip" on:click=move |_| panel.set(Some(Panel::Episodes))>"Đổi server"</span>
                    </div>
                </div>
            })}
            {move || offline.get().then(|| view! { <div class="offline glass"><Icon d=ic::WIFI_OFF />"Mất kết nối mạng · sẽ tự phát lại khi có mạng"</div> })}
            {move || next_card().then(|| {
                let i = next_index().unwrap_or(0);
                let name = ep(server.get_untracked(), i).and_then(|e| e.name).map(|x| api::ep_label(&x)).unwrap_or_default();
                view! {
                    <div class="nextc glass" style:bottom=move || if controls.get() { "calc(110px + var(--bottom))" } else { "calc(32px + var(--bottom))" }>
                        <div class="th"><Img src=film_s.with_value(|f| f.thumb()) /><b>{move || (dur.get() - pos.get()).ceil().max(0.0).to_string()}</b></div>
                        <div class="c">
                            <small>"TẬP TIẾP THEO"</small>
                            <span class="n">{name}</span>
                            <div class="two">
                                <span class="pchip hi" on:click=move |_| switch(server.get_untracked(), i)>"Phát ngay"</span>
                                <span class="pchip" on:click=move |_| cancelled.set(true)>"Huỷ"</span>
                            </div>
                        </div>
                    </div>
                }
            })}
            {move || panel.get().map(|p| match p {
                Panel::Settings => view! { <SettingsPanel panel=panel speed=speed fit=fit sleep=sleep video=video /> }.into_any(),
                Panel::Episodes => view! { <EpisodesPanel panel=panel det=det server=server index=index switch=Callback::new(move |(s, i)| switch(s, i)) /> }.into_any(),
            })}
        </div>
    }
}

fn section(title: &'static str, opts: Vec<(String, bool, Callback<()>)>) -> impl IntoView {
    view! {
        <div>
            <div class="stitle">{title}</div>
            <div class="opts">{opts.into_iter().map(|(l, on, cb)| view! { <span class="opt" class:on=on on:click=move |_| cb.run(())>{l}</span> }).collect_view()}</div>
        </div>
    }
}

#[component]
fn SettingsPanel(panel: RwSignal<Option<Panel>>, speed: RwSignal<f64>, fit: RwSignal<u8>, sleep: RwSignal<Option<Sleep>>, video: NodeRef<leptos::html::Video>) -> impl IntoView {
    view! {
        <div class="ppanel">
            <div class="h">"Cài đặt phát"<span aria-label="Đóng" on:click=move |_| panel.set(None)><Icon d=ic::CLOSE /></span></div>
            {move || section("Tốc độ", [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].into_iter().map(|s| {
                let l = if s == 1.0 { "Bình thường".to_string() } else { format!("{s}×") };
                (l, speed.get() == s, Callback::new(move |_| { speed.set(s); if let Some(v) = video.get_untracked() { v.set_playback_rate(s) } }))
            }).collect())}
            {move || section("Khung hình", ["Vừa", "Phóng", "Giãn"].into_iter().enumerate().map(|(i, l)| {
                (l.to_string(), fit.get() == i as u8, Callback::new(move |_| fit.set(i as u8)))
            }).collect())}
            {move || {
                let cur = sleep.get();
                let mut o = vec![("Tắt".to_string(), cur.is_none(), Callback::new(move |_| sleep.set(None)))];
                for m in [15u32, 30, 45, 60] {
                    o.push((format!("{m} phút"), matches!(cur, Some(Sleep::At(_, x)) if x == m), Callback::new(move |_| sleep.set(Some(Sleep::At(glue::now() + m as f64 * 60_000.0, m))))));
                }
                o.push(("Hết tập này".into(), cur == Some(Sleep::EndOfEpisode), Callback::new(move |_| sleep.set(Some(Sleep::EndOfEpisode)))));
                section("Hẹn giờ tắt", o)
            }}
        </div>
    }
}

#[component]
fn EpisodesPanel(panel: RwSignal<Option<Panel>>, det: StoredValue<api::Detail>, server: RwSignal<usize>, index: RwSignal<usize>, switch: Callback<(usize, usize)>) -> impl IntoView {
    let shown = RwSignal::new(server.get_untracked());
    let grid = NodeRef::<leptos::html::Div>::new();
    // Opens scrolled to the current episode minus 6 (two rows of three above it).
    Effect::new(move |_| if let Some(g) = grid.get() {
        let row = index.get_untracked().saturating_sub(6) / 3;
        g.set_scroll_top((row * 52) as i32);
    });
    view! {
        <div class="ppanel">
            <div class="h">"Danh sách tập"<span aria-label="Đóng" on:click=move |_| panel.set(None)><Icon d=ic::CLOSE /></span></div>
            {move || (det.with_value(|d| d.episodes.len()) > 1).then(|| section("Server", det.with_value(|d| d.episodes.iter().enumerate().map(|(i, s)| {
                (s.server_name.clone().unwrap_or_else(|| format!("Server {}", i + 1)), shown.get() == i, Callback::new(move |_| shown.set(i)))
            }).collect())))}
            <div class="epgrid" node_ref=grid style="overflow-y:auto;flex:1;align-content:start">
                {move || {
                    let s = shown.get();
                    det.with_value(|d| d.episodes.get(s).map(|sv| sv.server_data.clone()).unwrap_or_default()).into_iter().enumerate().map(|(i, e)| {
                        let on = server.get() == s && index.get() == i;
                        let label = e.name.clone().filter(|x| !x.is_empty()).unwrap_or_else(|| (i + 1).to_string());
                        view! { <span class:on=on class:off=e.stream().is_none() on:click=move |_| { panel.set(None); switch.run((s, i)); }>{label}</span> }
                    }).collect_view()
                }}
            </div>
        </div>
    }
}
