package com.thientech.tmovie.tv

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.BringIntoViewSpec
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.thientech.tmovie.core.data.WatchRecord
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.FilmItem

/**
 * 10-foot layout (Netflix / Apple TV): overscan-safe margins, content past the collapsed nav,
 * landscape cards with titles underneath.
 *
 * Kept cheap for low-end TV boxes: focus is a scale + white ring on a graphics layer (no
 * shadows, blurs or animated backdrops), and images load at card size.
 */
object Tv {
    /** How far a Top 10 rank number reaches left of its poster. */
    val RankWidth = 74.dp
    val Start = 104.dp
    val End = 48.dp
    val CardWidth = 216.dp
    val PosterWidth = 132.dp
    /** Room above and below a row's cards for the focus scale. */
    val RowBleed = 14.dp
    /** The icon's play mark split: cyan, lavender, pink (banner and wordmark). */
    val LogoColors = listOf(Color(0xFF5EDBD7), Color(0xFFA595F0), Color(0xFFEF7CBB))
    val Title = TextStyle(fontWeight = FontWeight.ExtraBold, fontSize = 50.sp, lineHeight = 54.sp, letterSpacing = (-0.5).sp)
}

/** The focused card of each open page, so closing a page puts focus back where it was. */
class FocusMemory { var last: FocusRequester? = null }

val LocalFocusMemory = staticCompositionLocalOf { FocusMemory() }

/** The one focusable surface: grows and rings white while focused. OK on the remote clicks it. */
@Composable
fun FocusCard(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(10.dp),
    scale: Float = 1.1f,
    focusRequester: FocusRequester = remember { FocusRequester() },
    onFocusChange: (Boolean) -> Unit = {},
    content: @Composable BoxScope.(focused: Boolean) -> Unit,
) {
    val memory = LocalFocusMemory.current
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    val s by animateFloatAsState(if (focused) scale else 1f, spring(dampingRatio = 0.8f, stiffness = 700f), label = "focus")
    Box(
        modifier
            .zIndex(if (focused) 1f else 0f)
            .graphicsLayer { scaleX = s; scaleY = s }
            .clip(shape)
            .background(TMovieColors.Surface)
            .then(if (focused) Modifier.border(3.dp, Color.White, shape) else Modifier)
            .focusRequester(focusRequester)
            .onFocusChanged { onFocusChange(it.isFocused) }
            .clickable(interaction, indication = null) { memory.last = focusRequester; onClick() },
    ) { content(focused) }
}

/** White-when-focused capsule for buttons and filter chips; [selected] marks the active choice. */
@Composable
fun Chip(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    selected: Boolean = false,
    focusRequester: FocusRequester = remember { FocusRequester() },
    leading: (@Composable (Color) -> Unit)? = null,
) {
    FocusCard(onClick, modifier, CircleShape, scale = 1.06f, focusRequester = focusRequester) { focused ->
        val fg = when {
            focused -> Color.Black
            selected -> TMovieColors.BrandLight
            else -> Color.White
        }
        Row(
            Modifier
                .background(if (focused) Color.White else if (selected) TMovieColors.Brand.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.1f))
                .height(46.dp)
                .padding(horizontal = 22.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            leading?.invoke(fg)
            Text(text, color = fg, fontSize = 18.sp, fontWeight = if (selected || focused) FontWeight.Bold else FontWeight.Medium, maxLines = 1)
        }
    }
}

/** Round icon button (Apple TV "+" next to Play). */
@Composable
fun RoundButton(onClick: () -> Unit, content: @Composable (Color) -> Unit) {
    FocusCard(onClick, Modifier.size(52.dp), CircleShape, scale = 1.1f) { focused ->
        Box(Modifier.fillMaxSize().background(if (focused) Color.White else Color.White.copy(alpha = 0.16f)), Alignment.Center) {
            content(if (focused) Color.Black else Color.White)
        }
    }
}

