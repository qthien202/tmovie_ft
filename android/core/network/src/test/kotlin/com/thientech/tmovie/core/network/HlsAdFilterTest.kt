package com.thientech.tmovie.core.network

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** ad_playlist.m3u8: a real PhimAPI variant playlist (2026-10-10) with a mid-roll and a post-roll. */
class HlsAdFilterTest {
    private val source = javaClass.getResource("/fixtures/ad_playlist.m3u8")!!.readText()

    @Test fun stripsSplicedAds() {
        val cleaned = HlsAdFilter.clean(source)
        val segments = cleaned.lines().filter { it.endsWith(".ts") }
        assertFalse(segments.any { it.startsWith("convertv8/") })  // mid-roll
        assertFalse(segments.any { it.startsWith("/v8/") })        // post-roll
        assertTrue(segments.all { '/' !in it })                    // only the film's own segments remain
        assertEquals(source.lines().count { it.endsWith(".ts") && '/' !in it }, segments.size)
        assertTrue(cleaned.trimEnd().endsWith("#EXT-X-ENDLIST"))
        assertFalse("#EXT-X-DISCONTINUITY\n#EXT-X-DISCONTINUITY" in cleaned)
    }

    @Test fun leavesMasterAndCleanPlaylistsAlone() {
        val master = "#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1\n3500kb/hls/index.m3u8\n"
        assertEquals(master, HlsAdFilter.clean(master))
        val plain = "#EXTM3U\n#EXTINF:4.0,\na.ts\n#EXTINF:4.0,\nb.ts\n#EXT-X-ENDLIST\n"
        assertEquals(plain, HlsAdFilter.clean(plain))
    }

    @Test fun keepsTheFilmsPathAndRefusesBigCuts() {
        // "x/" holds most segments, so it is the film; the odd "a.ts" block is the one dropped.
        val oddOneOut = "#EXTM3U\n#EXTINF:4.0,\na.ts\n#EXT-X-DISCONTINUITY\n#EXTINF:4.0,\nx/b.ts\n#EXTINF:4.0,\nx/c.ts\n#EXTINF:4.0,\nx/d.ts\n#EXT-X-ENDLIST\n"
        val cleaned = HlsAdFilter.clean(oddOneOut)
        assertTrue("x/b.ts" in cleaned && "a.ts" !in cleaned.lines())
        // Dropping 8 s of 12 s is more than a quarter: leave the playlist untouched.
        val tooMuch = "#EXTM3U\n#EXTINF:4.0,\na.ts\n#EXTINF:4.0,\nb.ts\n#EXTINF:4.0,\nc.ts\n#EXT-X-DISCONTINUITY\n#EXTINF:8.0,\nx/ad.ts\n#EXT-X-ENDLIST\n"
        assertTrue("x/ad.ts" in HlsAdFilter.clean(tooMuch.replace("#EXTINF:8.0", "#EXTINF:80.0")))
    }
}
