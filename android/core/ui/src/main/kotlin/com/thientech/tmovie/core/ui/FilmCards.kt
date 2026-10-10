package com.thientech.tmovie.core.ui

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
    var shown by remember { mutableStateOf(false) }
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

/** "Xem tiếp" card: landscape still with progress; tapping resumes playback straight away. */
@Composable
fun ContinueCard(record: WatchRecord, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var loading by remember { mutableStateOf(false) }
    val interaction = rememberInteraction()
    Column(
        modifier
            .width(210.dp)
            .pressScale(interaction)
            .clip(CardShape)
            .clickable(interaction, indication = null) {
                scope.launch {
                    loading = true
                    runCatching { PhimApi.shared.detail(record.film.slug) }.getOrNull()?.let { Player.start(context, it) }
                    loading = false
                }
            },
    ) {
        Box(Modifier.fillMaxWidth().aspectRatio(16f / 9f), contentAlignment = Alignment.Center) {
            RemoteImage(record.film.thumbImage, Modifier.matchParentSize())
            Box(Modifier.size(44.dp).clip(CircleShape).glass(CircleShape), contentAlignment = Alignment.Center) {
                if (loading) CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                else Icon(Icons.Filled.PlayArrow, "Tiếp tục xem", tint = Color.White)
            }
            ProgressStrip(maxOf(0.03f, record.lastProgress), Modifier.align(Alignment.BottomCenter))
        }
        Column(Modifier.fillMaxWidth().background(Color.White.copy(alpha = 0.08f)).padding(horizontal = 10.dp, vertical = 8.dp)) {
            Text(record.film.name, color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(record.episodeName, color = TMovieColors.Secondary, fontSize = 12.sp, maxLines = 1)
        }
    }
}
