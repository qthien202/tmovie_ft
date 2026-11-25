//! Của tôi, as feature/profile: editable name, Xem gần đây, Danh sách của tôi, settings, confirm dialogs.
//! No account card: it is hidden when Firebase isn't configured, which is always the case on the web.

use leptos::prelude::*;

use super::*;

#[component]
pub fn Profile() -> impl IntoView {
    let n = nav();
    let name = RwSignal::new(store::get::<String>("profileName").unwrap_or_else(|| "Bạn".into()));
    let autoplay = RwSignal::new(store::flag("heroAutoplay", true));
    let confirm = RwSignal::new(None::<bool>); // Some(true) = history, Some(false) = list
    let history = move || { n.lib.get(); store::history() };
    let saved = move || { n.lib.get(); store::saved() };
    view! {
        <div class="scroll">
            <div class="p-head">
                <div class="title28">"Của tôi"</div>
                <div class="p-av">
                    <div class="av">{move || name.get().chars().next().map(|c| c.to_uppercase().to_string()).unwrap_or_default()}</div>
                    <div style="flex:1;min-width:0">
                        <input maxlength="40" prop:value=move || name.get() on:input=move |e| {
                            let v = event_target_value(&e);
                            store::set("profileName", &v);
                            name.set(v);
                        } />
                        <div class="sub">{move || format!("{} phim đã lưu · {} phim đã xem", saved().len(), history().len())}</div>
                    </div>
                </div>
            </div>
            {move || { let h = history(); (!h.is_empty()).then(|| view! {
                <Shelf title="Xem gần đây" gap=14>{h.into_iter().take(20).map(|w| view! { <ContinueCard w=w /> }).collect_view()}</Shelf>
            }) }}
            <div style="margin:26px 0 10px"><RailHeader title="Danh sách của tôi" /></div>
            {move || { let s = saved(); if s.is_empty() {
                view! { <div class="sec" style="padding:0 16px;font-size:14px">"Nhấn + Danh sách ở một bộ phim để lưu lại."</div> }.into_any()
            } else {
                view! { <div class="grid3">{s.into_iter().map(|f| view! { <PosterCard film=f cell=true /> }).collect_view()}</div> }.into_any()
            } }}
            <div class="settings glass">
                <div class="srow" on:click=move |_| { let v = !autoplay.get_untracked(); autoplay.set(v); store::set_flag("heroAutoplay", v); }>
                    <Icon d=ic::SLIDES /><div class="sb" style="padding-top:8px;padding-bottom:8px"><span class="t">"Tự phát xem trước"</span><div class="switch" class:on=move || autoplay.get()></div></div>
                </div>
                <div class="srow" on:click=move |_| confirm.set(Some(true))>
                    <Icon d=ic::HISTORY /><div class="sb"><span class="t">"Xoá lịch sử xem"</span><span class="chev"><Icon d=ic::CHEV_R /></span></div>
                </div>
                <div class="srow" on:click=move |_| confirm.set(Some(false))>
                    <Icon d=ic::TRASH /><div class="sb"><span class="t">"Xoá danh sách của tôi"</span><span class="chev"><Icon d=ic::CHEV_R /></span></div>
                </div>
                <div class="srow">
                    <Icon d=ic::INFO /><div class="sb"><span class="t">"Phiên bản"</span><span class="sec">{env!("CARGO_PKG_VERSION")}</span></div>
                </div>
            </div>
            <div style="height:calc(120px + var(--bottom))"></div>
        </div>
        {move || confirm.get().map(|hist| view! {
            <div class="dialog-veil" on:click=move |_| confirm.set(None)>
                <div class="dialog" on:click=|e| e.stop_propagation()>
                    <h3>{if hist { "Xoá lịch sử xem?" } else { "Xoá danh sách của tôi?" }}</h3>
                    <div class="acts">
                        <span on:click=move |_| confirm.set(None)>"Huỷ"</span>
                        <span class="red" on:click=move |_| {
                            if hist { for w in store::history() { store::forget(&w.film.slug) } } else { store::set("tm.list", &Vec::<Film>::new()) }
                            n.bump();
                            confirm.set(None);
                        }>"Xoá"</span>
                    </div>
                </div>
            </div>
        })}
    }
}
