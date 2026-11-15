package com.thientech.tmovie.feature.home

import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import com.thientech.tmovie.core.ui.route
import com.thientech.tmovie.core.ui.RailHeader
import com.thientech.tmovie.core.designsystem.RemoteImage
import androidx.compose.ui.zIndex
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.clickable
import androidx.compose.foundation.border
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.Spring
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
                    Shelf("Xem tiếp", spacing = 14.dp) { items(history.take(15), key = { it.film.slug }) { ContinueCard(it) } }
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

/**
 * "Top 10" as a deck of cards fanned across the width, the rank printed on each poster. Swiping
 * left pulls the top card out and tucks it under the deck; swiping right pulls the bottom one back
 * on top. Endless: after 10 comes 1. Tapping the top card opens the film, a card behind brings it up.
 */
@Composable
private fun Top10Shelf(vm: HomeViewModel) {
    val films = vm.top10
    val n = films.size
    val nav = rememberNavigator()
    val scope = rememberCoroutineScope()
    val haptics = LocalHapticFeedback.current
    var top by remember { mutableIntStateOf(0) }
    // The card on its way out (or back in), drawn at the side for the first half of the move.
    var moving by remember { mutableStateOf<Int?>(null) }
    var movingOnTop by remember { mutableStateOf(true) }
    var drag by remember { mutableFloatStateOf(0f) }
    fun step(dir: Int) {
        if (n < 2 || moving != null) return
        val next = (top + dir + n) % n
        movingOnTop = dir > 0
        moving = if (dir > 0) top else next
        top = next
        haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
        scope.launch { delay(260); movingOnTop = !movingOnTop; moving = null }
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        RailHeader("Top 10 phim bộ tuần này", ListRoute.type("Phim bộ", "phim-bo"))
        Box(
            Modifier.fillMaxWidth().height(262.dp).clipToBounds()
                .pointerInput(n) {
                    detectHorizontalDragGestures(
                        onDragEnd = { if (drag < -40.dp.toPx()) step(1) else if (drag > 40.dp.toPx()) step(-1); drag = 0f },
                        onDragCancel = { drag = 0f },
                    ) { _, dx -> drag += dx }
                },
        ) {
            films.forEachIndexed { i, film ->
                val k = (i - top + n) % n
                val v = minOf(k, 4).toFloat()
                val isMoving = moving == i
                val spec = spring<Float>(dampingRatio = if (isMoving) 0.9f else 0.82f, stiffness = Spring.StiffnessMediumLow)
                val x by animateFloatAsState(if (isMoving) -150f else 18f + v * 64f, spec, label = "x")
                val y by animateFloatAsState(if (isMoving) -6f else v * 7f, spec, label = "y")
                val scale by animateFloatAsState(if (isMoving) 0.96f else 1f - v * 0.075f, spec, label = "s")
                val rot by animateFloatAsState(if (isMoving) -12f else 0f, spec, label = "r")
                val alpha by animateFloatAsState(if (k > 4 && !isMoving) 0f else 1f, label = "a")
                Box(
                    Modifier
                        .zIndex(if (isMoving) (if (movingOnTop) 40f else -1f) else 20f - k)
                        .offset(x = x.dp + if (k == 0) (drag * 0.6f / LocalDensity.current.density).dp else 0.dp, y = y.dp)
                        .graphicsLayer {
                            scaleX = scale; scaleY = scale; rotationZ = rot; this.alpha = alpha
                            transformOrigin = TransformOrigin(0f, 1f)
                        }
                        .size(162.dp, 243.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .border(1.dp, Color.White.copy(alpha = 0.16f), RoundedCornerShape(18.dp))
                        .clickable(enabled = k <= 4) {
                            if (k == 0) nav.openFilm(film.route("top10/${film.slug}")) else top = i
                        },
                ) {
                    RemoteImage(film.posterImage, Modifier.fillMaxSize(), film.name)
                    Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.55f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.75f))))
                    Text(
                        "${i + 1}",
                        style = TextStyle(
                            fontSize = 64.sp, fontWeight = FontWeight.Black, letterSpacing = (-3).sp,
                            brush = medal(i + 1), shadow = Shadow(Color.Black.copy(alpha = 0.6f), blurRadius = 20f),
                        ),
                        modifier = Modifier.align(Alignment.BottomStart).padding(start = 10.dp).offset(y = 12.dp),
                    )
                    film.episodeCurrent?.takeIf { it.isNotBlank() && !it.equals("full", true) }?.let {
                        Text(
                            it.replace("Hoàn Tất", "Trọn bộ"), color = Color.White, fontSize = 10.sp, fontWeight = FontWeight.Bold, maxLines = 1,
                            modifier = Modifier.background(TMovieColors.Brand, RoundedCornerShape(bottomEnd = 9.dp)).padding(horizontal = 7.dp, vertical = 3.dp),
                        )
                    }
                    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = minOf(0.5f, v * 0.13f))))
                }
            }
        }
    }
}

private fun medal(rank: Int): Brush = when (rank) {
    1 -> Brush.verticalGradient(listOf(Color(0xFFFFF3CC), Color(0xFFF0B84D)))
    2 -> Brush.verticalGradient(listOf(Color.White, Color(0xFFB9C2CC)))
    3 -> Brush.verticalGradient(listOf(Color(0xFFFFE0BF), Color(0xFFD08A4C)))
    else -> SolidColor(Color.White)
}
