//! Trang chủ, as feature/home: hero pager with preview, Xem tiếp, Danh sách, Top 10 deck, countries, 9 rails.

use std::collections::HashMap;
use std::time::Duration;

use leptos::prelude::*;
use leptos::task::spawn_local;
use leptos::leptos_dom::helpers::{set_timeout_with_handle, TimeoutHandle};

use super::*;
use crate::api::{Detail, Filter};
use crate::glue;

fn rails() -> Vec<(&'static str, &'static str, Source)> {
    let t = |s: &str| Source::Type(s.into());
    let c = |s: &str| Source::Country(s.into());
    let g = |s: &str| Source::Genre(s.into());
    vec![
        ("Mới cập nhật", "Mới cập nhật", t("phim-moi-cap-nhat")),
        ("Phim Hàn Quốc", "Hàn Quốc", c("han-quoc")),
        ("Phim Trung Quốc", "Trung Quốc", c("trung-quoc")),
        ("Phim lẻ", "Phim lẻ", t("phim-le")),
        ("TV Shows", "TV Shows", t("tv-shows")),
        ("Hành động", "Hành động", g("hanh-dong")),
        ("Tình cảm", "Tình cảm", g("tinh-cam")),
        ("Kinh dị", "Kinh dị", g("kinh-di")),
        ("Hoạt hình", "Hoạt hình", t("hoat-hinh")),
    ]
}

#[derive(Clone, Copy)]
struct HomeData {
    hero: RwSignal<Vec<Film>>,
    top10: RwSignal<Vec<Film>>,
    details: RwSignal<HashMap<String, Detail>>,
    arts: RwSignal<HashMap<String, String>>,
    ready: RwSignal<bool>,
    rails: [RwSignal<Option<Vec<Film>>>; 9],
}

/// Ponytail: the Android fallback ranks by KKPhim views (one detail call per film); here it is "freshest" straight away.
async fn freshest() -> Vec<Film> {
    let mut all = vec![];
    for p in 1..=2 {
        if let Ok(pg) = api::list(&Source::Type("phim-moi-cap-nhat".into()), p, &Filter::default()).await { all.extend(pg.items); }
    }
    let big = |f: &Film| f.country.iter().any(|c| matches!(c.slug.as_deref(), Some("han-quoc" | "trung-quoc" | "au-my")));
    all.sort_by_key(|f| !big(f));
    all.into_iter().filter(|f| !f.is_animation()).take(10).collect()
}

impl HomeData {
    fn load(self) {
        self.ready.set(false);
        for r in self.rails { r.set(None); }
        spawn_local(async move {
            let hot = api::hot().await;
            let mut hero: Vec<Film> = hot.as_ref().map(|h| h.films.iter().filter(|f| !f.is_animation()).take(12).cloned().collect()).unwrap_or_default();
            if hero.len() < 5 { hero = freshest().await; }
            self.top10.set(hot.map(|h| h.series.into_iter().take(10).collect()).unwrap_or_default());
            // Key art + story for each; the hero waits for them up to 2.5 s so the art doesn't swap in late.
            let left = RwSignal::new(hero.len());
            for f in &hero {
                let slug = f.slug.clone();
                spawn_local(async move {
                    if let Ok(d) = api::detail(&slug).await { self.details.update(|m| { m.insert(slug.clone(), d); }); }
                    if let Some(p) = api::backdrops(&slug).await.first() { self.arts.update(|m| { m.insert(slug.clone(), api::tmdb(p, "w1280")); }); }
                    left.update(|n| *n -= 1);
                    if left.get_untracked() == 0 { self.ready.set(true); }
                });
            }
            self.hero.set(hero);
            gloo_timers::future::TimeoutFuture::new(2500).await;
            self.ready.set(true);
        });
        for (i, (_, _, src)) in rails().into_iter().enumerate() {
            let sig = self.rails[i];
            spawn_local(async move { sig.set(Some(api::list(&src, 1, &Filter::default()).await.map(|p| p.items).unwrap_or_default())) });
        }
    }
}

