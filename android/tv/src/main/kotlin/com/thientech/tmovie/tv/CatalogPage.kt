package com.thientech.tmovie.tv

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source

/** A whole list ("Xem tất cả" on a row): a poster grid that loads the next page as focus nears the end. */
@Composable
fun CatalogPage(title: String, source: Source, onOpen: (FilmItem) -> Unit) {
    val films = remember { mutableStateListOf<FilmItem>() }
    var page by remember { mutableIntStateOf(0) }
    var hasMore by remember { mutableStateOf(true) }
    var loading by remember { mutableStateOf(false) }
    val grid = rememberLazyGridState()
    val first = remember { FocusRequester() }

    suspend fun loadMore() {
        if (loading || !hasMore) return
        loading = true
        runCatching { PhimApi.shared.list(source, page + 1) }
            .onSuccess { p -> films += p.items.filter { f -> films.none { it.slug == f.slug } }; page = p.currentPage; hasMore = p.hasMore }
            .onFailure { hasMore = false }
        loading = false
    }
    LaunchedEffect(Unit) {
        loadMore()
        repeat(30) {
            withFrameNanos {}
            if (runCatching { first.requestFocus() }.isSuccess) return@LaunchedEffect
        }
    }
    LaunchedEffect(grid) {
        snapshotFlow { (grid.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0) >= films.size - 14 }
            .collect { near -> if (near) loadMore() }
    }

    Column(Modifier.fillMaxSize().padding(top = 40.dp)) {
        Text(title, color = Color.White, fontSize = 30.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = Tv.Start))
        when {
            films.isEmpty() && loading -> Box(Modifier.fillMaxSize()) { CircularProgressIndicator(Modifier.align(Alignment.Center), color = TMovieColors.BrandLight) }
            films.isEmpty() -> Text("Không tải được danh sách", color = TMovieColors.Secondary, fontSize = 18.sp, modifier = Modifier.padding(start = Tv.Start, top = 24.dp))
            else -> LazyVerticalGrid(
                GridCells.Fixed(4),
                state = grid,
                contentPadding = PaddingValues(start = Tv.Start, end = Tv.End, top = 20.dp, bottom = 48.dp),
                horizontalArrangement = Arrangement.spacedBy(20.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                itemsIndexed(films, { _, f -> f.slug }) { i, f ->
                    if (i == 0) WideCard(f, { onOpen(f) }, Modifier.fillMaxWidth(), focusRequester = first) else WideCard(f, { onOpen(f) }, Modifier.fillMaxWidth())
                }
            }
        }
    }
}
