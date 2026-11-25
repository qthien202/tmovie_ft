//! Khám phá, as browse/ExploreScreen: stories, moods, the shuffle card, Mới & Hot, collections.

use leptos::prelude::*;
use leptos::task::spawn_local;

use super::*;
use crate::api::Filter;

const MOODS: [(&str, &str, &str, &str, &str, &str); 8] = [
    ("😱", "Hồi hộp", "g", "kinh-di", "#3A1C71", "#D76D77"),
    ("💕", "Lãng mạn", "g", "tinh-cam", "#FF8FB1", "#9D5CFF"),
    ("😂", "Cười xả láng", "g", "hai-huoc", "#F7971E", "#FFD200"),
    ("🍿", "Cày một đêm", "t", "phim-le", "#1D976C", "#93F9B9"),
    ("📺", "Cày dài kỳ", "t", "phim-bo", "#2B5876", "#4E4376"),
    ("👨‍👩‍👧", "Cả nhà cùng xem", "t", "hoat-hinh", "#3D8BFF", "#5BE0FF"),
    ("🤯", "Mind-blowing", "g", "vien-tuong", "#0F2027", "#2C7A8C"),
    ("⚔️", "Cổ trang", "g", "co-trang", "#C79A3A", "#8A3A1F"),
];

const COLLECTIONS: [(&str, &str, &str, &str, &str, &str); 4] = [
    ("Hàn Quốc đang gây sốt", "Những bộ ai cũng bàn tuần này", "c", "han-quoc", "#FF5F6D", "#7B2FF7"),
    ("Cày một lèo", "Phim bộ đã trọn, khỏi chờ tập", "t", "phim-bo", "#1D976C", "#2B5876"),
    ("Kinh dị nửa đêm", "Tắt đèn rồi hãy bấm", "g", "kinh-di", "#200122", "#6F0000"),
    ("Hoạt hình cả nhà", "Cuối tuần cho bé và bố mẹ", "t", "hoat-hinh", "#3D8BFF", "#5B8CFF"),
];

fn source(kind: &str, slug: &str) -> Source {
    match kind {
        "g" => Source::Genre(slug.into()),
        "c" => Source::Country(slug.into()),
        _ => Source::Type(slug.into()),
    }
}

async fn page1(s: Source) -> Vec<Film> { api::list(&s, 1, &Filter::default()).await.map(|p| p.items).unwrap_or_default() }

fn short_name(name: &str) -> String { name.split([':', '/', '(']).next().unwrap_or(name).trim().to_string() }

#[component]
pub fn Explore() -> impl IntoView {
    let n = nav();
    let hot = RwSignal::new(Vec::<Film>::new());
    let moods: [RwSignal<Vec<Film>>; 8] = std::array::from_fn(|_| RwSignal::new(vec![]));
    let cols: [RwSignal<Vec<Film>>; 4] = std::array::from_fn(|_| RwSignal::new(vec![]));
    let mood = RwSignal::new(0usize);
    let seg = RwSignal::new(0usize);
    let feeds: [RwSignal<Option<Vec<Film>>>; 3] = std::array::from_fn(|_| RwSignal::new(None));
    spawn_local(async move {
        if let Some(h) = api::hot().await {
            let mut seen = std::collections::HashSet::new();
            hot.set(h.films.into_iter().chain(h.series).filter(|f| seen.insert(f.slug.clone())).collect());
        }
    });
    for (i, m) in MOODS.iter().enumerate() { let s = source(m.2, m.3); spawn_local(async move { moods[i].set(page1(s).await) }); }
    for (i, c) in COLLECTIONS.iter().enumerate() { let s = source(c.2, c.3); spawn_local(async move { cols[i].set(page1(s).await) }); }
    spawn_local(async move { feeds[0].set(Some(page1(Source::Type("phim-sap-chieu".into())).await)) });
    spawn_local(async move {
        let bo = page1(Source::Type("phim-bo".into())).await;
        let cur = |f: &Film| f.episode_current.clone().unwrap_or_default();
        feeds[1].set(Some(bo.iter().filter(|f| cur(f).starts_with("Tập")).cloned().collect()));
        feeds[2].set(Some(bo.into_iter().filter(|f| cur(f).to_lowercase().contains("hoàn tất")).collect()));
    });

    view! {
        <div class="scroll"><div class="list28">
            <div class="pg-head">
                <div class="title28">"Khám phá"</div>
                <div class="stories">
                    {move || hot.get().into_iter().take(12).enumerate().map(|(i, f)| {
                        let label = format!("{}{}", if i < 3 { "🔥 " } else { "" }, short_name(&f.name));
                        let src = f.poster();
                        view! {
                            <div class="story press" on:click=move |_| n.open(f.clone())>
                                <div class="ring"><div><Img src=src /></div></div>
                                <span>{label}</span>
                            </div>
                        }
                    }).collect_view()}
                </div>
            </div>

            <div class="shelf" style="gap:12px">
                <div class="section-title" style="padding:0 16px">"Hôm nay bạn muốn xem gì?"</div>
                <div class="moods">
                    {MOODS.iter().enumerate().map(|(i, (emoji, title, _, _, a, b))| view! {
                        <div class="mood" class:on=move || mood.get() == i style=format!("background:linear-gradient(135deg,{a},{b})")
                            on:click=move |_| mood.set(i)>
                            <div class="fanb">{move || fan(&moods[i].get(), 62.0)}</div>
                            <div class="lab glass"><span class="e">{*emoji}</span><b>{*title}</b></div>
                        </div>
                    }).collect_view()}
                </div>
                {move || {
                    let i = mood.get();
                    let (emoji, title, k, slug, ..) = MOODS[i];
                    let films = moods[i].get();
                    poster_shelf(format!("{emoji} {title}"), Some((title.into(), source(k, slug))), (!films.is_empty()).then_some(films))
                }}
            </div>

            <Shuffle hot=hot />

            <div class="shelf" style="gap:14px">
                <div class="section-title" style="padding:0 16px">"Mới & Hot"</div>
                <div class="segbar glass">
                    {["🍿 Sắp chiếu", "🔥 Đang chiếu", "✅ Trọn bộ"].into_iter().enumerate().map(|(i, l)| view! {
                        <span class:on=move || seg.get() == i on:click=move |_| seg.set(i)>{l}</span>
                    }).collect_view()}
                </div>
                {move || match feeds[seg.get()].get() {
                    None => view! { <div class="center-spin">{spinner(36)}</div> }.into_any(),
                    Some(v) => v.into_iter().take(5).map(|f| view! { <FeedCard film=f /> }).collect_view().into_any(),
                }}
            </div>

            <div class="shelf" style="gap:12px">
                <div class="section-title" style="padding:0 16px">"Bộ sưu tập"</div>
                <div class="cols2">
                    {COLLECTIONS.iter().enumerate().map(|(i, (title, sub, k, slug, a, b))| view! {
                        <div class="colc press" style=format!("background:linear-gradient(135deg,{a},{b})") on:click=move |_| n.list(*title, source(k, slug))>
                            <div class="fanb" style="top:12px">{move || fan(&cols[i].get().into_iter().skip(1).take(3).collect::<Vec<_>>(), 60.0)}</div>
                            <div class="g"></div>
                            <div class="tx"><b>{*title}</b><span>{*sub}</span></div>
                        </div>
                    }).collect_view()}
                </div>
            </div>
        </div></div>
    }
}

