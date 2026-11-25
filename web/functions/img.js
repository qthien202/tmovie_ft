// /img?u=<phimimg url>: the same image with CORS, so the app can sample its colour (phimimg.com sends no CORS headers).
export async function onRequestGet({ request }) {
  const u = new URL(request.url).searchParams.get('u') || '';
  let target;
  try { target = new URL(u); } catch { return new Response('bad url', { status: 400 }); }
  if (target.protocol !== 'https:' || target.hostname !== 'phimimg.com') return new Response('forbidden', { status: 403 });
  const res = await fetch(target, { cf: { cacheTtl: 86400, cacheEverything: true } });
  const out = new Response(res.body, res);
  out.headers.set('Access-Control-Allow-Origin', '*');
  out.headers.set('Cache-Control', 'public, max-age=86400');
  return out;
}
