package com.thientech.tmovie.tv

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.player.Player
import com.thientech.tmovie.feature.home.HomeViewModel
import com.thientech.tmovie.feature.home.homeRails
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Home: a full-screen billboard of what's hot (Apple TV / Netflix) with Play, Info and My List,
 * then rows on the plain canvas. The focused row always sits at the top of the screen.
 */
@Composable
fun HomeTab(onOpen: (FilmItem) -> Unit, onList: (String, Source) -> Unit) {
    val vm: HomeViewModel = viewModel()
    val history by Library.history.collectAsStateWithLifecycle()
    val saved by Library.saved.collectAsStateWithLifecycle()
    val rows = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val pin = { i: Int -> { scope.launch { rows.animateScrollToItem(i) }; Unit } }
    val play = remember { FocusRequester() }
    var started by rememberSaveable { mutableStateOf(false) }

    // Start on the billboard's Play button once the hot list is in.
    LaunchedEffect(vm.hero.isNotEmpty()) {
        if (started || vm.hero.isEmpty()) return@LaunchedEffect
        rows.scrollToItem(0)
        repeat(30) {
            withFrameNanos {}
            if (runCatching { play.requestFocus() }.isSuccess) { started = true; return@LaunchedEffect }
        }
    }

    // The TV home screen's channel mirrors the billboard (same films, same art).
    val context = LocalContext.current
    LaunchedEffect(vm.hero, vm.heroArt.size) { Featured.publish(context, vm.hero, vm.heroArt.toMap()) }

    BoxWithConstraints(Modifier.fillMaxSize()) {
        if (vm.hero.isEmpty() && vm.rails.isEmpty()) {
            if (vm.failed) Text("Không tải được, kiểm tra mạng rồi mở lại app.", color = TMovieColors.Secondary, fontSize = 20.sp, modifier = Modifier.align(Alignment.Center))
            else CircularProgressIndicator(Modifier.align(Alignment.Center), color = TMovieColors.BrandLight)
            return@BoxWithConstraints
        }
        val height = maxHeight
        NoAutoScroll {
            LazyColumn(Modifier.fillMaxSize(), rows, contentPadding = PaddingValues(bottom = height * 0.6f)) {
                var n = 0
                if (vm.hero.isNotEmpty()) n++.let { i ->
                    item("billboard") {
                        Billboard(vm.hero, vm.heroArt, height * 0.86f, play, active = rows.firstVisibleItemIndex == 0, onOpen = onOpen, onFocused = pin(i))
                    }
                }
                if (history.isNotEmpty()) n++.let { i -> item("continue") {
                    Shelf("Xem tiếp", history.take(20), { it.film.slug }, pin(i)) { r -> ContinueCard(r, { onOpen(r.film) }) }
                } }
                if (vm.hero.isNotEmpty()) n++.let { i -> item("top") {
                    Shelf("Top 10 tại Việt Nam hôm nay", vm.hero.take(10).withIndex().toList(), { it.value.slug }, pin(i), pivot = Tv.Start + Tv.RankWidth) { (rank, f) ->
                        RankCard(rank + 1, f, { onOpen(f) })
                    }
                } }
                if (vm.top10.isNotEmpty()) n++.let { i -> item("series") {
                    Shelf("Phim bộ đang hot", vm.top10, { it.slug }, pin(i)) { f -> WideCard(f, { onOpen(f) }) }
                } }
                if (saved.isNotEmpty()) n++.let { i -> item("saved") {
                    Shelf("Danh sách của tôi", saved.map { it.film }, { it.slug }, pin(i)) { f -> WideCard(f, { onOpen(f) }) }
                } }
                homeRails.forEach { rail ->
                    val films = vm.rails[rail].orEmpty()
                    if (films.isNotEmpty()) n++.let { i -> item(rail.title) {
                        Shelf(rail.title, films, { it.slug }, pin(i), onMore = { onList(rail.title, rail.route.source) }) { f -> WideCard(f, { onOpen(f) }) }
                    } }
                }
            }
        }
    }
}

/**
 * The hot list one title at a time, changing every 12 s while on screen: textless key art,
 * a "TOP n" tag, title, details, a short synopsis and the actions.
 */
