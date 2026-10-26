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
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.thientech.tmovie.core.data.WatchRecord
import com.thientech.tmovie.core.designsystem.ProgressStrip
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.FilmItem

/** 10-foot layout: overscan-safe margins, content starting past the collapsed side nav. */
object Tv {
    val Start = 104.dp
    val End = 48.dp
    val PosterWidth = 136.dp
    val WideWidth = 272.dp
    /** Room above and below a row's cards for the focus scale and glow. */
    val RowBleed = 14.dp
}

/** The focused card of each open page, so closing a page puts focus back where it was. */
class FocusMemory { var last: FocusRequester? = null }

val LocalFocusMemory = staticCompositionLocalOf { FocusMemory() }

/**
 * The one focusable surface of the TV app: grows, rings white and lifts above its row while
 * focused (Google TV / Apple TV). OK on the remote clicks it.
 */
@Composable
fun FocusCard(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(10.dp),
    scale: Float = 1.08f,
    focusRequester: FocusRequester = remember { FocusRequester() },
    onFocus: () -> Unit = {},
    content: @Composable BoxScope.(focused: Boolean) -> Unit,
) {
    val memory = LocalFocusMemory.current
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    val s by animateFloatAsState(if (focused) scale else 1f, spring(dampingRatio = 0.75f, stiffness = 600f), label = "focus")
    Box(
        modifier
            .zIndex(if (focused) 1f else 0f)
            .graphicsLayer { scaleX = s; scaleY = s }
            .shadow(if (focused) 24.dp else 0.dp, shape, ambientColor = TMovieColors.BrandLight, spotColor = TMovieColors.BrandLight)
            .clip(shape)
            .background(TMovieColors.Surface)
            .then(if (focused) Modifier.border(3.dp, Color.White, shape) else Modifier)
            .focusRequester(focusRequester)
            .onFocusChanged { if (it.isFocused) onFocus() }
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
                .background(if (focused) Color.White else if (selected) TMovieColors.Brand.copy(alpha = 0.25f) else Color.White.copy(alpha = 0.08f))
                .height(44.dp)
                .padding(horizontal = 20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            leading?.invoke(fg)
            Text(text, color = fg, fontSize = 17.sp, fontWeight = if (selected || focused) FontWeight.SemiBold else FontWeight.Medium, maxLines = 1)
        }
    }
}

/**
 * Lists that scroll with focus keep the focused item at a fixed line ([leading] from the start)
 * instead of creeping to the edge: rows hold their column, the page holds its row.
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
fun <T> Shelf(title: String, items: List<T>, key: (T) -> Any, onFocused: () -> Unit = {}, item: @Composable (T) -> Unit) {
    Column(Modifier.fillMaxWidth().padding(bottom = 14.dp).onFocusChanged { if (it.hasFocus) onFocused() }) {
        Text(
            title, color = Color.White.copy(alpha = 0.9f), fontSize = 20.sp, fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(start = Tv.Start, top = 6.dp),
        )
        Pivot(Tv.Start) {
            LazyRow(
                Modifier.focusRestorer(),
                contentPadding = PaddingValues(start = Tv.Start, end = Tv.End, top = Tv.RowBleed, bottom = Tv.RowBleed),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
            ) { items(items, key) { item(it) } }
        }
    }
}

@Composable
fun PosterCard(film: FilmItem, onClick: () -> Unit, onFocus: () -> Unit = {}, focusRequester: FocusRequester = remember { FocusRequester() }) {
    FocusCard(onClick, Modifier.width(Tv.PosterWidth).aspectRatio(2f / 3f), focusRequester = focusRequester, onFocus = onFocus) {
        RemoteImage(film.posterImage ?: film.thumbImage, Modifier.fillMaxSize(), film.name)
    }
}

/** "Xem tiếp": the episode still frame, title and progress. */
@Composable
fun ContinueCard(record: WatchRecord, onClick: () -> Unit, onFocus: () -> Unit = {}, focusRequester: FocusRequester = remember { FocusRequester() }) {
    FocusCard(onClick, Modifier.width(Tv.WideWidth).aspectRatio(16f / 9f), focusRequester = focusRequester, onFocus = onFocus) {
        RemoteImage(record.film.thumbImage, Modifier.fillMaxSize(), record.film.name)
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.45f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.85f))))
        Column(Modifier.align(Alignment.BottomStart).fillMaxWidth()) {
            Text(record.film.name, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, maxLines = 1,
                overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(horizontal = 12.dp))
            Text(record.episodeName.ifBlank { " " }, color = TMovieColors.Secondary, fontSize = 13.sp, maxLines = 1,
                modifier = Modifier.padding(horizontal = 12.dp))
            Spacer(Modifier.height(8.dp))
            ProgressStrip(record.lastProgress)
        }
    }
}

/** "2024 · FHD · Vietsub · Tập 12 · Hành động, Tình cảm". */
fun FilmItem.metaLine(): String = listOfNotNull(
    year?.takeIf { it > 0 }?.toString(), quality, lang, episodeCurrent,
    category?.take(3)?.mapNotNull { it.name }?.joinToString(", ")?.ifBlank { null },
).joinToString("  ·  ")

/** Full-bleed key art fading into the canvas on the left and bottom, behind a page's text. */
@Composable
fun Backdrop(url: String?, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize()) {
        RemoteImage(url, Modifier.align(Alignment.TopEnd).fillMaxWidth(0.78f).aspectRatio(16f / 9f))
        Box(Modifier.fillMaxSize().background(Brush.horizontalGradient(0.22f to TMovieColors.Canvas, 0.62f to TMovieColors.Canvas.copy(alpha = 0.35f), 1f to Color.Transparent)))
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.35f to Color.Transparent, 0.72f to TMovieColors.Canvas)))
    }
}
