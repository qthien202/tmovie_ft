//! Film detail, as feature/detail: 16:10 art, meta, play, synopsis, credits, actions, cast, Tập phim / Tương tự / Hình ảnh.

use leptos::prelude::*;
use leptos::task::spawn_local;

use super::*;
use crate::api::{Detail, Filter, Person};
use crate::glue;

#[component]
pub fn DetailPage(film: Film) -> impl IntoView {
    let n = nav();
    let slug = StoredValue::new(film.slug.clone());
    let d = RwSignal::new(None::<Detail>);
    let failed = RwSignal::new(false);
    let people = RwSignal::new(Vec::<Person>::new());
    let backs = RwSignal::new(Vec::<String>::new());
    let similar = RwSignal::new(Vec::<Film>::new());
    let load = move || {
        failed.set(false);
        let s = slug.get_value();
        spawn_local(async move {
            match api::detail(&s).await {
                Ok(det) => {
                    if let Some(g) = det.film.category.first().and_then(|c| c.slug.clone()) {
                        let me = s.clone();
                        spawn_local(async move {
                            let p = api::list(&Source::Genre(g), 1, &Filter::default()).await.map(|p| p.items).unwrap_or_default();
                            similar.set(p.into_iter().filter(|f| f.slug != me).collect());
                        });
                    }
                    d.set(Some(det));
                }
                Err(_) => failed.set(true),
            }
        });
        spawn_local(async move { people.set(api::peoples(&slug.get_value()).await) });
        spawn_local(async move { backs.set(api::backdrops(&slug.get_value()).await) });
    };
    load();
    let scroll_y = RwSignal::new(0.0);
    let base = StoredValue::new(film.clone());
    let cur = move || d.with(|d| d.as_ref().map(|d| d.film.clone())).unwrap_or_else(|| base.get_value());
    let record = move || { n.lib.get(); store::watch(&slug.get_value()) };
    let expanded = RwSignal::new(false);
    let tab = RwSignal::new(None::<usize>);
    let has_eps = move || d.with(|d| d.as_ref().is_some_and(|d| d.episodes.iter().any(|s| s.server_data.len() > 1)));
    let tabs = move || {
        let mut t = vec![];
        if has_eps() { t.push((0, "Tập phim")); }
        t.push((1, "Tương tự"));
        if backs.with(|b| !b.is_empty()) { t.push((2, "Hình ảnh")); }
        t
    };
    let active = move || tab.get().filter(|t| tabs().iter().any(|(i, _)| i == t)).unwrap_or_else(|| tabs()[0].0);
    let play = move |_| {
        let Some(det) = d.get_untracked() else { return };
        if !n.start(det, true) { n.toast("Phim này chưa có link phát") }
    };
    let thumb0 = film.thumb();
    let art = Signal::derive(move || d.with(|d| d.as_ref().map(|d| d.film.thumb())).filter(|s| !s.is_empty()).unwrap_or_else(|| thumb0.clone()));

    view! {
        <div class="scroll" on:scroll=move |e| scroll_y.set(scroll_top(&e))>
            <div class="d-art" style:transform=move || format!("translateY({}px)", scroll_y.get() * 0.3)>
                <Img src=art /><div class="g"></div>
            </div>
            <div class="d-col">
                <div class="d-block">
                    <div class="title28">{move || cur().name}</div>
                    {move || cur().origin_name.filter(|o| !o.trim().is_empty()).map(|o| view! { <div class="orig">{o}</div> })}
                    {move || { let f = cur(); view! {
                        <div class="meta-row">
                            {f.rating().map(|r| view! { <span class="st">{format!("★ {r:.1}")}</span> })}
                            {f.year.map(|y| view! { <span class="yr">{y}</span> })}
                            {f.quality.clone().filter(|q| !q.is_empty()).map(|q| view! { <span class="q">{q}</span> })}
                            {f.episode_current.clone().map(|e| view! { <span>{e}</span> })}
                            {f.time.clone().filter(|t| !t.is_empty()).map(|t| view! { <span>{t}</span> })}
                        </div>
                    } }}
                    <div class="play-wide press" class:off=move || d.with(|d| d.is_none()) on:click=play>
                        <Icon d=ic::PLAY fill=true />
                        <span>{move || record().map(|w| format!("Tiếp tục {}", api::ep_label(&w.episode_name))).unwrap_or_else(|| "Phát".into())}</span>
                    </div>
                    {move || failed.get().then(|| view! { <div class="retry" on:click=move |_| load()>"Không tải được phim · Thử lại"</div> })}
                    {move || d.get().and_then(|d| d.content).map(|c| view! {
                        <div class="synop" class:open=move || expanded.get() on:click=move |_| expanded.update(|e| *e = !*e)>{api::plain(&c)}</div>
                    })}
                    {move || d.get().map(|det| {
                        let actors: Vec<String> = det.actor.iter().filter(|a| !a.trim().is_empty() && a.as_str() != "Đang cập nhật").take(4).cloned().collect();
                        let tmdb_dir: Vec<String> = people.get().into_iter().filter(|p| p.known_for_department.as_deref() == Some("Directing")).filter_map(|p| p.name).collect();
                        let dirs = if tmdb_dir.is_empty() { det.director.iter().filter(|a| !a.trim().is_empty() && a.as_str() != "Đang cập nhật").cloned().collect() } else { tmdb_dir };
                        view! {
                            {(!actors.is_empty()).then(|| view! { <div class="credit"><span>"Diễn viên: "</span><i>{actors.join(", ")}</i></div> })}
                            {(!dirs.is_empty()).then(|| view! { <div class="credit"><span>"Đạo diễn: "</span><i>{dirs.join(", ")}</i></div> })}
                        }
                    })}
                </div>

                <div class="d-actions">
                    {move || view! { <SaveButton film=cur() style=SaveStyle::Column /> }}
                    <div class="d-act" on:click=move |_| {
                        let f = cur();
                        let orig = f.origin_name.filter(|o| !o.is_empty()).map(|o| format!(" ({o})")).unwrap_or_default();
                        glue::share(&format!("{}{} — đang xem trên TMovie", f.name, orig));
                    }><Icon d=ic::SEND /><span>"Chia sẻ"</span></div>
                    {move || d.get().and_then(|d| d.trailer_url).filter(|t| !t.is_empty()).map(|t| view! {
                        <div class="d-act" on:click=move |_| glue::open(&t)><Icon d=ic::MOVIE /><span>"Trailer"</span></div>
                    })}
                </div>

                {move || {
                    let cast: Vec<Person> = people.get().into_iter().filter(|p| p.known_for_department.as_deref() == Some("Acting")).collect();
                    (!cast.is_empty()).then(|| view! {
                        <HScroll class="cast">
                            {cast.into_iter().map(|p| view! {
                                <div class="p">
                                    <Img src=p.profile_path.as_deref().map(|x| api::tmdb(x, "w185")).unwrap_or_default() class="ph" />
                                    <b>{p.name.unwrap_or_default()}</b><span>{p.character.unwrap_or_default()}</span>
                                </div>
                            }).collect_view()}
                        </HScroll>
                    })
                }}

                <div class="d-tabs">
                    {move || tabs().into_iter().map(|(i, label)| view! {
                        <div class="d-tab" class:on=move || active() == i on:click=move |_| tab.set(Some(i))><i></i>{label}</div>
                    }).collect_view()}
                </div>

                {move || match active() {
                    0 => d.get().map(|det| view! { <Episodes d=det stills=backs.get() /> }.into_any()),
                    1 => Some(view! {
                        <div class="grid3">{similar.get().into_iter().map(|f| view! { <PosterCard film=f cell=true /> }).collect_view()}</div>
                    }.into_any()),
                    _ => Some(view! {
                        <div class="backs">{backs.get().into_iter().map(|p| view! { <Img src=api::tmdb(&p, "w780") /> }).collect_view()}</div>
                    }.into_any()),
                }}
            </div>
            <div style="height:calc(120px + var(--bottom))"></div>
        </div>
        <div class="fback glass press" aria-label="Quay lại" on:click=move |_| n.back()><Icon d=ic::BACK /></div>
    }
}