@Composable
private fun Billboard(
    films: List<FilmItem>,
    art: Map<String, String>,
    height: Dp,
    play: FocusRequester,
    active: Boolean,
    onOpen: (FilmItem) -> Unit,
    onFocused: () -> Unit,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var index by rememberSaveable { mutableIntStateOf(0) }
    val film = films[index % films.size]
    val saved by Library.saved.collectAsStateWithLifecycle()
    val isSaved = saved.any { it.film.slug == film.slug }
    // Synopses come from the detail endpoint; one request per title, kept while Home lives.
    val synopsis = remember { mutableStateMapOf<String, String>() }
    LaunchedEffect(film.slug) {
        if (film.slug !in synopsis) runCatching { PhimApi.shared.detail(film.slug) }.getOrNull()?.content?.let {
            synopsis[film.slug] = it.replace(Regex("<[^>]*>"), "").replace("&nbsp;", " ").trim()
        }
    }
    LaunchedEffect(index, active) {
        if (!active || films.size < 2) return@LaunchedEffect
        delay(12_000)
        index = (index + 1) % films.size
    }
    var starting by remember { mutableStateOf(false) }

    Box(Modifier.fillMaxWidth().height(height).onFocusChanged { if (it.hasFocus) onFocused() }) {
        Crossfade(film.slug, animationSpec = tween(600), label = "billboard") { slug ->
            Backdrop(art[slug] ?: films.firstOrNull { it.slug == slug }?.thumbImage)
        }
        Column(Modifier.align(Alignment.BottomStart).padding(start = Tv.Start, bottom = 48.dp).width(560.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("TOP\n10", color = Color.White, fontSize = 10.sp, lineHeight = 10.sp, fontWeight = FontWeight.Black,
                    modifier = Modifier.clip(RoundedCornerShape(3.dp)).background(Color(0xFFE50914)).padding(horizontal = 4.dp, vertical = 2.dp))
                Text("Top ${index % films.size + 1} tại Việt Nam hôm nay", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 10.dp))
            }
            Text(film.name, style = Tv.Title, color = Color.White, maxLines = 2, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 10.dp))
            Row(Modifier.padding(top = 12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                film.rating?.let { Text("★ ${"%.1f".format(it)}", color = Color(0xFFFFD166), fontSize = 17.sp, fontWeight = FontWeight.Bold) }
                Text(film.metaLine(), color = Color.White.copy(alpha = 0.9f), fontSize = 17.sp, fontWeight = FontWeight.Medium, maxLines = 1)
                film.quality?.takeIf { it.isNotBlank() }?.let { Badge(it) }
            }
            Text(film.genreLine(), color = TMovieColors.Secondary, fontSize = 16.sp, maxLines = 1, modifier = Modifier.padding(top = 6.dp))
            Text(synopsis[film.slug] ?: " ", color = Color.White.copy(alpha = 0.85f), fontSize = 17.sp, lineHeight = 25.sp, maxLines = 3,
                overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 14.dp).height(75.dp))
            Row(Modifier.padding(top = 20.dp), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
                Chip("Phát", {
                    if (!starting) scope.launch {
                        // Straight into playback, resuming where it was left.
                        starting = true
                        runCatching { PhimApi.shared.detail(film.slug) }.getOrNull()?.let { Player.start(context, it) }
                        starting = false
                    }
                }, focusRequester = play) { fg ->
                    if (starting) CircularProgressIndicator(Modifier.size(20.dp), color = fg, strokeWidth = 2.dp)
                    else Icon(Icons.Rounded.PlayArrow, null, tint = fg, modifier = Modifier.size(28.dp))
                }
                Chip("Thông tin", { onOpen(film) }) { fg -> Icon(Icons.Outlined.Info, null, tint = fg, modifier = Modifier.size(24.dp)) }
                RoundButton({ Library.toggleSaved(film) }) { fg ->
                    Icon(if (isSaved) Icons.Rounded.Check else Icons.Rounded.Add, if (isSaved) "Bỏ khỏi danh sách" else "Thêm vào danh sách", tint = fg, modifier = Modifier.size(26.dp))
                }
            }
        }
        // Which title of the hot list this is.
        Row(Modifier.align(Alignment.BottomEnd).padding(end = Tv.End, bottom = 60.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            films.indices.forEach { i ->
                Box(Modifier.size(if (i == index % films.size) 18.dp else 6.dp, 6.dp).clip(CircleShape)
                    .background(if (i == index % films.size) Color.White else Color.White.copy(alpha = 0.35f)))
            }
        }
    }
}
