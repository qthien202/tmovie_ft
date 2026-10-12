package com.thientech.tmovie.feature.home

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.ColorSampler
import com.thientech.tmovie.core.designsystem.Pill
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.Wordmark
import com.thientech.tmovie.core.ui.ContinueCard
import com.thientech.tmovie.core.ui.CountryShelf
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.ui.GenrePickerPill
import com.thientech.tmovie.core.ui.ListRoute
import com.thientech.tmovie.core.ui.PosterCard
import com.thientech.tmovie.core.ui.Shelf
import com.thientech.tmovie.core.ui.rememberNavigator

/**
 * Home: Apple TV-style hero tinted by its art, category pills, then Continue Watching,
 * My List, Top 10 and genre shelves over a colour wash from the hero.
 */
@Composable
fun HomeScreen(vm: HomeViewModel = viewModel()) {
    val context = LocalContext.current
    val history by Library.history.collectAsStateWithLifecycle()
    val saved by Library.saved.collectAsStateWithLifecycle()
    val pager = rememberPagerState { vm.hero.size }
    val list = rememberLazyListState()
    val heroFilm = vm.hero.getOrNull(pager.settledPage)
    val heroArt = heroFilm?.let { vm.heroArt[it.slug] ?: it.thumbImage }
    var tint by remember { mutableStateOf(TMovieColors.Brand) }
    LaunchedEffect(heroArt) { tint = ColorSampler.tint(context, heroArt) ?: TMovieColors.Brand }
    val wash by animateColorAsState(tint.copy(alpha = 0.35f), tween(800), label = "wash")

    PullToRefreshBox(isRefreshing = vm.refreshing, onRefresh = { vm.load(refresh = true) }, modifier = Modifier.fillMaxSize()) {
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0f to wash, 0.5f to TMovieColors.Canvas)).background(Color.Transparent)) {
            LazyColumn(state = list, contentPadding = PaddingValues(bottom = 120.dp), verticalArrangement = Arrangement.spacedBy(26.dp)) {
                item(key = "hero") {
                    if (vm.hero.isNotEmpty()) {
                        HeroPager(vm.hero, vm.heroArt, tint, pager) {
                            if (list.firstVisibleItemIndex == 0) list.firstVisibleItemScrollOffset.toFloat() else 0f
                        }
                    } else {
                        // Same height as the hero, so nothing jumps when it arrives.
                        Box(Modifier.fillMaxWidth().height((LocalConfiguration.current.screenHeightDp * 0.74f).dp).background(Color.White.copy(alpha = 0.04f)))
                    }
                }
                if (history.isNotEmpty()) item(key = "continue") {
                    Shelf("Xem tiếp") { items(history.take(15), key = { it.film.slug }) { ContinueCard(it) } }
                }
                if (saved.isNotEmpty()) item(key = "mylist") {
                    Shelf("Danh sách của tôi") { items(saved, key = { it.film.slug }) { PosterCard(it.film, "mylist/${it.film.slug}") } }
                }
                if (vm.top10.isNotEmpty()) item(key = "top10") { Top10Shelf(vm) }
                item(key = "countries") { CountryShelf() }
                homeRails.forEach { rail ->
                    val films = vm.rails[rail]
                    if (films == null || films.isNotEmpty()) item(key = rail.title) {
                        Shelf(rail.title, more = rail.route) {
                            if (films == null) items(5) { PosterPlaceholder() }
                            else items(films, key = { it.slug }) { PosterCard(it, "${rail.title}/${it.slug}") }
                        }
                    }
                }
                if (vm.failed) item(key = "failed") {
                    Column(Modifier.fillMaxWidth().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("Không tải được phim", color = Color.White)
                        Button(onClick = { vm.load() }, modifier = Modifier.padding(top = 12.dp)) { Text("Thử lại") }
                    }
                }
            }
            HomeHeader()
        }
    }
}

@Composable
private fun PosterPlaceholder() {
    Box(Modifier.width(112.dp).height(168.dp).clip(RoundedCornerShape(8.dp)).background(Color.White.copy(alpha = 0.06f)))
}

/** Wordmark plus category pills, over a fade so content scrolls under it. */
@Composable
private fun HomeHeader() {
    val nav = rememberNavigator()
    Column(
        Modifier
            .fillMaxWidth()
            .background(Brush.verticalGradient(listOf(Color.Black.copy(alpha = 0.85f), Color.Black.copy(alpha = 0.4f), Color.Transparent)))
            .statusBarsPadding()
            .padding(bottom = 10.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Wordmark(Modifier.padding(horizontal = 16.dp, vertical = 4.dp))
        Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            GenrePickerPill(kind = PhimApi.Taxonomy.Countries)
            GenrePickerPill()
            Pill("Phim bộ", { nav.openList(ListRoute.type("Phim bộ", "phim-bo")) })
            Pill("Phim lẻ", { nav.openList(ListRoute.type("Phim lẻ", "phim-le")) })
            Pill("TV Shows", { nav.openList(ListRoute.type("TV Shows", "tv-shows")) })
        }
    }
}

/** Netflix "Top 10": huge outlined rank numbers tucked behind each poster. */
@Composable
private fun Top10Shelf(vm: HomeViewModel) {
    Shelf("Top 10 phim bộ tuần này", more = ListRoute.type("Phim bộ", "phim-bo"), spacing = 4.dp) {
        itemsIndexed(vm.top10, key = { _, f -> "top10/${f.slug}" }) { i, film ->
            Row(verticalAlignment = Alignment.Bottom) {
                Text(
                    "${i + 1}",
                    style = TextStyle(fontSize = 120.sp, fontWeight = FontWeight.Black, drawStyle = Stroke(width = 5f)),
                    color = Color.White.copy(alpha = 0.85f),
                    modifier = Modifier.padding(bottom = 0.dp).width(if (i + 1 >= 10) 130.dp else 70.dp),
                )
                PosterCard(film, "top10/${film.slug}", Modifier.padding(start = 0.dp), width = 104.dp)
            }
        }
    }
}