/**
 * Lists that scroll with focus keep the focused item at a fixed line ([leading] from the start)
 * instead of creeping to the edge: rows hold their column.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun Pivot(leading: Dp, content: @Composable () -> Unit) {
    val px = with(LocalDensity.current) { leading.toPx() }
    val spec = remember(px) {
        object : BringIntoViewSpec {
            override fun calculateScrollDistance(offset: Float, size: Float, containerSize: Float) = offset - px
        }
    }
    CompositionLocalProvider(LocalBringIntoViewSpec provides spec, content = content)
}

/** Turns off focus-driven scrolling, for a list that scrolls itself to the focused row. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun NoAutoScroll(content: @Composable () -> Unit) {
    val spec = remember {
        object : BringIntoViewSpec {
            override fun calculateScrollDistance(offset: Float, size: Float, containerSize: Float) = 0f
        }
    }
    CompositionLocalProvider(LocalBringIntoViewSpec provides spec, content = content)
}

/** A titled row; coming back to it lands on the card that was focused last. */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
/** [pivot]: where the focused card is held (Top 10 holds its poster past the rank number). */
fun <T> Shelf(title: String, items: List<T>, key: (T) -> Any, onFocused: () -> Unit = {}, onMore: (() -> Unit)? = null, pivot: Dp = Tv.Start, item: @Composable (T) -> Unit) {
    Column(Modifier.fillMaxWidth().padding(top = 22.dp).onFocusChanged { if (it.hasFocus) onFocused() }) {
        Text(title, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = Tv.Start))
        Pivot(pivot) {
            LazyRow(
                Modifier.focusRestorer(),
                contentPadding = PaddingValues(start = Tv.Start, end = Tv.End, top = Tv.RowBleed, bottom = Tv.RowBleed),
                horizontalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                items(items, key) { item(it) }
                onMore?.let { more -> item("more") { MoreCard(more) } }
            }
        }
    }
}