#[component]
pub fn Home() -> impl IntoView {
    let n = nav();
    let data = HomeData {
        hero: RwSignal::new(vec![]),
        top10: RwSignal::new(vec![]),
        details: RwSignal::new(HashMap::new()),
        arts: RwSignal::new(HashMap::new()),
        ready: RwSignal::new(false),
        rails: std::array::from_fn(|_| RwSignal::new(None)),
    };
    data.load();
    let settled = RwSignal::new(0usize);
    let scroll_y = RwSignal::new(0.0);
    // The wash behind the page: the settled hero art's tint at 35%, Brand until sampled.
    let tint = RwSignal::new("61,139,255".to_string());
    Effect::new(move |_| {
        let i = settled.get();
        let Some(f) = data.hero.with(|h| h.get(i).cloned()) else { return };
        let url = data.arts.with(|a| a.get(&f.slug).cloned()).unwrap_or_else(|| f.thumb());
        spawn_local(async move { if let Some(c) = glue::tint_of(&url).await { tint.set(c) } });
    });
    let failed = move || data.ready.get() && data.hero.with(|h| h.is_empty()) && data.rails.iter().all(|r| r.with(|v| v.as_ref().is_some_and(|v| v.is_empty())));
    view! {
        <div class="home-bg" style:background=move || format!("linear-gradient(rgba({},.35), var(--canvas) 50%)", tint.get())></div>
        <div class="scroll" on:scroll=move |e| scroll_y.set(scroll_top(&e))>
            <div class="home-col">
                {move || if data.ready.get() && !data.hero.with(|h| h.is_empty()) {
                    view! { <Hero data=data settled=settled scroll_y=scroll_y /> }.into_any()
                } else {
                    view! { <div class="hero ph"></div> }.into_any()
                }}
                {move || {
                    n.lib.get();
                    let h = store::history();
                    (!h.is_empty()).then(|| view! {
                        <Shelf title="Xem tiếp" gap=14>{h.into_iter().take(15).map(|w| view! { <ContinueCard w=w /> }).collect_view()}</Shelf>
                    })
                }}
                {move || {
                    n.lib.get();
                    let s = store::saved();
                    (!s.is_empty()).then(|| view! {
                        <Shelf title="Danh sách của tôi">{s.into_iter().map(|f| view! { <PosterCard film=f /> }).collect_view()}</Shelf>
                    })
                }}
                {move || { let t = data.top10.get(); (!t.is_empty()).then(|| view! { <Top10 films=t /> }) }}
                <CountryShelf />
                {rails().into_iter().enumerate().map(|(i, (title, list_title, src))| {
                    let sig = data.rails[i];
                    move || poster_shelf(title.into(), Some((list_title.into(), src.clone())), sig.get())
                }).collect_view()}
                {move || failed().then(|| view! {
                    <div class="err-box"><div>"Không tải được phim"</div><div class="mbtn" on:click=move |_| data.load()>"Thử lại"</div></div>
                })}
            </div>
        </div>
        <HomeHeader />
    }
}

#[component]
fn HomeHeader() -> impl IntoView {
    let n = nav();
    let pill = move |label: &'static str, slug: &'static str| view! {
        <div class="pill glass press" on:click=move |_| n.list(label, Source::Type(slug.into()))>{label}</div>
    };
    view! {
        <div class="home-head">
            <div class="wordmark">"TMOVIE"</div>
            <div class="pills">
                <GenrePickerPill countries=true />
                <GenrePickerPill countries=false />
                {pill("Phim bộ", "phim-bo")}
                {pill("Phim lẻ", "phim-le")}
                {pill("TV Shows", "tv-shows")}
            </div>
        </div>
    }
}

fn title_size(name: &str) -> (u32, u32, u32) {
    match name.chars().count() {
        0..=16 => (40, 41, 2),
        17..=26 => (34, 36, 2),
        _ => (28, 31, 3),
    }
}