/// EpisodeList: server + 50-episode range dropdowns, rows with stills and progress, "Đang xem".
#[component]
fn Episodes(d: Detail, stills: Vec<String>) -> impl IntoView {
    let n = nav();
    let rec = store::watch(&d.film.slug);
    let server = RwSignal::new(rec.as_ref().map(|w| w.server).filter(|s| *s < d.episodes.len()).unwrap_or(0));
    let range = RwSignal::new(rec.as_ref().filter(|w| w.server == server.get_untracked()).map(|w| w.episode / 50).unwrap_or(0));
    let det = StoredValue::new(d);
    let eps = move || det.with_value(|d| d.episodes.get(server.get()).map(|s| s.server_data.clone()).unwrap_or_default());
    let thumb = det.with_value(|d| d.film.thumb());
    let server_menu = move |e: web_sys::MouseEvent| {
        let items = det.with_value(|d| d.episodes.iter().enumerate().map(|(i, s)| {
            MenuItem::new(s.server_name.clone().unwrap_or_else(|| format!("Server {}", i + 1)), server.get_untracked() == i, move || { server.set(i); range.set(0); })
        }).collect());
        open_menu(n, &e, false, items);
    };
    let range_menu = move |e: web_sys::MouseEvent| {
        let total = eps().len();
        let items = (0..total.div_ceil(50)).map(|r| {
            MenuItem::new(format!("Tập {}–{}", r * 50 + 1, ((r + 1) * 50).min(total)), range.get_untracked() == r, move || range.set(r))
        }).collect();
        open_menu(n, &e, false, items);
    };
    view! {
        <div class="ep-list">
            <div class="ep-ctrls">
                {move || (det.with_value(|d| d.episodes.len()) > 1).then(|| view! {
                    <div class="dd glass" on:click=server_menu>
                        {move || det.with_value(|d| d.episodes.get(server.get()).and_then(|s| s.server_name.clone())).unwrap_or_else(|| format!("Server {}", server.get() + 1))}
                        <Icon d=ic::CHEV_D />
                    </div>
                })}
                {move || { let t = eps().len(); (t > 50).then(|| view! {
                    <div class="dd glass" on:click=range_menu>
                        {move || { let r = range.get(); format!("Tập {}–{}", r * 50 + 1, ((r + 1) * 50).min(t)) }}
                        <Icon d=ic::CHEV_D />
                    </div>
                }) }}
            </div>
            {move || {
                n.lib.get();
                let rec = store::watch(&det.with_value(|d| d.film.slug.clone()));
                let s = server.get();
                let r = range.get();
                eps().into_iter().enumerate().skip(r * 50).take(50).map(|(i, ep)| {
                    let still = if stills.is_empty() { thumb.clone() } else { api::tmdb(&stills[i % stills.len()], "w300") };
                    let slug = ep.slug.clone().unwrap_or_default();
                    let progress = rec.as_ref().map(|w| w.progress(&slug)).unwrap_or(0.0);
                    let now = rec.as_ref().is_some_and(|w| w.server == s && w.episode == i);
                    let name = ep.name.clone().filter(|x| !x.is_empty()).unwrap_or_else(|| format!("Tập {}", i + 1));
                    let off = ep.stream().is_none();
                    view! {
                        <div class="ep-row" class:off=off on:click=move |_| {
                            let detail = det.get_value();
                            n.play.set(Some(Play { detail, server: s, index: i, from_detail: true }));
                        }>
                            <div class="still">
                                <Img src=still />
                                <div class="c glass"><Icon d=ic::PLAY fill=true /></div>
                                {(progress > 0.0).then(|| view! { <div class="strip"><i style=format!("width:{}%", progress * 100.0)></i></div> })}
                            </div>
                            <div><b>{name}</b>{now.then(|| view! { <span class="now">"Đang xem"</span> })}</div>
                        </div>
                    }
                }).collect_view()
            }}
        </div>
    }
}
