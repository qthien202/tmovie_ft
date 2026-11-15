package com.thientech.tmovie.feature.home

import androidx.compose.ui.text.font.FontWeight
import com.thientech.tmovie.core.network.PhimApi
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.runtime.produceState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.border
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeOff
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.Settings
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.designsystem.cinematic
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.ui.PlayFilmButton
import com.thientech.tmovie.core.ui.SaveButton
import com.thientech.tmovie.core.ui.SaveStyle
import com.thientech.tmovie.core.ui.rememberNavigator
import com.thientech.tmovie.core.ui.route
import com.thientech.tmovie.core.ui.sharedFilm
import kotlin.math.absoluteValue
import kotlinx.coroutines.delay

/**
 * Apple TV-style hero: full-bleed key art pages with parallax paging, a slow Ken Burns drift,
 * depth from device tilt, a muted autoplay preview, and a centred title / Play + Add cluster.
 */
@Composable
fun HeroPager(films: List<FilmItem>, art: Map<String, String>, tint: Color, pager: PagerState, scrollOffset: () -> Float) {
    val reduceMotion = rememberReduceMotion()
    val powerSave = rememberPowerSave()
    val autoplaySetting by Settings.heroAutoplay.collectAsStateWithLifecycle()
    val muted by Settings.heroMuted.collectAsStateWithLifecycle()
    val autoplay = autoplaySetting && !reduceMotion && !powerSave
    // Animated values are passed as lambdas and read only inside graphicsLayer, so the hero
    // redraws its layers each frame instead of recomposing.
    val tilt = rememberTilt(enabled = !reduceMotion)
    val haptics = LocalHapticFeedback.current
    val height = (LocalConfiguration.current.screenHeightDp * 0.78f).dp

    // Auto-advance (longer while a preview plays); swiping changes the page and restarts the timer.
    // Keyed on settledPage, not currentPage: currentPage flips halfway through the scroll, which
    // restarted this effect and cancelled its own animation, leaving the hero stuck between pages.
    LaunchedEffect(pager.settledPage, films.size, autoplay) {
        if (films.size < 2) return@LaunchedEffect
        delay(if (autoplay) 30_000 else 8_000)
        if (pager.isScrollInProgress) return@LaunchedEffect  // the user is swiping; their fling decides
        pager.animateScrollToPage((pager.settledPage + 1) % films.size, animationSpec = cinematic())
    }
    LaunchedEffect(pager.settledPage) { haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove) }

    val kenBurns = rememberInfiniteTransition(label = "kenBurns").animateFloat(
        1f, if (reduceMotion) 1f else 1.12f,
        infiniteRepeatable(tween(12_000, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "scale",
    )

    Box(
        Modifier
            .fillMaxWidth()
            .height(height)
            // Stretch on pull-down; on scroll-up the art lags behind.
            .graphicsLayer {
                val y = scrollOffset()
                translationY = if (reduceMotion) 0f else y * 0.35f
            },
    ) {
        HorizontalPager(pager, Modifier.fillMaxSize(), key = { films[it].slug }) { page ->
            val film = films[page]
            HeroPage(
                film = film,
                rank = page + 1,
                art = art[film.slug] ?: film.thumbImage,
                tint = tint,
                pageOffset = { (pager.currentPage - page) + pager.currentPageOffsetFraction },
                kenBurns = { kenBurns.value },
                tilt = { tilt.value },
                motion = !reduceMotion,
                preview = autoplay && page == pager.settledPage,
                muted = muted,
            )
        }
        // Page indicator, vertical down the right edge so it never competes with the caption.
        Column(
            Modifier.align(Alignment.BottomEnd).padding(end = 12.dp, bottom = 40.dp).clip(CircleShape).glass(CircleShape).padding(horizontal = 5.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(5.dp),
        ) {
            films.indices.forEach { i ->
                val selected = i == pager.currentPage
                val h by animateDpAsState(if (selected) 24.dp else 6.dp, label = "dot")
                Box(Modifier.width(5.dp).height(h).clip(CircleShape).background(Color.White.copy(alpha = if (selected) 1f else 0.4f)))
            }
        }
    }
}

@Composable
private fun HeroPage(
    film: FilmItem,
    rank: Int,
    art: String?,
    tint: Color,
    pageOffset: () -> Float,
    kenBurns: () -> Float,
    tilt: () -> androidx.compose.ui.geometry.Offset,
    motion: Boolean,
    preview: Boolean,
    muted: Boolean,
) {
    val nav = rememberNavigator()
    val sourceId = "hero/${film.slug}"
    val animatedTint by animateColorAsState(tint, tween(800), label = "tint")
    // Clip the page so the Ken Burns / tilt scale never bleeds into neighbours or below the hero.
    Box(Modifier.fillMaxSize().clipToBounds()) {
        Box(
            Modifier
                .fillMaxSize()
                .sharedFilm(sourceId)
                .clickable { nav.openFilm(film.route(sourceId)) }
                .graphicsLayer {
                    // Paging parallax + tilt depth; scaled up so neither ever shows an edge.
                    val s = 1.08f * kenBurns()
                    val t = tilt()
                    scaleX = s; scaleY = s
                    translationX = (if (motion) pageOffset() * size.width * 0.4f else 0f) - t.x * 22.dp.toPx()
                    translationY = -t.y * 14.dp.toPx()
                },
        ) {
            RemoteImage(art, Modifier.fillMaxSize(), film.name)
            if (preview) HeroPreview(film.slug, muted, Modifier.fillMaxSize())
        }
        // Scrim: dark at the top for the status bar; at the bottom a heavier fade (Apple TV's
        // blurred veil) so the caption reads on any still.
        Box(
            Modifier.fillMaxSize().background(
                Brush.verticalGradient(
                    0f to Color.Black.copy(alpha = 0.7f), 0.16f to Color.Black.copy(alpha = 0.25f), 0.3f to Color.Transparent,
                    0.46f to Color.Transparent, 0.62f to Color.Black.copy(alpha = 0.38f), 0.8f to animatedTint.copy(alpha = 0.1f).compositeOver(Color.Black.copy(alpha = 0.72f)),
                    1f to TMovieColors.Canvas,
                ),
            ),
        )
        val story by produceState("", film.slug) {
            value = runCatching { PhimApi.shared.detail(film.slug).content.orEmpty() }.getOrDefault("")
                .replace(Regex("<[^>]+>"), "").replace("&nbsp;", " ").replace("&amp;", "&").trim()
        }
        Column(
            Modifier
                .align(Alignment.BottomStart)
                .padding(start = 20.dp, end = 48.dp, bottom = 30.dp)
                .graphicsLayer {
                    val o = pageOffset()
                    val t = tilt()
                    alpha = 1f - (o.absoluteValue * 1.4f).coerceAtMost(1f)
                    translationX = o * 60.dp.toPx() + t.x * 8.dp.toPx()
                    translationY = t.y * 5.dp.toPx()
                },
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    "TOP $rank", color = Color.Black, fontSize = 10.5.sp, fontWeight = FontWeight.Black, letterSpacing = 0.6.sp,
                    modifier = Modifier.background(Color.White, RoundedCornerShape(6.dp)).padding(horizontal = 7.dp, vertical = 2.dp),
                )
                Text("Đang hot tuần này", color = Color.White.copy(alpha = 0.85f), fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
            }
            // Long names step down in size rather than being cut.
            val len = film.name.length
            Text(
                film.name,
                color = Color.White,
                fontSize = if (len > 26) 28.sp else if (len > 16) 34.sp else 40.sp,
                lineHeight = if (len > 26) 31.sp else if (len > 16) 36.sp else 41.sp,
                fontWeight = FontWeight.ExtraBold,
                letterSpacing = (-0.8).sp,
                maxLines = if (len > 26) 3 else 2,
                overflow = TextOverflow.Ellipsis,
                style = TextStyle(shadow = Shadow(Color.Black.copy(alpha = 0.35f), blurRadius = 28f)),
                modifier = Modifier.padding(top = 10.dp),
            )
            Row(Modifier.padding(top = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(facts(film), color = Color.White.copy(alpha = 0.85f), fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                film.quality?.takeIf { it.isNotBlank() }?.let { HeroBadge(it) }
                film.lang?.takeIf { it.isNotBlank() }?.let { HeroBadge(if (it.contains("thuyết", true) || it.contains("lồng", true)) "TM" else "VS") }
            }
            Text(
                story, color = Color.White.copy(alpha = 0.72f), fontSize = 14.sp, lineHeight = 19.sp, maxLines = 2, overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(top = 8.dp).heightIn(min = 38.dp),
            )
            Row(Modifier.padding(top = 16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                PlayFilmButton(film, capsule = true)
                SaveButton(film, SaveStyle.Circle)
                AnimatedVisibility(preview, enter = fadeIn() + scaleIn(), exit = fadeOut() + scaleOut()) {
                    Box(
                        Modifier.size(50.dp).clip(CircleShape).glass(CircleShape).clickable { Settings.setHeroMuted(!muted) },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            if (muted) Icons.AutoMirrored.Filled.VolumeOff else Icons.AutoMirrored.Filled.VolumeUp,
                            if (muted) "Bật tiếng xem trước" else "Tắt tiếng xem trước",
                            tint = Color.White,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun HeroBadge(text: String) {
    Text(
        text, color = Color.White, fontSize = 10.sp, fontWeight = FontWeight.Bold, maxLines = 1,
        modifier = Modifier.border(1.dp, Color.White.copy(alpha = 0.55f), RoundedCornerShape(4.dp)).padding(horizontal = 5.dp, vertical = 1.dp),
    )
}

/** "Phim bộ · Tình cảm · Hành động · 2026" */
private fun facts(film: FilmItem): String = (
    listOf(
        when (film.type) {
            "series" -> "Phim bộ"
            "single" -> "Phim lẻ"
            "tvshows" -> "TV Show"
            "hoathinh" -> "Hoạt hình"
            else -> null
        },
    ) + film.category.orEmpty().take(2).map { it.name } + film.year?.toString()
    ).filterNotNull().joinToString(" · ")