#[component]
fn Hero(data: HomeData, settled: RwSignal<usize>, scroll_y: RwSignal<f64>) -> impl IntoView {
    let n = nav();
    let films = data.hero.get_untracked();
    let count = films.len();
    let pager = NodeRef::<leptos::html::Div>::new();
    let pos = RwSignal::new(0.0f64);
    let touching = RwSignal::new(false);
    let autoplay = store::flag("heroAutoplay", true) && !glue::reduce_motion();
    let muted = RwSignal::new(store::flag("heroMuted", true));
    let previewing = RwSignal::new(false);
    let (w, _) = glue::win();
    let active = move || n.tab.get() == 0 && n.stack.with(|s| s.is_empty()) && n.play.with(|p| p.is_none());
    let go_to = move |i: usize| if let Some(el) = pager.get_untracked() {
        let o = web_sys::ScrollToOptions::new();
        o.set_left(i as f64 * el.client_width() as f64);
        o.set_behavior(web_sys::ScrollBehavior::Smooth);
        el.scroll_to_with_scroll_to_options(&o);
    };
    // Auto-advance 8 s after each settle (30 s while previews play), skipped while the finger is down.
    Effect::new(move |prev: Option<Option<TimeoutHandle>>| {
        if let Some(Some(h)) = prev { h.clear(); }
        let s = settled.get();
        set_timeout_with_handle(move || if !touching.get_untracked() { go_to((s + 1) % count) }, Duration::from_millis(if autoplay { 30_000 } else { 8_000 })).ok()
    });
    view! {
        <div class="hero" style:transform=move || format!("translateY({}px)", scroll_y.get() * 0.35)>
            <div class="pager" node_ref=pager
                on:touchstart=move |_| touching.set(true) on:touchend=move |_| touching.set(false)
                on:scroll=move |_| if let Some(el) = pager.get_untracked() {
                    let p = el.scroll_left() as f64 / el.client_width().max(1) as f64;
                    pos.set(p);
                    let r = p.round();
                    if (p - r).abs() < 0.02 && settled.get_untracked() != r as usize { settled.set(r as usize); }
                }>
                {films.into_iter().enumerate().map(|(i, f)| {
                    let off = move || pos.get() - i as f64;
                    let slug = f.slug.clone();
                    let s2 = slug.clone();
                    let s3 = slug.clone();
                    let art = Signal::derive(move || data.arts.with(|a| a.get(&s2).cloned()).unwrap_or_default());
                    let thumb = f.thumb();
                    let src = Signal::derive(move || { let a = art.get(); if a.is_empty() { thumb.clone() } else { a } });
                    let film = f.clone();
                    let detail = move || data.details.with(|m| m.get(&s3).cloned());
                    let stream = {
                        let detail = detail.clone();
                        move || detail().and_then(|d| d.servers().first().and_then(|s| s.server_data.iter().find_map(|e| e.stream().map(String::from))))
                    };
                    let (ts, lh, lines) = title_size(&f.name);
                    let open = f.clone();
                    view! {
                        <div class="page-h" on:click=move |_| n.open(open.clone())>
                            <div class="art" style:transform=move || format!("translateX({}px)", off() * w * 0.4)>
                                <Img src=src />
                                {move || (autoplay && active() && settled.get() == i).then(|| stream()).flatten()
                                    .map(|u| view! { <HeroVideo url=u muted=muted previewing=previewing /> })}
                            </div>
                            <div class="scrim" style="background:linear-gradient(rgba(0,0,0,.7) 0%, rgba(0,0,0,.25) 16%, transparent 30%, transparent 46%, rgba(0,0,0,.38) 62%, rgba(0,0,0,.72) 80%, var(--canvas) 100%)"></div>
                            <div class="cap" style:opacity=move || (1.0 - off().abs() * 1.4).max(0.0).to_string()
                                style:transform=move || format!("translateX({}px)", off() * 60.0)>
                                <div class="top"><span class="b">{format!("TOP {}", i + 1)}</span><span>"Đang hot tuần này"</span></div>
                                <div class="tt" style=format!("font-size:{ts}px;line-height:{lh}px;-webkit-line-clamp:{lines}")>{f.name.clone()}</div>
                                {move || {
                                    let d = detail();
                                    let film = d.as_ref().map(|d| d.film.clone()).unwrap_or_else(|| f.clone());
                                    let facts = film.kind_label().map(String::from).into_iter()
                                        .chain(film.category.iter().take(2).filter_map(|c| c.name.clone()))
                                        .chain(film.year.map(|y| y.to_string())).collect::<Vec<_>>().join(" · ");
                                    let lang = film.lang.clone().unwrap_or_default().to_lowercase();
                                    let lang = if lang.contains("thuyết") || lang.contains("lồng") { "TM" } else { "VS" };
                                    let story = d.as_ref().and_then(|d| d.content.as_deref().map(api::plain)).unwrap_or_default();
                                    view! {
                                        <div class="facts">
                                            <span class="ft">{facts}</span>
                                            {film.quality.clone().filter(|q| !q.is_empty()).map(|q| view! { <span class="hbadge">{q}</span> })}
                                            <span class="hbadge">{lang}</span>
                                        </div>
                                        <div class="hstory">{story}</div>
                                    }
                                }}
                                <div class="btns">
                                    <PlayFilmButton film=film.clone() />
                                    <SaveButton film=film style=SaveStyle::Circle />
                                    {move || (previewing.get() && settled.get() == i).then(|| view! {
                                        <div class="save-circle glass press" aria-label=move || if muted.get() { "Bật tiếng xem trước" } else { "Tắt tiếng xem trước" }
                                            on:click=move |e| { e.stop_propagation(); let m = !muted.get_untracked(); muted.set(m); store::set_flag("heroMuted", m); }>
                                            <svg viewBox="0 0 24 24"><path d=move || if muted.get() { ic::VOL_OFF } else { ic::VOL_UP } /></svg>
                                        </div>
                                    })}
                                </div>
                            </div>
                        </div>
                    }
                }).collect_view()}
            </div>
            <div class="dots glass">
                {(0..count).map(|i| view! { <i class:on=move || settled.get() == i></i> }).collect_view()}
            </div>
        </div>
    }
}

