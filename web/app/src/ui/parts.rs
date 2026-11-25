//! Shared pieces, as the Android core/ui + designsystem: cards, shelves, buttons, pickers, menus, the pager.

use leptos::prelude::*;
use leptos::task::spawn_local;
use wasm_bindgen::JsCast;

use super::{nav, Menu, MenuItem, Nav, Picker};
use crate::api::{self, Category, Film, Filter, Source};
use crate::store;

/// Icon paths on a 24-unit grid (stroke icons unless drawn with `class="fill"`).
pub mod ic {
    pub const PLAY: &str = "M7.5 4.8v14.4a.8.8 0 0 0 1.2.7l11.4-7.2a.8.8 0 0 0 0-1.4L8.7 4.1a.8.8 0 0 0-1.2.7z";
    pub const PAUSE: &str = "M6 4.5h4v15H6zM14 4.5h4v15h-4z";
    pub const PLUS: &str = "M12 5v14M5 12h14";
    pub const CHECK: &str = "M5 12.5l4.5 4.5L19 7.5";
    pub const CHEV_R: &str = "M9.5 6l6 6-6 6";
    pub const CHEV_L: &str = "M14.5 6l-6 6 6 6";
    pub const EXPAND: &str = "M4 9V4h5M15 4h5v5M20 15v5h-5M9 20H4v-5";
    pub const CHEV_D: &str = "M6.5 9.5l5.5 5.5 5.5-5.5";
    pub const BACK: &str = "M20 12H4.5M11 5l-7 7 7 7";
    pub const CLOSE: &str = "M18 6L6 18M6 6l12 12";
    pub const FILTER: &str = "M3 6.5h18M6.5 12h11M10 17.5h4";
    pub const SEARCH: &str = "M3 11a8 8 0 1 0 16 0a8 8 0 1 0-16 0M21 21l-4.3-4.3";
    pub const SEND: &str = "M21.5 2.5L10.5 13.5M21.5 2.5l-7 19-4-8-8-4z";
    pub const MOVIE: &str = "M3 5h18v14H3zM7 5v14M17 5v14M3 9.5h4M3 14.5h4M17 9.5h4M17 14.5h4";
    pub const PLAY_CIRCLE: &str = "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M10 8.5v7l5.5-3.5z";
    pub const ROT_L: &str = "M3.5 12a8.5 8.5 0 1 0 2.6-6.1L3.5 8.5M3.5 3.5v5h5";
    pub const ROT_R: &str = "M20.5 12a8.5 8.5 0 1 1-2.6-6.1l2.6 2.6M20.5 3.5v5h-5";
    pub const LOCK: &str = "M5 11h14v10H5zM8 11V7.5a4 4 0 0 1 8 0V11";
    pub const LOCK_OPEN: &str = "M5 11h14v10H5zM8 11V7.5a4 4 0 0 1 7.8-1.3";
    pub const PIP: &str = "M3 5h18v14H3zM12.5 12h6v4.5h-6z";
    pub const SETTINGS: &str = "M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1.5 14h5M9.5 8h5M17.5 16h5";
    pub const LIBRARY: &str = "M3 7h14v14H3zM7 3h14v14M8.5 11v6l5-3z";
    pub const SKIP_NEXT: &str = "M5.5 5.5l9.5 6.5-9.5 6.5zM16.5 5.5h2v13h-2z";
    pub const INFO: &str = "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M12 11v5.5M12 7.8v.4";
    pub const VOL_OFF: &str = "M11 5L6 9H2.5v6H6l5 4zM22 9l-6 6M16 9l6 6";
    pub const VOL_UP: &str = "M11 5L6 9H2.5v6H6l5 4zM15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9.5 9.5 0 0 1 0 13";
    pub const SUN: &str = "M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4";
    pub const HISTORY: &str = "M3.5 12a8.5 8.5 0 1 0 2.6-6.1L3.5 8.5M3.5 3.5v5h5M12 7.5V12l3.5 2";
    pub const TRASH: &str = "M4 6.5h16M9 6.5V4h6v2.5M6 6.5l1 14h10l1-14M10 10.5v6M14 10.5v6";
    pub const SLIDES: &str = "M3 4.5h18v12H3zM8 20.5h8M10.5 8.5v4l3.5-2z";
    pub const WIFI_OFF: &str = "M2 2l20 20M8.5 16.4a5 5 0 0 1 7 0M5 12.6a10 10 0 0 1 4.8-2.6M19 12.6a10 10 0 0 0-2.2-1.6M2 8.8A15 15 0 0 1 6.1 6.3M22 8.8A15 15 0 0 0 11 5.1M12 20h.01";
    pub const SPARKLE: &str = "M12 3l1.9 5.6 5.6 1.9-5.6 1.9L12 18l-1.9-5.6-5.6-1.9 5.6-1.9zM19 15l.8 2.2 2.2.8-2.2.8L19 21l-.8-2.2-2.2-.8 2.2-.8z";
}

