package com.thientech.tmovie.tv

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.player.Player
import com.thientech.tmovie.feature.browse.Channel
import com.thientech.tmovie.feature.browse.categoryName
import com.thientech.tmovie.feature.browse.countryName
import com.thientech.tmovie.feature.browse.loadChannels

/** "Truyền hình": iptv-org's channels, a country row (Việt Nam first), a category row, then the grid. */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun LiveTab() {
    val context = LocalContext.current
    val channels by produceState<List<Channel>?>(null) { value = runCatching { loadChannels() }.getOrDefault(emptyList()) }
    var country by rememberSaveable { mutableStateOf<String?>("vn") }
    var category by rememberSaveable { mutableStateOf<String?>(null) }
    val all = channels.orEmpty()
    val countries = remember(all) {
        all.mapNotNull { it.country }.groupingBy { it }.eachCount().entries
            .sortedWith(compareBy<Map.Entry<String, Int>> { it.key != "vn" }.thenByDescending { it.value }).map { it.key }
    }
    // Categories of the chosen country only, so every chip leads somewhere.
    val inCountry = remember(all, country) { all.filter { country == null || it.country == country } }
    val categories = remember(inCountry) { inCountry.flatMap { it.categories }.groupingBy { it }.eachCount().entries.sortedByDescending { it.value }.map { it.key } }
    val shown = remember(inCountry, category) { inCountry.filter { category == null || category in it.categories } }

    Column(Modifier.fillMaxSize().padding(top = 36.dp)) {
        Text("Truyền hình", color = Color.White, fontSize = 30.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = Tv.Start))
        Text(
            if (channels == null) "Đang tải danh sách kênh…" else "${shown.size} kênh",
            color = TMovieColors.Secondary, fontSize = 16.sp, modifier = Modifier.padding(start = Tv.Start, top = 4.dp, bottom = 8.dp),
        )
        if (channels == null) {
            Box(Modifier.fillMaxSize()) { CircularProgressIndicator(Modifier.align(Alignment.Center), color = TMovieColors.BrandLight) }
            return@Column
        }
        if (all.isEmpty()) {
            Text("Không tải được danh sách kênh", color = TMovieColors.Secondary, fontSize = 18.sp, modifier = Modifier.padding(start = Tv.Start, top = 24.dp))
            return@Column
        }
        ChipRow(listOf<String?>(null) + countries, country, { it?.let(::countryName) ?: "Tất cả quốc gia" }) { country = it; category = null }
        ChipRow(listOf<String?>(null) + categories, category, { it?.let(::categoryName) ?: "Tất cả thể loại" }) { category = it }
        LazyVerticalGrid(
            GridCells.Adaptive(200.dp),
            contentPadding = PaddingValues(start = Tv.Start, end = Tv.End, top = 12.dp, bottom = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            items(shown, { it.url + it.name }) { c ->
                FocusCard({ Player.live(context, c.name, c.url, c.userAgent, c.referrer) }, Modifier.fillMaxWidth().aspectRatio(16f / 10f)) { focused ->
                    Box(Modifier.fillMaxSize().background(if (focused) Color.White.copy(alpha = 0.14f) else Color.White.copy(alpha = 0.05f)))
                    if (c.logo != null) {
                        RemoteImage(c.logo, Modifier.align(Alignment.Center).fillMaxWidth(0.55f).aspectRatio(16f / 9f).padding(bottom = 18.dp), c.name, ContentScale.Fit)
                    }
                    Text(
                        c.name, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis,
                        textAlign = TextAlign.Center, modifier = Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp),
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalComposeUiApi::class)
@Composable
private fun ChipRow(options: List<String?>, selected: String?, label: (String?) -> String, onPick: (String?) -> Unit) {
    Pivot(Tv.Start) {
        LazyRow(
            Modifier.focusRestorer(),
            contentPadding = PaddingValues(start = Tv.Start, end = Tv.End, top = 8.dp, bottom = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) { items(options, { it ?: "" }) { o -> Chip(label(o), { onPick(o) }, selected = o == selected) } }
    }
}
