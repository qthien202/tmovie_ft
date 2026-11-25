// TMovie service worker: the app shell (HTML, CSS, wasm, JS, icons) opens from cache and refreshes in the
// background; posters from the image CDNs are kept for a week. API calls and /hls always go to the network.
const SHELL = 'tmovie-shell-v1';
const IMAGES = 'tmovie-img-v1';

self.addEventListener('install', (e) => { self.skipWaiting(); });
self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => ![SHELL, IMAGES].includes(k)).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET') return;
  if (url.origin === location.origin && !url.pathname.startsWith('/hls')) {
    // Stale-while-revalidate for the shell.
    e.respondWith(caches.open(SHELL).then(async (cache) => {
      const hit = await cache.match(e.request);
      const net = fetch(e.request).then((res) => { if (res.ok) cache.put(e.request, res.clone()); return res; }).catch(() => hit);
      return hit || net;
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