#[component]
pub fn Icon(d: &'static str, #[prop(optional)] fill: bool) -> impl IntoView {
    view! { <svg viewBox="0 0 24 24" class:fill=fill><path d=d /></svg> }
}

fn hide_img(e: &web_sys::Event) {
    if let Some(el) = e.target().and_then(|t| t.dyn_into::<web_sys::Element>().ok()) {
        let _ = el.set_attribute("style", "opacity:0");
    }
}

/// RemoteImage: white-6% placeholder, 250 ms fade-in.
#[component]
pub fn Img(#[prop(into)] src: Signal<String>, #[prop(optional, into)] class: String, #[prop(optional, into)] style: String) -> impl IntoView {
    view! {
        <div class=format!("img-ph {class}") style=style>
            <img src=move || src.get() alt="" loading="lazy" decoding="async" on:error=move |e| hide_img(&e) />
        </div>
    }
}

pub fn spinner(size: u32) -> impl IntoView {
    view! { <div class="spinner" style=format!("width:{size}px;height:{size}px")></div> }
}

/// PosterCard: 2:3, radius 8, episode badge, no title.
#[component]
pub fn PosterCard(film: Film, #[prop(optional)] cell: bool) -> impl IntoView {
    let n = nav();
    let badge = film.badge();
    let src = film.poster();
    view! {
        <div class="poster" class:cell=cell on:click=move |_| n.open(film.clone())>
            <Img src=src />
            {badge.map(|b| view! { <span class="epb">{b}</span> })}
        </div>
    }
}

pub fn placeholders() -> impl IntoView { (0..5).map(|_| view! { <div class="poster ph"></div> }).collect_view() }

#[component]
pub fn RailHeader(#[prop(into)] title: String, #[prop(default = None)] more: Option<(String, Source)>) -> impl IntoView {
    let n = nav();
    view! {
        <div class="rail-head">
            <div class="section-title">{title}</div>
            {more.map(|(t, s)| view! {
                <div class="all" on:click=move |_| n.list(t.clone(), s.clone())>"Tất cả"<Icon d=ic::CHEV_R /></div>
            })}
        </div>
    }
}

/// Shelf: header + a horizontal row with 16 px padding and 8 px gaps (14 for "Xem tiếp").
#[component]
pub fn Shelf(#[prop(into)] title: String, #[prop(default = None)] more: Option<(String, Source)>, #[prop(default = 8)] gap: u32, children: Children) -> impl IntoView {
    view! {
        <div class="shelf">
            <RailHeader title=title more=more />
            <HScroll class="row" style=format!("gap:{gap}px")>{children()}</HScroll>
        </div>
    }
}

/// A horizontal row; on desktop, arrows on hover scroll it by most of its width.
#[component]
pub fn HScroll(class: &'static str, #[prop(optional, into)] style: String, children: Children) -> impl IntoView {
    let row = NodeRef::<leptos::html::Div>::new();
    let by = move |dir: f64| if let Some(el) = row.get_untracked() {
        let o = web_sys::ScrollToOptions::new();
        o.set_left(el.scroll_left() as f64 + dir * el.client_width() as f64 * 0.8);
        o.set_behavior(web_sys::ScrollBehavior::Smooth);
        el.scroll_to_with_scroll_to_options(&o);
    };
    view! {
        <div class="hwrap">
            <div class=class style=style node_ref=row>{children()}</div>
            <div class="arr l" aria-label="Trước" on:click=move |_| by(-1.0)><Icon d=ic::CHEV_L /></div>
            <div class="arr r" aria-label="Sau" on:click=move |_| by(1.0)><Icon d=ic::CHEV_R /></div>
        </div>
    }
}

/// The poster shelf every list section uses; hidden once it loads empty.
pub fn poster_shelf(title: String, more: Option<(String, Source)>, films: Option<Vec<Film>>) -> AnyView {
    match films {
        None => view! { <Shelf title=title more=more>{placeholders()}</Shelf> }.into_any(),
        Some(v) if v.is_empty() => ().into_any(),
        Some(v) => view! { <Shelf title=title more=more>{v.into_iter().map(|f| view! { <PosterCard film=f /> }).collect_view()}</Shelf> }.into_any(),
    }
}

