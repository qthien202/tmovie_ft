#!/usr/bin/env python3
"""Crawl what's hot in Vietnam right now and match it to PhimAPI films.

Source: Netflix's public weekly Top 10 for Vietnam (TV + films) on netflix.com/tudum/top10.
Each title is searched on PhimAPI and matched by its original (English) name. The result,
hot.json, is published on the `hot-data` branch and read by the iOS and Android hero.

Usage: python3 tools/hot/crawl_hot.py out/hot.json      (stdlib only)
"""
import html
import json
import re
import sys
import unicodedata
import urllib.parse
import urllib.request
from datetime import datetime, timezone

UA = {"User-Agent": "Mozilla/5.0 (TMovie hot crawler)"}
TOP10 = "https://www.netflix.com/tudum/top10/vietnam/{kind}"
SEARCH = "https://phimapi.com/v1/api/tim-kiem?keyword={q}&page=1"
ADULT = {"phim-18", "18-plus"}


def fetch(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def netflix_top10(kind):
    """Ranked titles plus the week they cover, for kind 'tv' or 'films'."""
    page = fetch(TOP10.format(kind=kind))
    titles = re.findall(r'data-uia="top10-card-logo"[^>]*>(?:<style[^>]*>[^<]*</style>)?<img[^>]*alt="([^"]+)"', page)
    week = re.search(r'"weekEndDate":"([^"]+)"', page)
    return [html.unescape(t) for t in titles], week.group(1) if week else None


def base_title(title):
    """'Irreplaceable: Season 1' → 'Irreplaceable'; 'X: Limited Series' → 'X'."""
    return re.sub(r":\s*(Season|Part|Limited Series|Volume|Mùa|Phần)\b.*$", "", title, flags=re.I).strip()


def norm(s):
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    s = re.sub(r"\((season|phan|part)[^)]*\)", " ", s)
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def match(title, kind):
    """Best PhimAPI film for a Netflix title: exact origin name first, then a close contains."""
    q = base_title(title)
    try:
        items = json.loads(fetch(SEARCH.format(q=urllib.parse.quote(q))))["data"]["items"] or []
    except Exception:
        return None
    want = norm(q)
    items = [i for i in items if not ADULT & {c.get("slug") for c in i.get("category") or []}]
    wanted_type = "series" if kind == "tv" else "single"

    def score(i):
        origin, name = norm(i.get("origin_name")), norm(i.get("name"))
        if origin == want or name == want:
            s = 3
        elif want and (origin.startswith(want) or want in origin):
            s = 2
        else:
            return 0
        return s + (0.5 if i.get("type") == wanted_type else 0) + (i.get("year") or 0) / 10000

    best = max(items, key=score, default=None)
    return best if best and score(best) > 0 else None


def main(out):
    hot, weeks = [], set()
    for kind in ("tv", "films"):
        titles, week = netflix_top10(kind)
        weeks.add(week)
        for rank, title in enumerate(titles, 1):
            film = match(title, kind)
            print(f"{kind:5} #{rank:<2} {title[:40]:40} -> {film['slug'] if film else '—'}", file=sys.stderr)
            if film:
                hot.append({"rank": rank, "kind": kind, "title": title, "film": film})
    # Interleave TV and films by rank so the hero alternates series and movies.
    hot.sort(key=lambda h: (h["rank"], h["kind"] != "tv"))
    data = {
        "source": "netflix-top10-vietnam",
        "week": max(w for w in weeks if w) if any(weeks) else None,
        "updatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "items": hot,
    }
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    print(f"{len(hot)} matched → {out}", file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "hot.json")
