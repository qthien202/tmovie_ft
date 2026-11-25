/**
 * GET /hls?u=<playlist URL>: the stream's HLS playlist without the ads the providers splice in.
 * Same rule as the apps' HlsAdFilter: drop every #EXT-X-DISCONTINUITY block whose segments all come
 * from a directory other than the film's, unless that would cut more than a quarter of the time.
 *
 * Only playlists (a few KB of text) pass through here. Segment URIs are made absolute so the video
 * itself is fetched straight from the provider; variant playlists point back at /hls so they are
 * cleaned too.
 */
const DISCONTINUITY = '#EXT-X-DISCONTINUITY';

export async function onRequestGet({ request }) {
  const target = new URL(request.url).searchParams.get('u') || '';
  let src;
  try { src = new URL(target); } catch { return new Response('bad url', { status: 400 }); }
  if (!/^https?:$/.test(src.protocol) || !/\.m3u8$/i.test(src.pathname)) return new Response('not a playlist', { status: 400 });

  const res = await fetch(src, { headers: { 'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)' }, cf: { cacheTtl: 300, cacheEverything: true } });
  if (!res.ok) return new Response(`upstream ${res.status}`, { status: 502 });
  const text = await res.text();
  if (!text.startsWith('#EXTM3U') || text.length > 4_000_000) return new Response('not a playlist', { status: 502 });

  const self = new URL(request.url);
  const body = text.includes('#EXT-X-STREAM-INF') ? rewriteMaster(text, res.url, self) : absolutize(clean(text), res.url);
  return new Response(body, {
    headers: {
      'Content-Type': 'application/vnd.apple.mpegurl',
      'Cache-Control': 'public, max-age=300',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

/** Variant playlists go back through /hls; other URIs become absolute. */
function rewriteMaster(text, base, self) {
  return text.split('\n').map((line) => {
    const t = line.trim();
    if (!t || t.startsWith('#')) return line.replace(/URI="([^"]+)"/g, (_, u) => `URI="${new URL(u, base)}"`);
    const abs = new URL(t, base).toString();
    return /\.m3u8(\?|$)/i.test(abs) ? `${self.origin}/hls?u=${encodeURIComponent(abs)}` : abs;
  }).join('\n');
}

function absolutize(text, base) {
  return text.split('\n').map((line) => {
    const t = line.trim();
    if (!t) return line;
    if (t.startsWith('#')) return line.replace(/URI="([^"]+)"/g, (_, u) => `URI="${new URL(u, base)}"`);
    return new URL(t, base).toString();
  }).join('\n');
}

const dirOf = (seg) => { const p = seg.split('?')[0]; const i = p.lastIndexOf('/'); return i < 0 ? '' : p.slice(0, i); };

/** The apps' HlsAdFilter.clean, line for line. */
export function clean(playlist) {
  if (playlist.includes('#EXT-X-STREAM-INF') || !playlist.includes(DISCONTINUITY)) return playlist;
  const lines = playlist.split('\n');
  const headerEnd = lines.findIndex((l) => l.startsWith('#EXTINF') || l.trim() === DISCONTINUITY);
  if (headerEnd < 0) return playlist;
  const header = lines.slice(0, headerEnd);
  const body = lines.slice(headerEnd);
  const endList = body.some((l) => l.trim() === '#EXT-X-ENDLIST');

  const blocks = [];
  let cur = [];
  for (const line of body) {
    const t = line.trim();
    if (t === DISCONTINUITY) { if (cur.length) blocks.push(cur); cur = []; } else if (t !== '#EXT-X-ENDLIST') cur.push(line);
  }
  if (cur.length) blocks.push(cur);
  const info = blocks.map((b) => ({
    lines: b,
    segments: b.filter((l) => l.trim() && !l.startsWith('#')),
    duration: b.filter((l) => l.startsWith('#EXTINF:')).reduce((a, l) => a + (parseFloat(l.slice(8)) || 0), 0),
  }));

  const counts = {};
  info.forEach((b) => b.segments.forEach((s) => { counts[dirOf(s)] = (counts[dirOf(s)] || 0) + 1; }));
  const mainDir = Object.entries(counts).sort((a, b) => b[1] - a[1])[0]?.[0];
  if (mainDir === undefined) return playlist;
  const kept = info.filter((b) => !b.segments.length || b.segments.some((s) => dirOf(s) === mainDir));
  const dropped = info.filter((b) => !kept.includes(b));
  if (!dropped.length) return playlist;
  const total = info.reduce((a, b) => a + b.duration, 0);
  if (total <= 0 || dropped.reduce((a, b) => a + b.duration, 0) > total / 4) return playlist;

  const out = [...header];
  kept.filter((b) => b.segments.length || b.lines.some((l) => l.trim())).forEach((b, i) => {
    if (i > 0) out.push(DISCONTINUITY);
    out.push(...b.lines.filter((l) => l.trim()));
  });
  if (endList) out.push('#EXT-X-ENDLIST');
  return out.join('\n') + '\n';
}