/// ContinueCard: the paused frame (or the thumb), progress, minutes left; tap resumes playback.
#[component]
pub fn ContinueCard(w: store::Watch) -> impl IntoView {
    let n = nav();
    let busy = RwSignal::new(false);
    let img = store::frame(&w.film.slug).unwrap_or_else(|| w.film.thumb());
    let ep = api::ep_label(&w.episode_name);
    let pct = w.last_progress().max(0.03) * 100.0;
    let left = w.minutes_left();
    let slug = w.film.slug.clone();
    view! {
        <div class="cont" on:click=move |_| if !busy.get_untracked() { n.play_slug(slug.clone(), busy) }>
            <div class="im">
                <Img src=img />
                <div class="shade"></div>
                <div class="playb glass" aria-label="Tiếp tục xem">
                    {move || if busy.get() { spinner(24).into_any() } else { view! { <Icon d=ic::PLAY fill=true /> }.into_any() }}
                </div>
                {(!ep.is_empty()).then(|| view! { <span class="chip glass">{ep}</span> })}
                <div class="bot">
                    <div class="track"><i style=format!("width:{pct}%")></i></div>
                    {left.map(|m| view! { <span>{format!("Còn {m} phút")}</span> })}
                </div>
            </div>
            <b>{w.film.name.clone()}</b>
        </div>
    }
}

#[derive(Clone, Copy, PartialEq)]
pub enum SaveStyle { Column, Wide, Circle }

/// SaveButton: toggles "Danh sách của tôi".
#[component]
pub fn SaveButton(film: Film, style: SaveStyle) -> impl IntoView {
    let n = nav();
    let slug = film.slug.clone();
    let on = Signal::derive(move || { n.lib.get(); store::is_saved(&slug) });
    let toggle = move |e: web_sys::MouseEvent| {
        e.stop_propagation();
        store::toggle_saved(&film);
        n.bump();
    };
    let icon = move || view! { <svg viewBox="0 0 24 24"><path d=move || if on.get() { ic::CHECK } else { ic::PLUS } /></svg> };
    let label = move || if on.get() { "Bỏ khỏi danh sách" } else { "Thêm vào danh sách" };
    match style {
        SaveStyle::Column => view! { <div class="save-col" aria-label=label on:click=toggle>{icon}<span>"Danh sách"</span></div> }.into_any(),
        SaveStyle::Wide => view! { <div class="save-wide glass press" aria-label=label on:click=toggle>{icon}" Danh sách"</div> }.into_any(),
        SaveStyle::Circle => view! { <div class="save-circle glass press" aria-label=label on:click=toggle>{icon}</div> }.into_any(),
    }
}

/// PlayFilmButton: capsule "Xem ngay"/"Xem tiếp", wide "Phát"/"Tiếp tục".
#[component]
pub fn PlayFilmButton(film: Film, #[prop(optional)] wide: bool) -> impl IntoView {
    let n = nav();
    let busy = RwSignal::new(false);
    let slug = film.slug.clone();
    let resumed = Signal::derive({
        let slug = slug.clone();
        move || { n.lib.get(); store::watch(&slug).is_some() }
    });
    let label = move || match (wide, resumed.get()) {
        (false, false) => "Xem ngay",
        (false, true) => "Xem tiếp",
        (true, false) => "Phát",
        (true, true) => "Tiếp tục",
    };
    view! {
        <div class=if wide { "play-wide press" } else { "play-capsule press" }
            on:click=move |e| { e.stop_propagation(); if !busy.get_untracked() { n.play_slug(slug.clone(), busy) } }>
            {move || if busy.get() { view! { <span class="mini-spin"></span> }.into_any() } else { view! { <Icon d=ic::PLAY fill=true /> }.into_any() }}
            <span>{label}</span>
        </div>
    }
}

/// Opens the full-screen genre/country picker. Outside filter mode, picking opens that list.
pub fn open_picker(n: Nav, countries: bool, filter: Option<RwSignal<Option<Category>>>) {
    let on_pick = Callback::new(move |c: Option<Category>| match filter {
        Some(f) => f.set(c),
        None => if let Some(c) = c {
            let slug = c.slug.unwrap_or_default();
            let name = c.name.unwrap_or_else(|| slug.clone());
            n.list(name, if countries { Source::Country(slug) } else { Source::Genre(slug) });
        },
    });
    let selected = filter.and_then(|f| f.get_untracked()).and_then(|c| c.slug);
    n.picker.set(Some(Picker { countries, selected, filter: filter.is_some(), on_pick }));
}

