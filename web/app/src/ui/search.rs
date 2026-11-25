//! Tìm kiếm, as browse/SearchScreen: 400 ms debounce from 2 characters, genre chips and "Tìm kiếm hàng đầu" while idle.

use std::time::Duration;

use leptos::leptos_dom::helpers::{set_timeout_with_handle, TimeoutHandle};
use leptos::prelude::*;
use leptos::task::spawn_local;

use super::*;
use crate::api::Filter;

#[component]
pub fn Search() -> impl IntoView {
    let n = nav();
    let q = RwSignal::new(String::new());
    let term = RwSignal::new(String::new());
    let pager = Pager::new();
    let genres = RwSignal::new(Vec::<Category>::new());
    let top = RwSignal::new(Vec::<Film>::new());
    spawn_local(async move { genres.set(api::taxonomy("the-loai").await) });
    spawn_local(async move {
        top.set(api::list(&Source::Type("phim-moi-cap-nhat".into()), 1, &Filter::default()).await.map(|p| p.items).unwrap_or_default())
    });
    Effect::new(move |prev: Option<Option<TimeoutHandle>>| {
        if let Some(Some(h)) = prev { h.clear(); }
        let t = q.get().trim().to_string();
        if t.chars().count() < 2 {
            if !term.get_untracked().is_empty() { term.set(String::new()); pager.reset(); }
            return None;
        }
        set_timeout_with_handle(move || {
            term.set(t.clone());
            pager.reset();
            pager.more(Source::Search(t), Filter::default());
        }, Duration::from_millis(400)).ok()
    });
    let more = move || { let t = term.get_untracked(); if !t.is_empty() { pager.more(Source::Search(t), Filter::default()) } };
    view! {
        <div class="scroll narrow" on:scroll=move |e| if near_end(&e) { more() }>
            <div class="s-head">
                <div class="title28">"Tìm kiếm"</div>
                <div class="tfield">
                    <Icon d=ic::SEARCH />
                    <input placeholder="Phim, diễn viên, tên gốc…" type="search" enterkeyhint="search" autocomplete="off"
                        prop:value=move || q.get() on:input=move |e| q.set(event_target_value(&e)) />
                    {move || (!q.with(|s| s.is_empty())).then(|| view! {
                        <span class="x" aria-label="Xoá" on:click=move |_| q.set(String::new())><Icon d=ic::CLOSE /></span>
                    })}
                </div>
            </div>
            {move || if term.with(|t| t.is_empty()) {
                view! {
                    <div class="section-title" style="padding:20px 16px 12px">"Khám phá thể loại"</div>
                    <HScroll class="gc2">
                        {move || genres.get().into_iter().map(|c| {
                            let name = c.name.clone().unwrap_or_default();
                            let slug = c.slug.clone().unwrap_or_default();
                            let n2 = name.clone();
                            view! { <div class="gchip glass press" on:click=move |_| n.list(n2.clone(), Source::Genre(slug.clone()))>{name}</div> }
                        }).collect_view()}
                    </HScroll>
                    <div class="section-title" style="padding:28px 16px 12px">"Tìm kiếm hàng đầu"</div>
                    {move || top.get().into_iter().map(|f| {
                        let src = f.thumb();
                        let name = f.name.clone();
                        view! {
                            <div class="tops press" on:click=move |_| n.open(f.clone())>
                                <Img src=src class="th" /><b>{name}</b><Icon d=ic::PLAY_CIRCLE />
                            </div>
                        }
                    }).collect_view()}
                }.into_any()
            } else {
                view! {
                    <div class="grid3" style="padding-top:12px">
                        {move || pager.items.get().into_iter().map(|f| view! { <PosterCard film=f cell=true /> }).collect_view()}
                        {pager.footer(more)}
                    </div>
                    {move || (pager.done.get() && !pager.loading.get() && pager.items.with(|v| v.is_empty()))
                        .then(|| view! { <div class="note">{format!("Không tìm thấy “{}”", term.get())}</div> })}
                }.into_any()
            }}
            <div style="height:calc(120px + var(--bottom))"></div>
        </div>
    }
}
