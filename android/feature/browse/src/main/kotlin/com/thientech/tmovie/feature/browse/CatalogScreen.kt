package com.thientech.tmovie.feature.browse

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.ColorSampler
import com.thientech.tmovie.core.designsystem.HeroShape
import com.thientech.tmovie.core.designsystem.Pill
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.model.genreLine
import com.thientech.tmovie.core.network.Filter
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.ui.GenrePickerPill
import com.thientech.tmovie.core.ui.ListRoute
import com.thientech.tmovie.core.ui.bleed
import com.thientech.tmovie.core.ui.Pager
import com.thientech.tmovie.core.ui.PlayFilmButton
import com.thientech.tmovie.core.ui.PosterCard
import com.thientech.tmovie.core.ui.RailHeader
import com.thientech.tmovie.core.ui.SaveButton
import com.thientech.tmovie.core.ui.SaveStyle
import com.thientech.tmovie.core.ui.Shelf
import com.thientech.tmovie.core.ui.fullSpan
import com.thientech.tmovie.core.ui.posterItems
import com.thientech.tmovie.core.ui.rememberNavigator
import com.thientech.tmovie.core.ui.route
import com.thientech.tmovie.core.ui.sharedFilm
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

/**
 * Netflix-style category page for a type list, genre or country: pills, a featured card, shelves
 * sliced by country (or by genre on a country page), then an endless filtered grid.
 */
@Composable
fun CatalogScreen(route: ListRoute) {
    val context = LocalContext.current
    val nav = rememberNavigator()
    val scope = rememberCoroutineScope()
    val pager = remember(route) { Pager(route.source) }
    var shelves by remember(route) { mutableStateOf<List<Pair<String, List<FilmItem>>>>(emptyList()) }
    var tint by remember { mutableStateOf(TMovieColors.Brand) }
    val featured = pager.items.firstOrNull()
    val wash by animateColorAsState(tint.copy(alpha = 0.4f), tween(800), label = "wash")

    LaunchedEffect(route) {
        if (pager.items.isEmpty()) pager.loadMore()
        shelves = loadShelves(route)
    }
    LaunchedEffect(featured?.slug) { tint = ColorSampler.tint(context, featured?.thumbImage) ?: TMovieColors.Brand }

    LazyVerticalGrid(
        GridCells.Fixed(3),
        Modifier.fillMaxSize().background(Brush.verticalGradient(0f to wash, 0.5f to TMovieColors.Canvas)),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 120.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        fullSpan("top") {
            Column(Modifier.statusBarsPadding(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(40.dp).clip(CircleShape).glass(CircleShape).clickable { nav.back() }, contentAlignment = Alignment.Center) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Quay lại", tint = Color.White)
                    }
                    androidx.compose.foundation.layout.Spacer(Modifier.weight(1f))
                    FilterButton(pager, route.source) { scope.launch { pager.loadMore() } }
                }
                Text(route.title, style = TMovieType.Title, color = Color.White)
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Pill(route.title, { nav.back() }) { Icon(Icons.Filled.Close, "Đóng", tint = Color.White, modifier = Modifier.size(16.dp)) }
                    GenrePickerPill(selected = route.slug.takeIf { route.kind == "genre" })
                    GenrePickerPill(selected = route.slug.takeIf { route.kind == "country" }, kind = PhimApi.Taxonomy.Countries)
                }
            }
        }
        if (featured != null) fullSpan("featured") { FeaturedCard(featured, tint) }
        shelves.forEach { (title, films) ->
            fullSpan("shelf/$title") {
                Box(Modifier.bleed(16.dp)) {
                    Shelf(title) { items(films, key = { it.slug }) { PosterCard(it, "${route.title}/$title/${it.slug}") } }
                }
            }
        }
        fullSpan("all") { Box(Modifier.bleed(16.dp)) { RailHeader("Tất cả") } }
        posterItems(pager, "catalog/${route.title}") { scope.launch { pager.loadMore() } }
        if (pager.items.isEmpty() && !pager.loading && pager.filter != Filter()) fullSpan("empty") {
            Text("Không có phim · thử bỏ bớt bộ lọc", color = TMovieColors.Secondary, textAlign = TextAlign.Center, modifier = Modifier.padding(32.dp))
        }
    }
}

/** Country slices for a type/genre page; genre slices for a country page. Shelves under 4 films are dropped. */
private suspend fun loadShelves(route: ListRoute): List<Pair<String, List<FilmItem>>> = coroutineScope {
    val slices = if (route.kind == "country") {
        listOf("Hành động" to Filter(category = "hanh-dong"), "Tình cảm" to Filter(category = "tinh-cam"),
            "Cổ trang" to Filter(category = "co-trang"), "Hài hước" to Filter(category = "hai-huoc"), "Kinh dị" to Filter(category = "kinh-di"))
    } else {
        listOf("Hàn Quốc" to Filter(country = "han-quoc"), "Trung Quốc" to Filter(country = "trung-quoc"), "Âu Mỹ" to Filter(country = "au-my"),
            "Nhật Bản" to Filter(country = "nhat-ban"), "Thái Lan" to Filter(country = "thai-lan"), "Việt Nam" to Filter(country = "viet-nam"))
    }
    slices.map { (title, filter) ->
        async { title to runCatching { PhimApi.shared.list(route.source, 1, filter).items }.getOrDefault(emptyList()) }
    }.awaitAll().filter { it.second.size >= 4 }
}

/** Big poster card at the top of a category, Netflix style. */
@Composable
private fun FeaturedCard(film: FilmItem, tint: Color) {
    val nav = rememberNavigator()
    val sourceId = "featured/${film.slug}"
    Box(
        Modifier
            .padding(horizontal = 8.dp)
            .fillMaxWidth()
            .aspectRatio(0.78f)
            .sharedFilm(sourceId)
            .clip(HeroShape)
            .border(1.dp, Color.White.copy(alpha = 0.15f), HeroShape)
            .clickable { nav.openFilm(film.route(sourceId)) },
    ) {
        RemoteImage(film.thumbImage, Modifier.fillMaxSize(), film.name)
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.4f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.9f))))
        Column(
            Modifier.align(Alignment.BottomCenter).padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(film.name, style = TMovieType.Title, color = Color.White, textAlign = TextAlign.Center, maxLines = 2)
            Text(film.genreLine(), color = Color.White.copy(alpha = 0.85f), fontSize = 13.sp)
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                PlayFilmButton(film, capsule = false, modifier = Modifier.weight(1f))
                SaveButton(film, SaveStyle.Wide, Modifier.weight(1f))
            }
        }
    }
}
