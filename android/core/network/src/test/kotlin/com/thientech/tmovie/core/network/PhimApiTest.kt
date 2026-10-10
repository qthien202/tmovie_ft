package com.thientech.tmovie.core.network

import com.thientech.tmovie.core.model.phimImageUrl
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Fixtures recorded from https://phimapi.com/v1/api on 2026-10-10 (shared with the iOS tests). */
class PhimApiTest {
    private fun fixture(name: String) = javaClass.getResource("/fixtures/$name.json")!!.readText()

    @Test fun homeListDecodes() {
        val page = PhimApi.parsePage(fixture("list"))
        assertTrue(page.items.size > 20)
        assertEquals(1, page.currentPage)
        assertTrue(page.totalPages > 1000 && page.hasMore)
        assertTrue(page.items.first().thumbImage!!.startsWith("https://phimimg.com/"))
    }

    @Test fun detailDecodes() {
        val detail = PhimApi.json.decodeFromString<Envelope<DetailData>>(fixture("detail")).data.item
        assertEquals("nguoi-tinh-mang-mat-na-phan-1", detail.slug)
        assertEquals("24", detail.episodeTotal) // sent as a number
        assertEquals("336183", detail.tmdb?.id)
        assertTrue(detail.episodes!!.first().serverData!!.first().streamUrl!!.endsWith(".m3u8"))
        assertEquals(detail.slug, detail.toItem().slug)
    }

    @Test fun imagesPeoplesGenresDecode() {
        val images = PhimApi.json.decodeFromString<Envelope<ImagesData>>(fixture("images")).data.images!!
        assertTrue(images.first().url()!!.startsWith("https://image.tmdb.org/t/p/w780/"))
        val people = PhimApi.json.decodeFromString<Envelope<PeoplesData>>(fixture("peoples")).data.peoples!!
        assertEquals("Wang Ruichang", people.first().name)
        val genres = PhimApi.json.decodeFromString<Envelope<TaxonomyData>>(fixture("genres")).data.items
        assertTrue(genres.any { it.slug == "hanh-dong" })
    }

    @Test fun imageUrlRules() {
        assertEquals("https://phimimg.com/upload/vod/a.jpg", phimImageUrl("upload/vod/a.jpg"))
        assertEquals("https://phimimg.com/uploads/movies/a.jpg", phimImageUrl("/uploads/movies/a.jpg"))
        assertEquals("https://phimimg.com/uploads/movies/a.jpg", phimImageUrl("a.jpg"))
        assertEquals("https://x.com/a.jpg", phimImageUrl("https://x.com/a.jpg"))
        assertNull(phimImageUrl(""))
    }

    @Test fun listUrls() {
        val api = PhimApi()
        assertEquals(
            "https://phimapi.com/v1/api/danh-sach/phim-bo?page=2&country=han-quoc&year=2026",
            api.listUrl(Source.Type("phim-bo"), 2, Filter(country = "han-quoc", year = 2026)).toString(),
        )
        assertEquals(
            "https://phimapi.com/v1/api/tim-kiem?page=1&keyword=t%C3%ACnh%20y%C3%AAu",
            api.listUrl(Source.Search("tình yêu"), 1, Filter()).toString(),
        )
    }

    @Test fun hidesAdultAndTrailers() {
        val body = """
            {"data":{"items":[
              {"name":"A","slug":"a","category":[{"slug":"18-plus"}]},
              {"name":"A2","slug":"a2","category":[{"slug":"phim-18"}]},
              {"name":"B","slug":"b","episode_current":"Trailer"},
              {"name":"C","slug":"c"}
            ],"params":{"pagination":{"totalItems":49,"totalItemsPerPage":24,"currentPage":1}}}}
        """.trimIndent()
        assertEquals(listOf("c"), PhimApi.parsePage(body).items.map { it.slug })
        assertEquals(listOf("b", "c"), PhimApi.parsePage(body, keepTrailers = true).items.map { it.slug })
        assertEquals(3, PhimApi.parsePage(body).totalPages) // computed when the API omits it
    }
}
