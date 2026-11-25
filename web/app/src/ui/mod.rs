//! App shell, as the Android app's MainActivity + AppNavHost: gate → splash → onboarding → 4 tabs, a page stack, the player.

mod catalog;
mod detail;
mod explore;
mod home;
mod parts;
mod player;
mod profile;
mod search;

use std::time::Duration;

use leptos::prelude::*;
use leptos::task::spawn_local;

use crate::api::{self, Category, Detail, Film, Source};
use crate::gate::{self, Gate};
use crate::{glue, store};
pub use parts::*;

#[derive(Clone)]
pub enum Route {
    Film(Film),
    List(String, Source),
}

#[derive(Clone)]
pub struct Play {
    pub detail: Detail,
    pub server: usize,
    pub index: usize,
    pub from_detail: bool,
}

#[derive(Clone)]
pub struct Picker {
    pub countries: bool,
    pub selected: Option<String>,
    pub filter: bool,
    pub on_pick: Callback<Option<Category>>,
}

#[derive(Clone)]
pub struct MenuItem {
    pub label: String,
    pub on: bool,
    pub red: bool,
    pub sep: bool,
    /// Opens a submenu in place, so the menu stays until it is replaced.
    pub keep: bool,
    pub act: Option<Callback<()>>,
}

impl MenuItem {
    pub fn new(label: impl Into<String>, on: bool, act: impl Fn() + Send + Sync + 'static) -> Self {
        MenuItem { label: label.into(), on, red: false, sep: false, keep: false, act: Some(Callback::new(move |_| act())) }
    }
    pub fn sub(label: impl Into<String>, act: impl Fn() + Send + Sync + 'static) -> Self { MenuItem { keep: true, ..Self::new(label, false, act) } }
    pub fn sep() -> Self { MenuItem { label: String::new(), on: false, red: false, sep: true, keep: false, act: None } }
}

#[derive(Clone)]
pub struct Menu {
    pub x: f64,
    pub y: f64,
    pub right: bool,
    pub items: Vec<MenuItem>,
}

#[derive(Clone, Copy)]
pub struct Nav {
    pub tab: RwSignal<usize>,
    pub stack: RwSignal<Vec<(u32, Route)>>,
    pub play: RwSignal<Option<Play>>,
    pub toast_msg: RwSignal<Option<(u32, String)>>,
    pub picker: RwSignal<Option<Picker>>,
    pub menu: RwSignal<Option<Menu>>,
    /// Bumped whenever history or "Danh sách của tôi" changes.
    pub lib: RwSignal<u32>,
    ids: StoredValue<u32>,
}

pub fn nav() -> Nav { expect_context::<Nav>() }

impl Nav {
    fn push(&self, r: Route) {
        let id = self.ids.get_value() + 1;
        self.ids.set_value(id);
        self.menu.set(None);
        self.stack.update(|s| s.push((id, r)));
    }
    pub fn open(&self, f: Film) { self.push(Route::Film(f)) }
    pub fn list(&self, title: impl Into<String>, source: Source) { self.push(Route::List(title.into(), source)) }
    pub fn back(&self) { self.stack.update(|s| { s.pop(); }) }
    pub fn bump(&self) { self.lib.update(|v| *v += 1) }
    pub fn toast(&self, msg: impl Into<String>) {
        let id = self.ids.get_value() + 1;
        self.ids.set_value(id);
        self.toast_msg.set(Some((id, msg.into())));
        let t = self.toast_msg;
        set_timeout(move || if t.get_untracked().is_some_and(|(i, _)| i == id) { t.set(None) }, Duration::from_millis(2500));
    }
    /// Player.start: the last-watched episode, else the first playable one. False when nothing plays.
    pub fn start(&self, d: Detail, from_detail: bool) -> bool {
        let resume = store::watch(&d.film.slug)
            .filter(|w| d.episodes.get(w.server).and_then(|s| s.server_data.get(w.episode)).is_some_and(|e| e.stream().is_some()))
            .map(|w| (w.server, w.episode));
        let first = || d.episodes.iter().enumerate().find_map(|(s, sv)| sv.server_data.iter().position(|e| e.stream().is_some()).map(|i| (s, i)));
        match resume.or_else(first) {
            Some((server, index)) => {
                self.play.set(Some(Play { detail: d, server, index, from_detail }));
                true
            }
            None => false,
        }
    }
    /// PlayFilmButton / ContinueCard: fetch the detail, then start.
    pub fn play_slug(&self, slug: String, busy: RwSignal<bool>) {
        let n = *self;
        busy.set(true);
        spawn_local(async move {
            let ok = match api::detail(&slug).await { Ok(d) => n.start(d, false), Err(_) => false };
            if !ok { n.toast("Phim này chưa có link phát"); }
            busy.set(false);
        });
    }
}

#[component]
pub fn App() -> impl IntoView {
    let unlocked = RwSignal::new(gate::access().unlocked);
    spawn_local(gate::recheck(unlocked));
    view! {
        <div id="app">
            <Show when=move || unlocked.get() fallback=move || view! { <Gate unlocked=unlocked /> }>
                <Main />
            </Show>
        </div>
    }
}

/// splash → onboarding (until `onboarded`) → shell.
#[component]
fn Main() -> impl IntoView {
    let splash = RwSignal::new(true);
    let onboarded = RwSignal::new(store::flag("onboarded", false));
    set_timeout(move || splash.set(false), Duration::from_millis(if glue::reduce_motion() { 600 } else { 1400 }));
    view! {
        <Shell />
        <Show when=move || !onboarded.get()><Onboarding done=onboarded /></Show>
        <Show when=move || splash.get()><Splash /></Show>
    }
}

#[component]
fn Splash() -> impl IntoView {
    view! {
        <div class="splash"><div class="letters">
            {"TMOVIE".chars().enumerate().map(|(i, c)| view! { <span style=format!("animation-delay:{}ms", i * 70)>{c.to_string()}</span> }).collect_view()}
        </div></div>
    }
}

const ONBOARD: [(&str, &str, &str); 3] = [
    ("Cả thế giới điện ảnh\ntrong túi bạn", "Phim bộ, phim lẻ, TV Shows cập nhật mỗi ngày.", ic::SPARKLE),
    ("Sắc nét đến\ntừng khung hình", "Phát Full HD, Hình trong hình và chọn tập ngay trong player.", ic::PIP),
    ("Tiếp tục xem\nđúng chỗ bạn dừng", "Lịch sử và danh sách của bạn luôn sẵn sàng.", ic::HISTORY),
];

#[component]
fn Onboarding(done: RwSignal<bool>) -> impl IntoView {
    let posters = RwSignal::new(Vec::<Film>::new());
    spawn_local(async move {
        let mut all = vec![];
        for p in 1..=2 {
            if let Ok(pg) = api::list(&Source::Type("phim-moi-cap-nhat".into()), p, &Default::default()).await { all.extend(pg.items); }
        }
        posters.set(all);
    });
    let page = RwSignal::new(0usize);
    let pages = NodeRef::<leptos::html::Div>::new();
    let finish = move || { store::set_flag("onboarded", true); done.set(true); };
    let next = move || {
        let p = page.get_untracked();
        if p >= 2 { return finish(); }
        if let Some(el) = pages.get_untracked() {
            let o = web_sys::ScrollToOptions::new();
            o.set_left((p + 1) as f64 * el.client_width() as f64);
            o.set_behavior(web_sys::ScrollBehavior::Smooth);
            el.scroll_to_with_scroll_to_options(&o);
        }
    };
    view! {
        <div class="onb">
            <div class="wall">
                {move || {
                    let all = posters.get();
                    (0..4).map(|c| {
                        let col: Vec<Film> = all.iter().skip(c).step_by(4).cloned().collect();
                        view! { <div class="colm">{col.into_iter().map(|f| view! { <Img src=f.poster() /> }).collect_view()}</div> }
                    }).collect_view()
                }}
            </div>
            <div class="shade"></div>
            <div class="bottom">
                <div class="pages" node_ref=pages on:scroll=move |_| if let Some(el) = pages.get_untracked() {
                    let w = el.client_width().max(1) as f64;
                    page.set((el.scroll_left() as f64 / w).round() as usize);
                }>
                    {ONBOARD.iter().map(|(t, b, i)| view! {
                        <div class="pg"><svg viewBox="0 0 24 24"><path d=*i /></svg><h2>{*t}</h2><p>{*b}</p></div>
                    }).collect_view()}
                </div>
                <div class="dots">{(0..3).map(|i| view! { <i class:on=move || page.get() == i></i> }).collect_view()}</div>
                <div class="go press" on:click=move |_| next()>{move || if page.get() >= 2 { "Bắt đầu xem" } else { "Tiếp tục" }}</div>
                <div class="skip" on:click=move |_| finish()>"Bỏ qua"</div>
            </div>
        </div>
    }
}

const TABS: [(&str, [&str; 2]); 4] = [
    ("Trang chủ", ["M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8", "M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"]),
    ("Khám phá", ["M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0", "M16.2 7.8l-2 6.4-6.4 2 2-6.4z"]),
    ("Tìm kiếm", ["M3 11a8 8 0 1 0 16 0a8 8 0 1 0-16 0", "M21 21l-4.3-4.3"]),
    ("Của tôi", ["M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2", "M8 7a4 4 0 1 0 8 0a4 4 0 1 0-8 0"]),
];

#[component]
fn Shell() -> impl IntoView {
    let n = Nav {
        tab: RwSignal::new(0),
        stack: RwSignal::new(vec![]),
        play: RwSignal::new(None),
        toast_msg: RwSignal::new(None),
        picker: RwSignal::new(None),
        menu: RwSignal::new(None),
        lib: RwSignal::new(0),
        ids: StoredValue::new(0),
    };
    provide_context(n);
    // Tabs keep their state once opened (saveState/restoreState).
    let visited = RwSignal::new([true, false, false, false]);
    let go = move |i: usize| {
        visited.update(|v| v[i] = true);
        n.stack.set(vec![]);
        n.tab.set(i);
    };
    let tab_view = move |i: usize, body: fn() -> AnyView| view! {
        <div class="tabview" class:on=move || n.tab.get() == i>
            <Show when=move || visited.get()[i]>{body()}</Show>
        </div>
    };
    view! {
        {tab_view(0, || view! { <home::Home /> }.into_any())}
        {tab_view(1, || view! { <explore::Explore /> }.into_any())}
        {tab_view(2, || view! { <search::Search /> }.into_any())}
        {tab_view(3, || view! { <profile::Profile /> }.into_any())}
        <For each=move || n.stack.get() key=|(id, _)| *id let:item>
            <Page route=item.1 />
        </For>
        // Desktop: a menu across the top instead of the floating tab bar (CSS shows one or the other).
        <nav class="topnav">
            <div class="wordmark" on:click=move |_| go(0)>"TMOVIE"</div>
            {TABS.iter().enumerate().map(|(i, (label, _))| view! {
                <span class="tn" class:on=move || n.tab.get() == i && n.stack.with(|s| s.is_empty()) on:click=move |_| go(i)>{*label}</span>
            }).collect_view()}
        </nav>
        <div class="bar glass" class:hide=move || n.stack.with(|s| !s.is_empty())>
            <div class="hl" style:transform=move || format!("translateX({}px)", n.tab.get() * 66)></div>
            {TABS.iter().enumerate().map(|(i, (label, paths))| view! {
                <div class="tab" role="tab" aria-label=*label aria-selected=move || (n.tab.get() == i).to_string()
                    class:on=move || n.tab.get() == i on:click=move |_| go(i)>
                    <svg viewBox="0 0 24 24"><path d=paths[0] /><path d=paths[1] /></svg>
                </div>
            }).collect_view()}
        </div>
        {move || n.picker.get().map(|p| view! { <PickerOverlay p=p /> })}
        {move || n.menu.get().map(|m| view! { <MenuView m=m /> })}
        {move || n.play.get().map(|p| view! { <player::Player p=p /> })}
        <div class="toast" class:on=move || n.toast_msg.with(|t| t.is_some())>
            {move || n.toast_msg.get().map(|(_, m)| m)}
        </div>
    }
}

/// A pushed page (detail or list). Swipe in from the left edge to go back, as on iOS.
#[component]
fn Page(route: Route) -> impl IntoView {
    let n = nav();
    let start = StoredValue::new(None::<(i32, i32)>);
    let body = match route {
        Route::Film(f) => view! { <detail::DetailPage film=f /> }.into_any(),
        Route::List(t, s) => view! { <catalog::Catalog title=t source=s /> }.into_any(),
    };
    view! {
        <div class="page"
            on:pointerdown=move |e| start.set_value((e.client_x() < 24).then(|| (e.client_x(), e.client_y())))
            on:pointerup=move |e| if let Some((x, y)) = start.get_value() {
                start.set_value(None);
                if e.client_x() - x > 70 && (e.client_y() - y).abs() < 60 { n.back(); }
            }>
            {body}
        </div>
    }
}
