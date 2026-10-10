package com.thientech.tmovie.feature.home

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
    val tilt by rememberTilt(enabled = !reduceMotion)
    val haptics = LocalHapticFeedback.current
    val height = (LocalConfiguration.current.screenHeightDp * 0.74f).dp

    // Auto-advance (longer while a preview plays); swiping changes the page and restarts the timer.
    LaunchedEffect(pager.currentPage, films.size, autoplay) {
        if (films.size < 2) return@LaunchedEffect
        delay(if (autoplay) 30_000 else 8_000)
        pager.animateScrollToPage((pager.currentPage + 1) % films.size, animationSpec = cinematic())
    }
    LaunchedEffect(pager.settledPage) { haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove) }

    val kenBurns by rememberInfiniteTransition(label = "kenBurns").animateFloat(
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
            val offset = (pager.currentPage - page) + pager.currentPageOffsetFraction
            HeroPage(
                film = film,
                art = art[film.slug] ?: film.thumbImage,
                tint = tint,
                pageOffset = offset,
                kenBurns = kenBurns,
                tilt = tilt,
                motion = !reduceMotion,
                preview = autoplay && page == pager.settledPage,
                muted = muted,
            )
        }
        // Page dots.
        Row(Modifier.align(Alignment.BottomCenter).padding(bottom = 14.dp), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
            films.indices.forEach { i ->
                val selected = i == pager.currentPage
                val w by animateDpAsState(if (selected) 20.dp else 7.dp, label = "dot")
                Box(Modifier.width(w).height(7.dp).clip(CircleShape).background(Color.White.copy(alpha = if (selected) 1f else 0.4f)))
            }
        }
    }
}

@Composable
private fun HeroPage(
    film: FilmItem,
    art: String?,
    tint: Color,
    pageOffset: Float,
    kenBurns: Float,
    tilt: androidx.compose.ui.geometry.Offset,
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
                    val s = 1.08f * kenBurns
                    scaleX = s; scaleY = s
                    translationX = (if (motion) pageOffset * size.width * 0.4f else 0f) - tilt.x * 22.dp.toPx()
                    translationY = -tilt.y * 14.dp.toPx()
                },
        ) {
            RemoteImage(art, Modifier.fillMaxSize(), film.name)
            if (preview) HeroPreview(film.slug, muted, Modifier.fillMaxSize())
        }
        // Scrim: top fade for the header, tinted fade into the page at the bottom.
        Box(
            Modifier.fillMaxSize().background(
                Brush.verticalGradient(
                    0f to Color.Black.copy(alpha = 0.55f), 0.25f to Color.Transparent,
                    0.35f to Color.Transparent, 0.65f to animatedTint.copy(alpha = 0.25f), 1f to TMovieColors.Canvas,
                ),
            ),
        )
        Column(
            Modifier
                .align(Alignment.BottomCenter)
                .padding(start = 24.dp, end = 24.dp, bottom = 44.dp)
                .graphicsLayer {
                    alpha = 1f - (pageOffset.absoluteValue * 1.4f).coerceAtMost(1f)
                    translationX = pageOffset * 60.dp.toPx() + tilt.x * 8.dp.toPx()
                    translationY = tilt.y * 5.dp.toPx()
                },
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                captionLine(film).uppercase(),
                color = Color.White.copy(alpha = 0.75f),
                fontSize = 12.sp,
                letterSpacing = 1.2.sp,
                maxLines = 1,
            )
            Text(
                film.name,
                style = TMovieType.Display.copy(shadow = Shadow(Color.Black.copy(alpha = 0.5f), blurRadius = 24f)),
                color = Color.White,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            film.originName?.takeIf { it.isNotBlank() && it != film.name }?.let {
                Text(it, color = Color.White.copy(alpha = 0.7f), fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            Row(Modifier.padding(top = 6.dp), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
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

/** "Phim bộ · Tình cảm · 2026 · ★ 8.4" */
private fun captionLine(film: FilmItem): String = listOfNotNull(
    when (film.type) {
        "series" -> "Phim bộ"
        "single" -> "Phim lẻ"
        "tvshows" -> "TV Show"
        "hoathinh" -> "Hoạt hình"
        else -> null
    },
    film.category?.firstOrNull()?.name,
    film.year?.toString(),
    film.rating?.let { "★ " + String.format(java.util.Locale.US, "%.1f", it) },
).joinToString(" · ")

