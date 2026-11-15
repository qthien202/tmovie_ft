package com.thientech.tmovie.core.ui

import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.height
import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers
import com.thientech.tmovie.core.data.ContinueFrames
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.Brush
import androidx.compose.runtime.produceState
import androidx.compose.foundation.border
import androidx.compose.foundation.Image
import android.graphics.BitmapFactory
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.data.WatchRecord
import com.thientech.tmovie.core.designsystem.CardShape
import com.thientech.tmovie.core.designsystem.ProgressStrip
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.SectionTitle
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.cinematic
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.designsystem.pressScale
import com.thientech.tmovie.core.designsystem.rememberInteraction
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.player.Player
import kotlinx.coroutines.launch

/** Portrait poster that opens the film with a shared-element transition. */
@Composable
fun PosterCard(film: FilmItem, sourceId: String, modifier: Modifier = Modifier, width: Dp? = 112.dp) {
    val nav = rememberNavigator()
    val interaction = rememberInteraction()
    Box(
        (if (width != null) modifier.width(width) else modifier.fillMaxWidth())
            .aspectRatio(2f / 3f)
            .pressScale(interaction)
            .sharedFilm(sourceId)
            .clip(CardShape)
            .clickable(interaction, indication = null) { nav.openFilm(film.route(sourceId)) },
    ) {
        RemoteImage(film.posterImage, Modifier.matchParentSize(), film.name)
        film.episodeCurrent?.takeIf { it.isNotBlank() && !it.equals("full", true) }?.let {
            Text(
                it.replace("Hoàn Tất", "Trọn bộ"),
                color = Color.White,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                modifier = Modifier
                    .background(TMovieColors.Brand, RoundedCornerShape(bottomEnd = 8.dp))
                    .padding(horizontal = 6.dp, vertical = 3.dp),
            )
        }
    }
}

/** Section title with an optional "Tất cả" push. */
@Composable
fun RailHeader(title: String, more: ListRoute? = null) {
    val nav = rememberNavigator()
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        SectionTitle(title, Modifier.weight(1f))
        if (more != null) {
            Row(Modifier.clickable { nav.openList(more) }, verticalAlignment = Alignment.CenterVertically) {
                Text("Tất cả", color = TMovieColors.Secondary, fontSize = 15.sp)
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = TMovieColors.Secondary)
            }
        }
    }
}

/** A titled horizontal rail that rises in the first time it is composed. */
@Composable
fun Shelf(title: String, more: ListRoute? = null, spacing: Dp = 8.dp, content: LazyListScope.() -> Unit) {
    // Saveable, so the rise plays once rather than every time the shelf scrolls back into view.
    var shown by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(Unit) { shown = true }
    val progress by animateFloatAsState(if (shown) 1f else 0f, cinematic(), label = "rise")
    Column(
        Modifier.graphicsLayer { alpha = progress; translationY = (1 - progress) * 28.dp.toPx() },
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        RailHeader(title, more)
        LazyRow(contentPadding = PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(spacing), content = content)
    }
}

/**
 * "Xem tiếp" card, Apple TV Up Next: a large 16:9 still (the frame the viewer paused on, else the
 * film's), the episode as a glass chip, a glass play button, progress along the bottom edge with
 * the time left, and the title underneath. Tapping resumes playback straight away.
 */
@Composable
fun ContinueCard(record: WatchRecord, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var loading by remember { mutableStateOf(false) }
    val interaction = rememberInteraction()
    // Read again whenever the record is saved, so a newer paused frame shows up.
    val frame by produceState<ImageBitmap?>(null, record.film.slug, record.updatedAt) {
        value = withContext(Dispatchers.IO) {
            ContinueFrames.file(context, record.film.slug).takeIf { it.exists() }?.let { BitmapFactory.decodeFile(it.path)?.asImageBitmap() }
        }
    }
    val episode = record.episodeName.let { if (it.isNotEmpty() && it.all(Char::isDigit)) "Tập ${it.toInt()}" else it }
    val left = record.durations[record.lastEpisodeSlug]?.takeIf { it > 0 }?.let { d ->
        maxOf(1, ((d - (record.positions[record.lastEpisodeSlug] ?: 0.0)) / 60).toInt())
    }
    val shape = RoundedCornerShape(20.dp)
    Column(
        modifier
            .width(286.dp)
            .pressScale(interaction)
            .clickable(interaction, indication = null) {
                scope.launch {
                    loading = true
                    runCatching { PhimApi.shared.detail(record.film.slug) }.getOrNull()?.let { Player.start(context, it) }
                    loading = false
                }
            },
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(Modifier.fillMaxWidth().aspectRatio(16f / 9f).clip(shape).border(1.dp, Color.White.copy(alpha = 0.12f), shape), contentAlignment = Alignment.Center) {
            frame?.let { Image(it, null, Modifier.matchParentSize(), contentScale = ContentScale.Crop) }
                ?: RemoteImage(record.film.thumbImage, Modifier.matchParentSize())
            Box(Modifier.matchParentSize().background(Brush.verticalGradient(0.5f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.72f))))
            Box(Modifier.size(52.dp).clip(CircleShape).glass(CircleShape), contentAlignment = Alignment.Center) {
                if (loading) CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                else Icon(Icons.Filled.PlayArrow, "Tiếp tục xem", tint = Color.White, modifier = Modifier.size(26.dp))
            }
            if (episode.isNotEmpty()) {
                Text(
                    episode, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold, maxLines = 1,
                    modifier = Modifier.align(Alignment.TopStart).padding(10.dp).clip(CircleShape).glass(CircleShape).padding(horizontal = 9.dp, vertical = 3.dp),
                )
            }
            Row(
                Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(horizontal = 12.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Box(Modifier.weight(1f).height(4.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.3f))) {
                    Box(Modifier.fillMaxHeight().fillMaxWidth(maxOf(0.03f, record.lastProgress)).clip(CircleShape).background(Color.White))
                }
                left?.let { Text("Còn $it phút", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, maxLines = 1) }
            }
        }
        Text(
            record.film.name, color = TMovieColors.Secondary, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, maxLines = 1,
            overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(start = 2.dp),
        )
    }
}