/// FeedCard: 16:9 thumb, name, "★ 8.4 · 2026 · FHD · Phụ đề · Tập 12", genres, save.
#[component]
fn FeedCard(film: Film) -> impl IntoView {
    let n = nav();
    let f = film.clone();
    view! {
        <div class="feed">
            <div class="press" on:click=move |_| n.open(f.clone())><Img src=film.thumb() class="th" /></div>
            <div class="row2">
                <div><b>{film.name.clone()}</b><span class="m">{film.meta_line()}</span><span class="g2">{film.genre_line()}</span></div>
                <SaveButton film=film style=SaveStyle::Column />
            </div>
        </div>
    }
}

/// "Không biết xem gì?": 16 random steps slowing down (60 + step²·2 ms), then a pick from the hot list.
#[component]
fn Shuffle(hot: RwSignal<Vec<Film>>) -> impl IntoView {
    let pick = RwSignal::new(None::<Film>);
    let shown = RwSignal::new(None::<Film>);
    let spinning = RwSignal::new(false);
    let rnd = |n: usize| (js_sys::Math::random() * n as f64) as usize;
    let spin = move || {
        let all = hot.get_untracked();
        if all.is_empty() || spinning.get_untracked() { return; }
        spinning.set(true);
        spawn_local(async move {
            for step in 0..16u32 {
                shown.set(Some(all[rnd(all.len())].clone()));
                gloo_timers::future::TimeoutFuture::new(60 + step * step * 2).await;
            }
            let f = all[rnd(all.len())].clone();
            shown.set(Some(f.clone()));
            pick.set(Some(f));
            spinning.set(false);
        });
    };
    let face = move || shown.get().or_else(|| hot.with(|h| h.first().cloned()));
    view! {
        <div class="shuffle glass">
            <div class="reel" class:spin=move || spinning.get()>
                {move || face().map(|f| view! { <Img src=f.poster() /> })}
            </div>
            <div class="col">
                <span class="lbl">{move || if pick.with(|p| p.is_some()) { "TMOVIE CHỌN CHO BẠN" } else { "KHÔNG BIẾT XEM GÌ?" }}</span>
                <span class="tt">{move || pick.get().map(|f| f.name).unwrap_or_else(|| "Để TMovie chọn giúp".into())}</span>
                <span class="sub">{move || pick.get().map(|f| {
                    [f.year.map(|y| y.to_string()), f.country.first().and_then(|c| c.name.clone()), f.episode_current.clone()]
                        .into_iter().flatten().collect::<Vec<_>>().join(" · ")
                }).unwrap_or_else(|| "Lắc một cái, ra một phim đang hot.".into())}</span>
                {move || pick.get().filter(|_| !spinning.get()).map(|f| view! { <PlayFilmButton film=f /> })}
                <div class="spinb" class:w=move || pick.with(|p| p.is_none()) class:g=move || pick.with(|p| p.is_some()) on:click=move |_| spin()>
                    {move || if pick.with(|p| p.is_some()) { "🎲 Chọn lại" } else { "🎲 Chọn giúp tôi" }}
                </div>
            </div>
        </div>
    }
}
