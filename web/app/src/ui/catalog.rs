//! A list page, as browse/CatalogScreen + FilterButton: featured card, slices by country/genre, endless grid, filters.

use leptos::prelude::*;
use leptos::task::spawn_local;

use super::*;
use crate::api::Filter;
use crate::glue;

const BY_COUNTRY: [(&str, &str); 6] = [("Hàn Quốc", "han-quoc"), ("Trung Quốc", "trung-quoc"), ("Âu Mỹ", "au-my"), ("Nhật Bản", "nhat-ban"), ("Thái Lan", "thai-lan"), ("Việt Nam", "viet-nam")];
const BY_GENRE: [(&str, &str); 5] = [("Hành động", "hanh-dong"), ("Tình cảm", "tinh-cam"), ("Cổ trang", "co-trang"), ("Hài hước", "hai-huoc"), ("Kinh dị", "kinh-di")];

fn this_year() -> i64 { js_sys::Date::new_0().get_full_year() as i64 }

#[component]
pub fn Catalog(title: String, source: Source) -> impl IntoView {
    let n = nav();
    let category = RwSignal::new(None::<Category>);
    let country = RwSignal::new(None::<Category>);
    let year = RwSignal::new(None::<i64>);
    let sort = RwSignal::new(None::<String>);
    let is_country = matches!(source, Source::Country(_));
    let is_genre = matches!(source, Source::Genre(_));
    let filtering = move || category.with(|c| c.is_some()) || country.with(|c| c.is_some()) || year.with(|y| y.is_some());
    let filter = move || Filter {
        category: category.get().and_then(|c| c.slug),
        country: country.get().and_then(|c| c.slug),
        year: year.get(),
        sort: sort.get(),
    };
    let src = StoredValue::new(source.clone());
    let pager = Pager::new();
    Effect::new(move |_| {
        let f = filter();
        pager.reset();
        pager.more(src.get_value(), f);
    });
    let more = move || pager.more(src.get_value(), filter_untracked(category, country, year, sort));

    // Slices with at least 4 films become shelves.
    let shelves = RwSignal::new(Vec::<(usize, String, Source, Vec<Film>)>::new());
    {
        let slices: Vec<(&str, Filter)> = if is_country {
            BY_GENRE.iter().map(|(t, s)| (*t, Filter { category: Some(s.to_string()), ..Default::default() })).collect()
        } else {
            BY_COUNTRY.iter().map(|(t, s)| (*t, Filter { country: Some(s.to_string()), ..Default::default() })).collect()
        };
        for (k, (t, f)) in slices.into_iter().enumerate() {
            let source = source.clone();
            spawn_local(async move {
                if let Ok(p) = api::list(&source, 1, &f).await {
                    if p.items.len() >= 4 {
                        // Ponytail: "Tất cả" on a slice opens the slice's own list (country/genre), not the filtered parent.
                        let more = match (&f.country, &f.category) {
                            (Some(c), _) => Source::Country(c.clone()),
                            (_, Some(g)) => Source::Genre(g.clone()),
                            _ => source.clone(),
                        };
                        shelves.update(|v| { v.push((k, t.to_string(), more, p.items)); v.sort_by_key(|s| s.0); });
                    }
                }
            });
        }
    }
    let featured = move || (!filtering()).then(|| pager.items.with(|v| v.first().cloned())).flatten();
    let tint = RwSignal::new("61,139,255".to_string());
    Effect::new(move |_| if let Some(f) = featured() {
        let url = f.thumb();
        spawn_local(async move { if let Some(c) = glue::tint_of(&url).await { tint.set(c) } });
    });

    let year_menu = move |e: web_sys::MouseEvent, right: bool| {
        let mut items = vec![MenuItem::new("Tất cả", year.get_untracked().is_none(), move || year.set(None))];
        items.extend((2000..=this_year()).rev().map(|y| MenuItem::new(y.to_string(), year.get_untracked() == Some(y), move || year.set(Some(y)))));
        open_menu(n, &e, right, items);
    };
    let root_menu = move |e: web_sys::MouseEvent| {
        let s = sort.get_untracked();
        let mut items = vec![
            MenuItem::new("Mới cập nhật", s.is_none(), move || sort.set(None)),
            MenuItem::new("Năm phát hành", s.as_deref() == Some("year"), move || sort.set(Some("year".into()))),
            MenuItem::new("Mới thêm", s.as_deref() == Some("_id"), move || sort.set(Some("_id".into()))),
            MenuItem::sep(),
        ];
        let y = year.get_untracked();
        // Submenus open at the same spot as the root menu.
        items.push(MenuItem::sub(y.map(|y| format!("Năm: {y}")).unwrap_or_else(|| "Năm".into()), move || {
            let at = n.menu.get_untracked();
            let mut items = vec![MenuItem::new("Tất cả", year.get_untracked().is_none(), move || year.set(None))];
            items.extend((2000..=this_year()).rev().map(|y| MenuItem::new(y.to_string(), year.get_untracked() == Some(y), move || year.set(Some(y)))));
            if let Some(m) = at { n.menu.set(Some(Menu { items, ..m })) }
        }));
        let push_tax = |items: &mut Vec<MenuItem>, label: &str, countries: bool| {
            items.push(MenuItem::sub(label, move || {
                let target = if countries { country } else { category };
                let at = n.menu.get_untracked();
                spawn_local(async move {
                    let all = api::taxonomy(if countries { "quoc-gia" } else { "the-loai" }).await;
                    let cur = target.get_untracked().and_then(|c| c.slug);
                    let mut items = vec![MenuItem::new("Tất cả", cur.is_none(), move || target.set(None))];
                    items.extend(all.into_iter().map(|c| {
                        let on = cur.is_some() && c.slug == cur;
                        MenuItem::new(c.name.clone().unwrap_or_default(), on, move || target.set(Some(c.clone())))
                    }));
                    if let Some(m) = at { n.menu.set(Some(Menu { items, ..m })) }
                });
            }));
        };
        if !is_country { push_tax(&mut items, "Quốc gia", true); }
        if !is_genre { push_tax(&mut items, "Thể loại", false); }
        if filtering() {
            let mut clear = MenuItem::new("Bỏ lọc", false, move || { category.set(None); country.set(None); year.set(None); });
            clear.red = true;
            items.push(clear);
        }
        open_menu(n, &e, true, items);
    };

    let t2 = title.clone();
    view! {
        <div class="home-bg" style:background=move || format!("linear-gradient(rgba({},.4), var(--canvas) 50%)", tint.get())></div>
        <div class="scroll" on:scroll=move |e| if near_end(&e) { more() }>
            <div class="cat-top">
                <div class="r1">
                    <div class="circ40 glass press" aria-label="Quay lại" on:click=move |_| n.back()><Icon d=ic::BACK /></div>
                    <div class="circ40 glass press" class:tint=filtering aria-label="Bộ lọc" on:click=root_menu><Icon d=ic::FILTER /></div>
                </div>
                <div class="title28">{title.clone()}</div>
                <div class="cat-pills">
                    <div class="pill glass press" on:click=move |_| n.back()>{t2}<Icon d=ic::CLOSE /></div>
                    {(!is_country).then(|| view! { <GenrePickerPill countries=true filter=Some(country) /> })}
                    {(!is_genre).then(|| view! { <GenrePickerPill countries=false filter=Some(category) /> })}
                    <div class="pill glass press" class:on=move || year.with(|y| y.is_some()) on:click=move |e| year_menu(e, false)>
                        {move || year.get().map(|y| y.to_string()).unwrap_or_else(|| "Năm".into())}<Icon d=ic::CHEV_D />
                    </div>
                    {move || filtering().then(|| view! {
                        <div class="circ34 glass press" aria-label="Bỏ lọc" on:click=move |_| { category.set(None); country.set(None); year.set(None); }><Icon d=ic::CLOSE /></div>
                    })}
                </div>
            </div>
            {move || featured().map(|f| {
                let open = f.clone();
                view! {
                    <div class="featured" on:click=move |_| n.open(open.clone())>
                        <Img src=f.thumb() />
                        <div class="g"></div>
                        <div class="in">
                            <div class="title28">{f.name.clone()}</div>
                            <span>{f.genre_line()}</span>
                            <div class="two">
                                <PlayFilmButton film=f.clone() wide=true />
                                <SaveButton film=f style=SaveStyle::Wide />
                            </div>
                        </div>
                    </div>
                }
            })}
            {move || (!filtering()).then(|| shelves.get().into_iter().map(|(_, t, s, films)| {
                view! {
                    <div style="margin-top:26px">
                        <Shelf title=t.clone() more=Some((t, s))>{films.into_iter().map(|f| view! { <PosterCard film=f /> }).collect_view()}</Shelf>
                    </div>
                }
            }).collect_view())}
            <div style="margin:26px 0 10px">{move || view! { <RailHeader title=if filtering() { "Kết quả" } else { "Tất cả" } /> }}</div>
            <div class="grid3">
                {move || pager.items.get().into_iter().map(|f| view! { <PosterCard film=f cell=true /> }).collect_view()}
                {pager.footer(more)}
            </div>
            {move || (filtering() && pager.done.get() && !pager.loading.get() && pager.items.with(|v| v.is_empty()))
                .then(|| view! { <div class="note" style="padding:32px">"Không có phim · thử bỏ bớt bộ lọc"</div> })}
            <div style="height:calc(120px + var(--bottom))"></div>
        </div>
    }
}

fn filter_untracked(category: RwSignal<Option<Category>>, country: RwSignal<Option<Category>>, year: RwSignal<Option<i64>>, sort: RwSignal<Option<String>>) -> Filter {
    Filter {
        category: category.get_untracked().and_then(|c| c.slug),
        country: country.get_untracked().and_then(|c| c.slug),
        year: year.get_untracked(),
        sort: sort.get_untracked(),
    }
}
