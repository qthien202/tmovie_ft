// /__/auth/* and /__/firebase/*: Firebase Auth's handler pages served from our own domain (authDomain = this site),
// so Google sign-in stays first-party in Safari.
//
// The iOS home-screen app can't use that: iOS opens Google in a separate browser sheet whose storage the app
// doesn't share. So the app asks Google for an ID token posted (form_post) to the same registered redirect URI
// with a `tm-` state; we keep it for two minutes under that unguessable state, and the waiting app picks it up
// from /__/tm/token once, then signs in to Firebase with it.
const DONE = `<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>TMovie</title><body style="margin:0;min-height:100vh;display:grid;place-items:center;background:#05080A;color:#fff;font:17px -apple-system,system-ui,sans-serif;text-align:center">
<div style="padding:28px"><div style="font:900 34px -apple-system,system-ui;background:linear-gradient(90deg,#3D8BFF,#8ABCFF);-webkit-background-clip:text;color:transparent">TMOVIE</div>
<p style="margin:18px 0 6px;font-weight:600">Đăng nhập xong</p><p style="margin:0;color:rgba(255,255,255,.7)">Bấm <b>Xong</b> ở góc trên để quay lại TMovie.</p></div>
<script>setTimeout(()=>window.close(),600)</script></body></html>`;

export async function onRequest({ request, env }) {
  const url = new URL(request.url);
  if (url.pathname === '/__/auth/handler' && request.method === 'POST') {
    const form = await request.clone().formData().catch(() => null);
    const state = form && form.get('state');
    if (state && /^tm-[0-9a-f-]{36}$/.test(state)) {
      const token = form.get('id_token');
      if (token) await env.AUTH.put(state, token, { expirationTtl: 120 });
      return new Response(DONE, { headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' } });
    }
  }
  if (url.pathname === '/__/tm/token') {
    const state = url.searchParams.get('state') || '';
    const headers = { 'Cache-Control': 'no-store' };
    if (!/^tm-[0-9a-f-]{36}$/.test(state)) return new Response('bad state', { status: 400, headers });
    const token = await env.AUTH.get(state);
    if (!token) return new Response(null, { status: 204, headers });
    await env.AUTH.delete(state);
    return new Response(token, { headers });
  }
  return fetch(new Request('https://tmovie-1db06.firebaseapp.com' + url.pathname + url.search, request));
}
