package com.thientech.tmovie.tv

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.feature.home.HomeViewModel
import com.thientech.tmovie.feature.home.homeRails
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Home, Google TV style: the focused film fills the top (key art, title, details) and rows of
 * cards scroll underneath, each row pinned to the same line as focus moves down.
 */
@Composable
fun HomeTab(onOpen: (FilmItem) -> Unit) {
    val vm: HomeViewModel = viewModel()
    val history by Library.history.collectAsStateWithLifecycle()
    val saved by Library.saved.collectAsStateWithLifecycle()
    var focusedFilm by remember { mutableStateOf<FilmItem?>(null) }
    // Hold the header still while focus races along a row; settle on where it stops.
    var featured by remember { mutableStateOf<FilmItem?>(null) }
    LaunchedEffect(focusedFilm) {
        if (featured != null) delay(280)
        featured = focusedFilm
    }
    val shown = featured ?: vm.hero.firstOrNull()
    val first = remember { FocusRequester() }
    var started by rememberSaveable { mutableStateOf(false) }
    val rows = rememberLazyListState()
    // Rails often land before the first row; once it's in, start at the top with its first card focused.
    val ready = history.isNotEmpty() || vm.hero.isNotEmpty()
    LaunchedEffect(ready) {
        if (started || !ready) return@LaunchedEffect
        rows.scrollToItem(0)
        // The card attaches a frame or two later; try until it takes focus.
        repeat(30) {
            withFrameNanos {}
            if (runCatching { first.requestFocus() }.isSuccess) { started = true; return@LaunchedEffect }
        }
    }

    BoxWithConstraints(Modifier.fillMaxSize()) {
        Crossfade(shown?.let { vm.heroArt[it.slug] ?: it.thumbImage }, animationSpec = tween(450), label = "art") { Backdrop(it) }
        shown?.let { Header(it, Modifier.padding(start = Tv.Start, top = 40.dp).width(maxWidth * 0.5f)) }

        if (vm.hero.isEmpty() && vm.rails.isEmpty()) {
            if (vm.failed) Text("Không tải được, kiểm tra mạng rồi mở lại app.", color = TMovieColors.Secondary, fontSize = 18.sp, modifier = Modifier.align(Alignment.Center))
            else CircularProgressIndicator(Modifier.align(Alignment.Center), color = TMovieColors.BrandLight)
            return@BoxWithConstraints
        }

        val focus = { f: FilmItem -> { focusedFilm = f } }
        // Rows live in the lower half and scroll out under its top edge: the focused row always
        // sits right at that edge.
        val scope = rememberCoroutineScope()
        val pin = { i: Int -> { scope.launch { rows.animateScrollToItem(i) }; Unit } }
        NoAutoScroll {
            LazyColumn(
                Modifier.fillMaxSize().padding(top = maxHeight * 0.47f),
                state = rows,
                contentPadding = PaddingValues(bottom = maxHeight * 0.3f),
            ) {
                var n = 0
                // Focus starts on the first card of the first row: "Xem tiếp" when there is one.
                if (history.isNotEmpty()) n++.let { i -> item("continue") {
                    Shelf("Xem tiếp", history.take(20), { it.film.slug }, pin(i)) { r ->
                        if (r == history.first()) ContinueCard(r, { onOpen(r.film) }, focus(r.film), first) else ContinueCard(r, { onOpen(r.film) }, focus(r.film))
                    }
                } }
                if (vm.hero.isNotEmpty()) n++.let { i -> item("hot") {
                    Shelf("Đang hot tại Việt Nam", vm.hero, { it.slug }, pin(i)) { f ->
                        if (history.isEmpty() && f == vm.hero.first()) PosterCard(f, { onOpen(f) }, focus(f), first) else PosterCard(f, { onOpen(f) }, focus(f))
                    }
                } }
                if (vm.top10.isNotEmpty()) n++.let { i -> item("series") {
                    Shelf("Phim bộ hot", vm.top10, { it.slug }, pin(i)) { f -> PosterCard(f, { onOpen(f) }, focus(f)) }
                } }
                if (saved.isNotEmpty()) n++.let { i -> item("saved") {
                    Shelf("Danh sách của tôi", saved.map { it.film }, { it.slug }, pin(i)) { f -> PosterCard(f, { onOpen(f) }, focus(f)) }
                } }
                homeRails.forEach { rail ->
                    val films = vm.rails[rail].orEmpty()
                    if (films.isNotEmpty()) n++.let { i -> item(rail.title) {
                        Shelf(rail.title, films, { it.slug }, pin(i)) { f -> PosterCard(f, { onOpen(f) }, focus(f)) }
                    } }
                }
            }
        }
    }
}

@Composable
private fun Header(film: FilmItem, modifier: Modifier) {
    Column(modifier) {
        Text(film.name, style = TMovieType.Display.copy(fontSize = 44.sp, lineHeight = 50.sp), color = Color.White, maxLines = 2, overflow = TextOverflow.Ellipsis)
        film.originName?.takeIf { it.isNotBlank() && it != film.name }?.let {
            Text(it, color = TMovieColors.Secondary, fontSize = 18.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 6.dp))
        }
        Text(film.metaLine(), color = Color.White.copy(alpha = 0.85f), fontSize = 16.sp, fontWeight = FontWeight.Medium, maxLines = 1,
            overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 14.dp))
        film.rating?.let {
            Text("★ ${"%.1f".format(it)}", color = Color(0xFFFFD166), fontSize = 16.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 8.dp))
        }
    }
}
