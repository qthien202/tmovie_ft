package com.thientech.tmovie.feature.browse

import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.PlayCircleOutline
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.SectionTitle
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmCategory
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.ui.ListRoute
import com.thientech.tmovie.core.ui.Pager
import com.thientech.tmovie.core.ui.bleed
import com.thientech.tmovie.core.ui.fullSpan
import com.thientech.tmovie.core.ui.posterItems
import com.thientech.tmovie.core.ui.rememberNavigator
import com.thientech.tmovie.core.ui.route
import com.thientech.tmovie.core.ui.sharedFilm
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Search with debounced results, plus genre chips and "Tìm kiếm hàng đầu" when idle. */
@Composable
fun SearchScreen() {
    val nav = rememberNavigator()
    val scope = rememberCoroutineScope()
    var query by rememberSaveable { mutableStateOf("") }
    val pager = remember { Pager(Source.Search("")) }
    var trending by remember { mutableStateOf<List<FilmItem>>(emptyList()) }
    var genres by remember { mutableStateOf<List<FilmCategory>>(emptyList()) }
    val trimmed = query.trim()

    LaunchedEffect(Unit) {
        trending = runCatching { PhimApi.shared.list(Source.Type("phim-moi-cap-nhat")).items }.getOrDefault(emptyList())
        genres = runCatching { PhimApi.shared.taxonomy(PhimApi.Taxonomy.Genres) }.getOrDefault(emptyList())
    }
    LaunchedEffect(trimmed) {
        if (trimmed.length < 2) return@LaunchedEffect
        delay(400)  // debounce typing
        pager.update(source = Source.Search(trimmed))
        pager.loadMore()
    }

    LazyVerticalGrid(
        GridCells.Fixed(3),
        Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 120.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        fullSpan("field") {
            Column(Modifier.statusBarsPadding().padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Tìm kiếm", style = TMovieType.Title, color = Color.White)
                TextField(
                    query,
                    { query = it },
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)),
                    placeholder = { Text("Phim, diễn viên, tên gốc…") },
                    leadingIcon = { Icon(Icons.Filled.Search, null) },
                    trailingIcon = { if (query.isNotEmpty()) IconButton({ query = "" }) { Icon(Icons.Filled.Close, "Xoá") } },
                    singleLine = true,
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = Color.White.copy(alpha = 0.10f),
                        unfocusedContainerColor = Color.White.copy(alpha = 0.10f),
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                    ),
                )
            }
        }
        if (trimmed.length >= 2) {
            posterItems(pager, "search") { scope.launch { pager.loadMore() } }
            if (pager.items.isEmpty() && !pager.loading && !pager.failed) fullSpan("none") {
                Text("Không tìm thấy “$trimmed”", color = TMovieColors.Secondary, modifier = Modifier.padding(24.dp))
            }
        } else {
            if (genres.isNotEmpty()) fullSpan("genres") {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    SectionTitle("Khám phá thể loại")
                    // Two staggered rows of chips, filled alternately.
                    Column(Modifier.bleed(16.dp).horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        (0..1).forEach { row ->
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                genres.filterIndexed { i, _ -> i % 2 == row }.forEach { g ->
                                    Box(
                                        Modifier.height(40.dp).clip(RoundedCornerShape(10.dp)).glass(RoundedCornerShape(10.dp))
                                            .clickable { nav.openList(ListRoute.genre(g.name.orEmpty(), g.slug.orEmpty())) }.padding(horizontal = 16.dp),
                                        contentAlignment = Alignment.Center,
                                    ) { Text(g.name.orEmpty(), color = Color.White, fontWeight = FontWeight.SemiBold) }
                                }
                            }
                        }
                    }
                }
            }
            fullSpan("topTitle") { SectionTitle("Tìm kiếm hàng đầu", Modifier.padding(top = 8.dp)) }
            trending.forEach { film ->
                fullSpan("top/${film.slug}") {
                    val sourceId = "top-search/${film.slug}"
                    Row(Modifier.fillMaxWidth().clickable { nav.openFilm(film.route(sourceId)) }, verticalAlignment = Alignment.CenterVertically) {
                        RemoteImage(film.thumbImage, Modifier.width(140.dp).height(78.dp).sharedFilm(sourceId).clip(RoundedCornerShape(6.dp)))
                        Text(film.name, color = Color.White, fontSize = 15.sp, maxLines = 2, modifier = Modifier.weight(1f).padding(horizontal = 12.dp))
                        Icon(Icons.Filled.PlayCircleOutline, null, tint = Color.White)
                    }
                }
            }
        }
    }
}