/// GenrePickerPill: "Thể loại ⌄" / "Quốc gia ⌄"; in filter mode shows the pick, filled white.
#[component]
pub fn GenrePickerPill(countries: bool, #[prop(default = None)] filter: Option<RwSignal<Option<Category>>>) -> impl IntoView {
    let n = nav();
    let label = move || {
        filter.and_then(|f| f.get()).and_then(|c| c.name).unwrap_or_else(|| if countries { "Quốc gia" } else { "Thể loại" }.into())
    };
    let sel = move || filter.is_some_and(|f| f.with(|c| c.is_some()));
    view! {
        <div class="pill glass press" class:on=sel on:click=move |_| open_picker(n, countries, filter)>
            {label}<Icon d=ic::CHEV_D />
        </div>
    }
}

#[component]
pub fn PickerOverlay(p: Picker) -> impl IntoView {
    let n = nav();
    let items = RwSignal::new(Vec::<Category>::new());
    let kind = if p.countries { "quoc-gia" } else { "the-loai" };
    spawn_local(async move { items.set(api::taxonomy(kind).await) });
    let Picker { selected, filter, on_pick, .. } = p;
    view! {
        <div class="picker">
            {move || {
                let mut all: Vec<Option<Category>> = if filter { vec![None] } else { vec![] };
                all.extend(items.get().into_iter().map(Some));
                all.into_iter().enumerate().map(|(i, c)| {
                    let on = c.as_ref().and_then(|c| c.slug.clone()) == selected && (filter || c.is_some());
                    let name = c.as_ref().and_then(|c| c.name.clone()).unwrap_or_else(|| "Tất cả".into());
                    view! {
                        <div class="opt" class:on=on style=format!("animation-delay:{}ms", i.min(14) * 25)
                            on:click=move |_| { n.picker.set(None); on_pick.run(c.clone()); }>{name}</div>
                    }
                }).collect_view()
            }}
        </div>
        <div class="picker-close" aria-label="Đóng" on:click=move |_| n.picker.set(None)><Icon d=ic::CLOSE /></div>
    }
}

const COUNTRIES: [(&str, &str, &str); 9] = [
    ("🇰🇷", "Hàn Quốc", "han-quoc"), ("🇨🇳", "Trung Quốc", "trung-quoc"), ("🇺🇸", "Âu Mỹ", "au-my"),
    ("🇯🇵", "Nhật Bản", "nhat-ban"), ("🇹🇭", "Thái Lan", "thai-lan"), ("🇻🇳", "Việt Nam", "viet-nam"),
    ("🇹🇼", "Đài Loan", "dai-loan"), ("🇭🇰", "Hồng Kông", "hong-kong"), ("🇮🇳", "Ấn Độ", "an-do"),
];

#[component]
pub fn CountryShelf() -> impl IntoView {
    let n = nav();
    view! {
        <Shelf title="Phim theo quốc gia">
            {COUNTRIES.iter().map(|(flag, name, slug)| view! {
                <div class="country-tile press" on:click=move |_| n.list(*name, Source::Country(slug.to_string()))>
                    <span class="fl">{*flag}</span><b>{*name}</b>
                </div>
            }).collect_view()}
            <div class="country-tile press" on:click=move |_| open_picker(n, true, None)><span class="fl">"🌏"</span><b>"Tất cả"</b></div>
        </Shelf>
    }
}

/// Three posters fanned out: x [−.55, 0, .55]·w, rotation [−14°, 0, 14°], y [10, −2, 10]; the middle one on top.
pub fn fan(films: &[Film], w: f64) -> impl IntoView {
    const CFG: [(f64, f64, f64); 3] = [(-0.55, -14.0, 10.0), (0.0, 0.0, -2.0), (0.55, 14.0, 10.0)];
    [0usize, 2, 1].into_iter().filter_map(|k| {
        let f = films.get(k)?;
        let (dx, r, dy) = CFG[k];
        let style = format!("width:{w}px;height:{}px;left:calc(50% - {}px);transform:translate({}px,{dy}px) rotate({r}deg)", w * 1.48, w / 2.0, dx * w);
        Some(view! { <Img src=f.poster() style=style /> })
    }).collect_view()
}

