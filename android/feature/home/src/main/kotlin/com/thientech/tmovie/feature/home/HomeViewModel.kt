package com.thientech.tmovie.feature.home

import android.app.Application
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.HotList
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.ui.ListRoute
import java.time.LocalDate
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable

/** A horizontal rail on Home. */
data class Rail(val title: String, val route: ListRoute)

val homeRails = listOf(
    Rail("Mới cập nhật", ListRoute.type("Mới cập nhật", "phim-moi-cap-nhat")),
    Rail("Phim Hàn Quốc", ListRoute.country("Hàn Quốc", "han-quoc")),
    Rail("Phim Trung Quốc", ListRoute.country("Trung Quốc", "trung-quoc")),
    Rail("Phim lẻ", ListRoute.type("Phim lẻ", "phim-le")),
    Rail("TV Shows", ListRoute.type("TV Shows", "tv-shows")),
    Rail("Hành động", ListRoute.genre("Hành động", "hanh-dong")),
    Rail("Tình cảm", ListRoute.genre("Tình cảm", "tinh-cam")),
    Rail("Kinh dị", ListRoute.genre("Kinh dị", "kinh-di")),
    Rail("Hoạt hình", ListRoute.type("Hoạt hình", "hoat-hinh")),
)

class HomeViewModel(app: Application) : AndroidViewModel(app) {
    private val api = PhimApi.shared
    var hero by mutableStateOf<List<FilmItem>>(emptyList()); private set
    var top10 by mutableStateOf<List<FilmItem>>(emptyList()); private set
    /** Textless TMDB backdrops (w1280) per hero slug: cleaner key art than PhimAPI thumbs. */
    val heroArt = mutableStateMapOf<String, String>()
    val rails = mutableStateMapOf<Rail, List<FilmItem>>()
    var failed by mutableStateOf(false); private set
    var refreshing by mutableStateOf(false); private set

    init { load() }

    fun load(refresh: Boolean = false) = viewModelScope.launch {
        failed = false
        refreshing = refresh
        coroutineScope {
            val heroJob = async { loadHero(refresh) }
            homeRails.map { rail ->
                async { rails[rail] = runCatching { api.list(rail.route.source).items }.getOrDefault(emptyList()) }
            }.awaitAll()
            val (h, t) = heroJob.await()
            hero = h
            top10 = t
        }
        hero.map { film ->
            async {
                val images = runCatching { api.images(film.slug) }.getOrDefault(emptyList())
                (images.firstOrNull { it.type == "backdrop" && it.iso6391 == null } ?: images.firstOrNull { it.type == "backdrop" })
                    ?.url("w1280")?.let { heroArt[film.slug] = it }
            }
        }.awaitAll()
        failed = hero.isEmpty() && rails.values.all { it.isEmpty() }
        refreshing = false
    }

    /**
     * 1. Netflix Top 10 Vietnam, crawled every 6h (tools/hot). 2. Fallback: what is updating now,
     * ranked by real KKPhim views (PhimAPI ignores `sort_field=view`), cached for the day.
     */
    private suspend fun loadHero(refresh: Boolean): Pair<List<FilmItem>, List<FilmItem>> {
        HotList.fetch()?.let { hot ->
            val hero = hot.films.filterNot { it.isAnimation }
            if (hero.size >= 5) return hero.take(12) to hot.series.take(10)
        }
        val prefs = getApplication<Application>().getSharedPreferences("home", Context.MODE_PRIVATE)
        val today = LocalDate.now().toString()
        if (!refresh && prefs.getString("hero.day", null) == today) {
            val cached = runCatching { PhimApi.json.decodeFromString(HeroCache.serializer(), prefs.getString("hero.v6", "")!!) }.getOrNull()
            if (cached != null && cached.hero.isNotEmpty()) return cached.hero to cached.series
        }
        val ranked = rankByViews()
        if (ranked.first.size < 5) return freshest() to emptyList()
        prefs.edit().putString("hero.day", today)
            .putString("hero.v6", PhimApi.json.encodeToString(HeroCache.serializer(), HeroCache(ranked.first, ranked.second))).apply()
        return ranked
    }

    @Serializable private class HeroCache(val hero: List<FilmItem>, val series: List<FilmItem>)

    private suspend fun rankByViews(): Pair<List<FilmItem>, List<FilmItem>> = coroutineScope {
        val lists = listOf(Source.Type("phim-bo") to 1, Source.Type("phim-bo") to 2, Source.Type("phim-le") to 1)
            .map { (s, p) -> async { runCatching { api.list(s, p).items }.getOrDefault(emptyList()) } }.awaitAll().flatten()
        val candidates = lists.distinctBy { it.slug }.filterNot { it.isAnimation }
        val scored = candidates.map { film ->
            async {
                val d = runCatching { api.detail(film.slug) }.getOrNull()
                if (d == null || !d.isPlayable) null else film to (d.view ?: 0).toDouble()
            }
        }.awaitAll().filterNotNull()
        fun boost(f: FilmItem) = if (f.country.orEmpty().any { it.slug in preferred }) 1.5 else 1.0
        scored.sortedByDescending { it.second * boost(it.first) }.take(10).map { it.first } to
            scored.filter { it.first.type == "series" }.sortedByDescending { it.second }.take(10).map { it.first }
    }

    /** Port of the Flutter `_freshestFallback`: Hàn/Trung/Âu Mỹ first, no animation, top 10. */
    private suspend fun freshest(): List<FilmItem> = coroutineScope {
        val all = listOf(1, 2).map { p -> async { runCatching { api.list(Source.Type("phim-moi-cap-nhat"), p).items }.getOrDefault(emptyList()) } }
            .awaitAll().flatten().distinctBy { it.slug }.filterNot { it.isAnimation }
        val (pref, rest) = all.partition { f -> f.country.orEmpty().any { it.slug in preferred } }
        (pref + rest).take(10)
    }

    private companion object {
        val preferred = setOf("han-quoc", "trung-quoc", "au-my")
    }

}
