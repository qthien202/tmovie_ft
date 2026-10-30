package com.thientech.tmovie.tv

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.KeyboardArrowDown
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.FilmCategory
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.Filter
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import java.time.Year

private val kinds = listOf("phim-moi-cap-nhat" to "Tất cả phim", "phim-bo" to "Phim bộ", "phim-le" to "Phim lẻ", "hoat-hinh" to "Hoạt hình", "tv-shows" to "TV Shows")

private enum class Facet(val label: String) { Kind("Loại phim"), Genre("Thể loại"), Country("Quốc gia"), Year("Năm") }

/**
 * Browse everything by kind, genre, country and year (Netflix's genre menus): a row of
 * dropdown pills over the grid; each opens a full-screen list, Back or a pick closes it.
 */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun BrowseTab(onOpen: (FilmItem) -> Unit) {
    var kind by rememberSaveable { mutableStateOf(kinds[0].first) }
    var genre by rememberSaveable { mutableStateOf<String?>(null) }
    var country by rememberSaveable { mutableStateOf<String?>(null) }
    var year by rememberSaveable { mutableStateOf<Int?>(null) }
    var genres by remember { mutableStateOf(emptyList<FilmCategory>()) }
    var countries by remember { mutableStateOf(emptyList<FilmCategory>()) }
    LaunchedEffect(Unit) {
        genres = runCatching { PhimApi.shared.taxonomy(PhimApi.Taxonomy.Genres) }.getOrDefault(emptyList())
        countries = runCatching { PhimApi.shared.taxonomy(PhimApi.Taxonomy.Countries) }.getOrDefault(emptyList())
    }
    var picking by remember { mutableStateOf<Facet?>(null) }
    // Focus goes back to the pill once the picker has left the tree.
    var returnTo by remember { mutableStateOf<Facet?>(null) }
    val pills = remember { Facet.entries.associateWith { FocusRequester() } }
    val filtered = kind != kinds[0].first || genre != null || country != null || year != null
    LaunchedEffect(returnTo) {
        val f = returnTo ?: return@LaunchedEffect
        withFrameNanos {}; withFrameNanos {}
        runCatching { pills.getValue(f).requestFocus() }
        returnTo = null
    }

    fun options(f: Facet): List<Pair<Any?, String>> = when (f) {
        Facet.Kind -> kinds
        Facet.Genre -> listOf(null to "Tất cả thể loại") + genres.map { it.slug to it.name.orEmpty() }
        Facet.Country -> listOf(null to "Tất cả quốc gia") + countries.map { it.slug to it.name.orEmpty() }
        Facet.Year -> listOf(null to "Mọi năm") + (Year.now().value downTo 1990).map { it to "$it" }
    }
    fun value(f: Facet): Any? = when (f) { Facet.Kind -> kind; Facet.Genre -> genre; Facet.Country -> country; Facet.Year -> year }

    Column(Modifier.fillMaxSize().padding(top = 36.dp)) {
        Row(
            Modifier.padding(start = Tv.Start, end = Tv.End).focusRestorer(pills.getValue(Facet.Kind)),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Facet.entries.forEach { f ->
                val v = value(f)
                val label = if (v == null) f.label else options(f).firstOrNull { it.first == v }?.second ?: "$v"
                Chip(label, { picking = f }, selected = v != null && !(f == Facet.Kind && v == kinds[0].first), focusRequester = pills.getValue(f)) { fg ->
                    Icon(Icons.Rounded.KeyboardArrowDown, null, tint = fg, modifier = Modifier.size(22.dp))
                }
            }
            if (filtered) RoundButton({ kind = kinds[0].first; genre = null; country = null; year = null; returnTo = Facet.Kind }) { fg ->
                Icon(Icons.Rounded.Close, "Bỏ lọc", tint = fg, modifier = Modifier.size(24.dp))
            }
        }
        // A new filter is a new list: fresh paging and scroll.
        key(kind, genre, country, year) { FilmGrid(Source.Type(kind), Filter(category = genre, country = country, year = year), onOpen) }
    }

    picking?.let { f ->
        val close = { picking = null; returnTo = f }
        Picker(f.label, options(f), value(f), onDismiss = close) { picked ->
            when (f) {
                Facet.Kind -> kind = picked as String
                Facet.Genre -> genre = picked as String?
                Facet.Country -> country = picked as String?
                Facet.Year -> year = picked as Int?
            }
            close()
        }
    }
}

/** Full-screen choice list over a dimmed screen; focus starts on the current choice and stays inside. */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
private fun Picker(title: String, options: List<Pair<Any?, String>>, selected: Any?, onDismiss: () -> Unit, onPick: (Any?) -> Unit) {
    BackOverride(onDismiss)
    val at = options.indexOfFirst { it.first == selected }.coerceAtLeast(0)
    val list = rememberLazyListState((at - 3).coerceAtLeast(0))
    val start = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        repeat(30) { withFrameNanos {}; if (runCatching { start.requestFocus() }.isSuccess) return@LaunchedEffect }
    }
    Box(
        Modifier
            .fillMaxSize()
            .background(TMovieColors.Canvas.copy(alpha = 0.95f))
            .focusProperties { exit = { FocusRequester.Cancel } }
            .focusGroup(),
    ) {
        Text(title, color = TMovieColors.Secondary, fontSize = 20.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(start = Tv.Start, top = 40.dp))
        LazyColumn(
            Modifier.align(Alignment.Center).width(460.dp).fillMaxSize(),
            list,
            contentPadding = PaddingValues(vertical = 160.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            itemsIndexed(options, { _, o -> o.first ?: "all" }) { i, (v, label) ->
                PickerItem(label, v == selected, if (i == at) start else remember { FocusRequester() }) { onPick(v) }
            }
        }
    }
}

@Composable
private fun PickerItem(label: String, selected: Boolean, focus: FocusRequester, onClick: () -> Unit) {
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    Row(
        Modifier
            .fillMaxWidth()
            .height(56.dp)
            .focusRequester(focus)
            .clickable(interaction, indication = null, onClick = onClick)
            .graphicsLayer { val s = if (focused) 1.15f else 1f; scaleX = s; scaleY = s },
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            label,
            color = when { focused -> Color.White; selected -> TMovieColors.BrandLight; else -> Color.White.copy(alpha = 0.5f) },
            fontSize = 24.sp, fontWeight = if (focused || selected) FontWeight.Bold else FontWeight.Medium, maxLines = 1,
        )
        if (selected) Icon(Icons.Rounded.Check, null, tint = if (focused) Color.White else TMovieColors.BrandLight, modifier = Modifier.padding(start = 10.dp).size(24.dp))
    }
}