/// HeroPreview: 1.5 s after settling, plays episode 1 muted from 4:00 (or 10%), looping a 45 s window.
#[component]
fn HeroVideo(url: String, muted: RwSignal<bool>, previewing: RwSignal<bool>) -> impl IntoView {
    let v = NodeRef::<leptos::html::Video>::new();
    let start = StoredValue::new(0.0f64);
    let shown = RwSignal::new(false);
    let h = set_timeout_with_handle(move || if let Some(el) = v.get_untracked() { glue::attach(&el, &url) }, Duration::from_millis(1500)).ok();
    on_cleanup(move || {
        if let Some(h) = h { h.clear(); }
        if let Some(el) = v.get_untracked() { let _ = el.pause(); glue::detach(&el); }
        previewing.set(false);
    });
    view! {
        <video node_ref=v class="hero-video" muted=true playsinline=true prop:muted=move || muted.get()
            style:opacity=move || if shown.get() { "1" } else { "0" }
            on:loadedmetadata=move |_| if let Some(el) = v.get_untracked() {
                let d = el.duration();
                let s = if d > 600.0 { 240.0 } else { d / 10.0 };
                start.set_value(s);
                el.set_current_time(s);
                let _ = el.play();
            }
            on:timeupdate=move |_| if let Some(el) = v.get_untracked() {
                let t = el.current_time();
                let s = start.get_value();
                if t > s + 45.0 { el.set_current_time(s); }
                if !shown.get_untracked() && t > s + 0.3 { shown.set(true); previewing.set(true); }
            }>
        </video>
    }
}

/// Top 10 deck: cards fanned across the width, rank on the art; swipe steps endlessly, like a deck of cards.
#[component]
fn Top10(films: Vec<Film>) -> impl IntoView {
    let n = nav();
    let count = films.len();
    let top = RwSignal::new(0usize);
    let drag = RwSignal::new(0.0f64);
    let leaving = RwSignal::new(None::<usize>);
    let start = StoredValue::new(None::<(f64, usize)>);
    let films_store = StoredValue::new(films.clone());
    let films_at = move |i: usize| films_store.with_value(|f| f[i].clone());
    let step = move |left: bool| {
        if left {
            let t = top.get_untracked();
            leaving.set(Some(t));
            set_timeout(move || { top.set((t + 1) % count); leaving.set(None); }, Duration::from_millis(260));
        } else {
            top.update(|t| *t = (*t + count - 1) % count);
        }
    };
    let up = move |x: f64| {
        let Some((x0, i)) = start.get_value() else { return };
        start.set_value(None);
        let dx = x - x0;
        drag.set(0.0);
        if dx.abs() >= 40.0 { step(dx < 0.0) } else if dx.abs() < 8.0 {
            let k = (i + count - top.get_untracked()) % count;
            if k == 0 { n.open(films_at(i)) } else if k <= 4 { top.set(i) }
        }
    };
    view! {
        <div class="shelf">
            <RailHeader title="Top 10 phim bộ tuần này" more=Some(("Phim bộ".into(), Source::Type("phim-bo".into()))) />
            <div class="deck"
                on:pointermove=move |e| if let Some((x0, _)) = start.get_value() { drag.set(e.client_x() as f64 - x0) }
                on:pointerup=move |e| up(e.client_x() as f64)
                on:pointercancel=move |_| { start.set_value(None); drag.set(0.0); }>
                {films.into_iter().enumerate().map(|(i, f)| {
                    let k = move || (i + count - top.get()) % count;
                    let style = move || {
                        let k = k();
                        let v = k.min(4) as f64;
                        if leaving.get() == Some(i) {
                            return "transform:translate(-150px,-6px) scale(.96) rotate(-12deg);z-index:21;opacity:1".to_string();
                        }
                        let dx = if k == 0 { drag.get() * 0.6 } else { 0.0 };
                        format!("transform:translate({}px,{}px) scale({});z-index:{};opacity:{}",
                            18.0 + v * 64.0 + dx, v * 7.0, 1.0 - v * 0.075, 20 - k as i32, if k > 4 { 0 } else { 1 })
                    };
                    let rank = match i { 0 => "rk r1", 1 => "rk r2", 2 => "rk r3", _ => "rk" };
                    view! {
                        <div class="card" class:drag=move || drag.get() != 0.0 && k() == 0 style=style
                            on:pointerdown=move |e| start.set_value(Some((e.client_x() as f64, i)))
                            on:dragstart=|e| e.prevent_default()>
                            <img src=f.poster() alt="" loading="lazy" />
                            <div class="g"></div>
                            <div class="dim" style:opacity=move || (k().min(4) as f64 * 0.13).min(0.5).to_string()></div>
                            <div class=rank>{i + 1}</div>
                            {f.badge().map(|b| view! { <span class="epb">{b}</span> })}
                        </div>
                    }
                }).collect_view()}
            </div>
        </div>
    }
}