/// Opens a dropdown menu under (or right-aligned to) the tapped element.
pub fn open_menu(n: Nav, e: &web_sys::MouseEvent, right: bool, items: Vec<MenuItem>) {
    let Some(el) = e.current_target().and_then(|t| t.dyn_into::<web_sys::Element>().ok()) else { return };
    let r = el.get_bounding_client_rect();
    let (w, _) = crate::glue::win();
    n.menu.set(Some(Menu { x: if right { w - r.right() } else { r.left() }, y: r.bottom() + 6.0, right, items }));
}

#[component]
pub fn MenuView(m: Menu) -> impl IntoView {
    let n = nav();
    let pos = if m.right { format!("right:{}px;top:{}px", m.x, m.y) } else { format!("left:{}px;top:{}px", m.x, m.y) };
    view! {
        <div class="menu-veil" on:click=move |_| n.menu.set(None)></div>
        <div class="menu" style=pos>
            {m.items.into_iter().map(|it| if it.sep { view! { <hr /> }.into_any() } else {
                let (act, keep) = (it.act, it.keep);
                view! {
                    <div class="it" class:red=it.red on:click=move |_| { if !keep { n.menu.set(None) } if let Some(a) = act { a.run(()) } }>
                        <span>{it.label}</span>{it.on.then(|| view! { <Icon d=ic::CHECK /> })}
                    </div>
                }.into_any()
            }).collect_view()}
        </div>
    }
}

/// ui/Pager.kt: endless pages; each load fetches up to 4 pages, stopping once 8 new films came in.
#[derive(Clone, Copy)]
pub struct Pager {
    pub items: RwSignal<Vec<Film>>,
    page: RwSignal<i64>,
    pub loading: RwSignal<bool>,
    pub failed: RwSignal<bool>,
    pub done: RwSignal<bool>,
    epoch: RwSignal<u32>,
}

impl Pager {
    pub fn new() -> Self {
        Pager { items: RwSignal::new(vec![]), page: RwSignal::new(0), loading: RwSignal::new(false), failed: RwSignal::new(false), done: RwSignal::new(false), epoch: RwSignal::new(0) }
    }
    pub fn reset(&self) {
        self.epoch.update(|e| *e += 1);
        self.items.set(vec![]);
        self.page.set(0);
        self.loading.set(false);
        self.failed.set(false);
        self.done.set(false);
    }
    pub fn more(self, source: Source, filter: Filter) {
        if self.loading.get_untracked() || self.done.get_untracked() { return; }
        self.loading.set(true);
        self.failed.set(false);
        let epoch = self.epoch.get_untracked();
        spawn_local(async move {
            let mut added = 0;
            for _ in 0..4 {
                let p = self.page.get_untracked() + 1;
                let res = api::list(&source, p, &filter).await;
                if self.epoch.get_untracked() != epoch { return; }
                match res {
                    Ok(pg) => {
                        self.page.set(p);
                        let have: std::collections::HashSet<String> = self.items.with_untracked(|v| v.iter().map(|f| f.slug.clone()).collect());
                        let new: Vec<Film> = pg.items.into_iter().filter(|f| !have.contains(&f.slug)).collect();
                        added += new.len();
                        self.items.update(|v| v.extend(new));
                        if p >= pg.total_pages { self.done.set(true); break; }
                    }
                    Err(_) => { self.failed.set(true); break; }
                }
                if added >= 8 { break; }
            }
            self.loading.set(false);
        });
    }
    /// The grid footer: a spinner while loading, "Thử lại" after a failure.
    pub fn footer(self, retry: impl Fn() + Copy + Send + Sync + 'static) -> impl IntoView {
        view! {
            <div class="foot">
                {move || if self.failed.get() {
                    Some(view! { <div class="obtn" on:click=move |_| retry()>"Thử lại"</div> }.into_any())
                } else if self.loading.get() { Some(spinner(32).into_any()) } else { None }}
            </div>
        }
    }
}

/// Calls `more` when a scroll container nears its end.
pub fn near_end(e: &web_sys::Event) -> bool {
    e.target().and_then(|t| t.dyn_into::<web_sys::Element>().ok())
        .is_some_and(|el| (el.scroll_top() + el.client_height()) as f64 > el.scroll_height() as f64 - 900.0)
}

pub fn scroll_top(e: &web_sys::Event) -> f64 {
    e.target().and_then(|t| t.dyn_into::<web_sys::Element>().ok()).map(|el| el.scroll_top() as f64).unwrap_or(0.0)
}
