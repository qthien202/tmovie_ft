package com.thientech.tmovie.feature.browse

import org.junit.Assert.assertEquals
import org.junit.Test

class M3uTest {
    @Test fun parsesNamesAttributesAndOptions() {
        val list = parseM3u(
            """
            #EXTM3U
            #EXTINF:-1 tvg-id="A.vn" tvg-logo="https://x/a.png" group-title="General",An Giang TV 1 (1080p) [Geo-blocked]
            https://a/live.m3u8
            #EXTINF:-1 tvg-logo="" http-user-agent="Mozilla/5.0 (KHTML, like Gecko)" group-title="Sports",Sport, One
            #EXTVLCOPT:http-referrer=https://ref/
            https://b/chunklist
            #EXTINF:-1,Plain
            http://c/p.m3u8
            """.trimIndent(),
        )
        assertEquals(listOf("An Giang TV 1", "Sport, One", "Plain"), list.map { it.name })
        assertEquals("https://x/a.png", list[0].logo)
        assertEquals(true, list[0].geoBlocked)
        assertEquals(null, list[1].logo)
        assertEquals("Mozilla/5.0 (KHTML, like Gecko)", list[1].userAgent)
        assertEquals("https://ref/", list[1].referrer)
        assertEquals("https://b/chunklist", list[1].url)
        assertEquals("vn", list[0].country)
        assertEquals(listOf("General"), list[0].categories)
        assertEquals(null, list[2].country)
    }
}