/** A card with its title underneath (Apple TV); the title brightens with focus. */
@Composable
private fun Captioned(modifier: Modifier, title: String, subtitle: String?, card: @Composable (onFocusChange: (Boolean) -> Unit) -> Unit) {
    var focused by remember { mutableStateOf(false) }
    Column(modifier.zIndex(if (focused) 1f else 0f)) {
        card { focused = it }
        Text(title, color = if (focused) Color.White else Color.White.copy(alpha = 0.75f), fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
            maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 14.dp))
        if (subtitle != null) Text(subtitle, color = TMovieColors.Secondary, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

/** Landscape still + title: the default card everywhere. */
@Composable
fun WideCard(film: FilmItem, onClick: () -> Unit, modifier: Modifier = Modifier.width(Tv.CardWidth), onFocus: () -> Unit = {}, focusRequester: FocusRequester = remember { FocusRequester() }) {
    Captioned(modifier, film.name, null) { report ->
        FocusCard(onClick, Modifier.fillMaxWidth().aspectRatio(16f / 9f), focusRequester = focusRequester, onFocusChange = { report(it); if (it) onFocus() }) {
            RemoteImage(film.thumbImage ?: film.posterImage, Modifier.fillMaxSize(), film.name)
        }
    }
}

/** "Xem tiếp": the still with a progress line, and how much is left. */
@Composable
fun ContinueCard(record: WatchRecord, onClick: () -> Unit, onFocus: () -> Unit = {}, focusRequester: FocusRequester = remember { FocusRequester() }) {
    val slug = record.lastEpisodeSlug
    val left = ((record.durations[slug] ?: 0.0) - (record.positions[slug] ?: 0.0)) / 60
    val sub = listOfNotNull(record.episodeName.ifBlank { null }, if (left >= 1) "còn ${left.toInt()} phút" else null).joinToString(" · ")
    Captioned(Modifier.width(Tv.CardWidth), record.film.name, sub.ifBlank { null }) { report ->
        FocusCard(onClick, Modifier.fillMaxWidth().aspectRatio(16f / 9f), focusRequester = focusRequester, onFocusChange = { report(it); if (it) onFocus() }) {
            RemoteImage(record.film.thumbImage, Modifier.fillMaxSize(), record.film.name)
            Box(Modifier.align(Alignment.BottomStart).padding(10.dp).fillMaxWidth().height(4.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.3f))) {
                Box(Modifier.fillMaxHeight().fillMaxWidth(record.lastProgress.coerceIn(0.02f, 1f)).background(TMovieColors.BrandLight))
            }
        }
    }
}

/** Netflix's Top 10: a big outlined rank beside the poster. */
@Composable
fun RankCard(rank: Int, film: FilmItem, onClick: () -> Unit, onFocus: () -> Unit = {}) {
    var focused by remember { mutableStateOf(false) }
    Box(Modifier.width(Tv.PosterWidth + Tv.RankWidth).zIndex(if (focused) 1f else 0f)) {
        Text(
            "$rank",
            style = TextStyle(fontSize = 150.sp, fontWeight = FontWeight.Black, lineHeight = 150.sp, letterSpacing = (-8).sp, drawStyle = Stroke(width = 5f)),
            color = if (focused) Color.White else Color(0xFF8A8F94),
            modifier = Modifier.align(Alignment.BottomStart).offset(y = 26.dp),
        )
        FocusCard(
            onClick, Modifier.align(Alignment.CenterEnd).width(Tv.PosterWidth).aspectRatio(2f / 3f),
            onFocusChange = { focused = it; if (it) onFocus() },
        ) { RemoteImage(film.posterImage ?: film.thumbImage, Modifier.fillMaxSize(), film.name) }
    }
}

@Composable
fun PosterCard(film: FilmItem, onClick: () -> Unit, onFocus: () -> Unit = {}, focusRequester: FocusRequester = remember { FocusRequester() }) {
    FocusCard(onClick, Modifier.width(Tv.PosterWidth).aspectRatio(2f / 3f), focusRequester = focusRequester, onFocusChange = { if (it) onFocus() }) {
        RemoteImage(film.posterImage ?: film.thumbImage, Modifier.fillMaxSize(), film.name)
    }
}

/** Last card of a row: opens the whole list. */
@Composable
fun MoreCard(onClick: () -> Unit) {
    Captioned(Modifier.width(Tv.CardWidth), "Xem tất cả", null) { report ->
        FocusCard(onClick, Modifier.fillMaxWidth().aspectRatio(16f / 9f), onFocusChange = report) { focused ->
            Box(Modifier.fillMaxSize().background(if (focused) Color.White else Color.White.copy(alpha = 0.08f)), Alignment.Center) {
                Icon(Icons.AutoMirrored.Rounded.ArrowForward, null, tint = if (focused) Color.Black else Color.White, modifier = Modifier.size(40.dp))
            }
        }
    }
}

/** Small outlined label: "FHD", "Vietsub". */
@Composable
fun Badge(text: String, modifier: Modifier = Modifier) {
    Text(
        text, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold, maxLines = 1,
        modifier = modifier.clip(RoundedCornerShape(4.dp)).background(Color.Black.copy(alpha = 0.55f)).border(1.dp, Color.White.copy(alpha = 0.5f), RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp),
    )
}

/** "2024 · Vietsub · Tập 12". */
fun FilmItem.metaLine(): String = listOfNotNull(year?.takeIf { it > 0 }?.toString(), lang, episodeCurrent).joinToString("  ·  ")

/** "Hành động · Tình cảm · Hàn Quốc". */
fun FilmItem.genreLine(): String = (category.orEmpty().take(3) + country.orEmpty().take(1)).mapNotNull { it.name }.joinToString("  ·  ")

/**
 * Full-bleed key art fading into the canvas on the left and bottom (Apple TV / Netflix billboard).
 * Static: nothing here animates, so it costs one image draw.
 */
@Composable
fun Backdrop(url: String?, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize()) {
        RemoteImage(url, Modifier.fillMaxSize())
        Box(Modifier.fillMaxSize().background(Brush.horizontalGradient(0f to TMovieColors.Canvas.copy(alpha = 0.92f), 0.45f to TMovieColors.Canvas.copy(alpha = 0.45f), 0.75f to Color.Transparent)))
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.45f to Color.Transparent, 1f to TMovieColors.Canvas)))
    }
}
