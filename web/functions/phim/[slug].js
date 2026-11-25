// /phim/<slug>: the app page with that film's link preview (title, synopsis, art) for Messenger, Zalo, iMessage…
// The app itself reads the path and opens the film (see ui/mod.rs `film_path`).
const API = 'https://phimapi.com/v1/api';

const plain = (html) => (html || '').replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/\s+/g, ' ').trim();
const image = (u) => !u ? '' : u.startsWith('http') ? u : 'https://phimimg.com/' + (u.replace(/^\//, '').includes('/') ? u.replace(/^\//, '') : 'uploads/movies/' + u);
const json = (url) => fetch(url, { cf: { cacheTtl: 3600, cacheEverything: true } }).then((r) => (r.ok ? r.json() : null)).catch(() => null);

export async function onRequestGet({ request, params, env }) {
  const page = await env.ASSETS.fetch(new URL('/', request.url));
  const slug = String(params.slug || '');
  if (!/^[a-z0-9-]{1,120}$/.test(slug)) return page;
  const [detail, images] = await Promise.all([json(`${API}/phim/${slug}`), json(`${API}/phim/${slug}/images`)]);
  const f = detail && detail.data && detail.data.item;
  if (!f || !f.name) return page;

  // A textless TMDB backdrop (JPEG, which every chat app reads), else the film's own wide thumb.
  const backs = ((images && images.data && images.data.images) || []).filter((i) => i.type === 'backdrop');
  backs.sort((a, b) => (a.iso_639_1 == null ? 0 : 1) - (b.iso_639_1 == null ? 0 : 1));
  const art = backs.length ? `https://image.tmdb.org/t/p/w1280${backs[0].file_path}` : image(f.thumb_url || f.poster_url);
  const facts = [f.origin_name, f.year, f.episode_current, f.quality].filter(Boolean).join(' · ');
  const story = plain(f.content);
  const desc = [facts, story.length > 170 ? story.slice(0, 167) + '…' : story].filter(Boolean).join(' — ');
  const title = `${f.name} · TMovie`;
  const url = new URL(`/phim/${slug}`, request.url).toString();

  const set = (value) => ({ element: (e) => e.setAttribute('content', value) });
  return new HTMLRewriter()
    .on('title', { element: (e) => e.setInnerContent(title) })
    .on('link[rel="canonical"]', { element: (e) => e.setAttribute('href', url) })
    .on('meta[name="description"]', set(desc))
    .on('meta[property="og:type"]', set('video.movie'))
    .on('meta[property="og:title"]', set(f.name))
    .on('meta[property="og:description"]', set(desc))
    .on('meta[property="og:url"]', set(url))
    .on('meta[property="og:image"]', set(art))
    .on('meta[name="twitter:image"]', set(art))
    .on('meta[property="og:image:width"]', { element: (e) => e.remove() })
    .on('meta[property="og:image:height"]', { element: (e) => e.remove() })
    .transform(new Response(page.body, { headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'public, max-age=600' } }));
}
