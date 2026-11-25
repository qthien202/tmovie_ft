// TMovie service worker. The page itself comes from the network first (so a new deploy, whose wasm/CSS have new
// hashed names, is picked up on the next launch) and from cache only when offline. Hashed files never change, so
// they come from cache first. Posters are kept for a week. API calls, /hls and /img always go to the network.
const SHELL = 'tmovie-shell-v2';
const IMAGES = 'tmovie-img-v1';

self.addEventListener('install', () => { self.skipWaiting(); });
self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => ![SHELL, IMAGES].includes(k)).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET') return;
  if (url.origin === location.origin) {
    if (url.pathname.startsWith('/hls') || url.pathname.startsWith('/img')) return;
    if (e.request.mode === 'navigate' || url.pathname === '/' || url.pathname.endsWith('.html')) {
      e.respondWith(fetch(e.request).then((res) => {
        if (res.ok) { const copy = res.clone(); caches.open(SHELL).then((c) => c.put('/', copy)); }
        return res;
      }).catch(() => caches.match('/')));
      return;
    }
    e.respondWith(caches.open(SHELL).then(async (cache) => {
      const hit = await cache.match(e.request);
      if (hit) return hit;
      const res = await fetch(e.request);
      // Pages answers a missing file with the HTML page; never keep that under an asset's name.
      if (res.ok && !(res.headers.get('content-type') || '').includes('text/html')) cache.put(e.request, res.clone());
      return res;
    }));
  } else if (/phimimg\.com|image\.tmdb\.org/.test(url.hostname)) {
    e.respondWith(caches.open(IMAGES).then(async (cache) => {
      const hit = await cache.match(e.request);
      if (hit) return hit;
      const res = await fetch(e.request);
      if (res.ok || res.type === 'opaque') cache.put(e.request, res.clone());
      return res;
    }));
  }
});
