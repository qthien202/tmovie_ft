package com.thientech.tmovie.feature.home

import androidx.annotation.OptIn
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.thientech.tmovie.core.network.PhimApi
import kotlinx.coroutines.delay

/**
 * Muted autoplay preview for the hero, Apple TV style: after the art has shown for a moment,
 * a 45s window of episode 1 (from ~4 min in, past the opening) fades in and loops.
 */
@OptIn(UnstableApi::class)
@Composable
fun HeroPreview(slug: String, muted: Boolean, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val exo = remember(slug) { ExoPlayer.Builder(context).build().apply { repeatMode = Player.REPEAT_MODE_OFF } }
    var visible by remember(slug) { mutableStateOf(false) }
    val alpha by animateFloatAsState(if (visible) 1f else 0f, tween(1200), label = "preview")

    LaunchedEffect(muted) { exo.volume = if (muted) 0f else 1f }

    LaunchedEffect(slug) {
        delay(1500)  // let the key art land first
        val detail = runCatching { PhimApi.shared.detail(slug) }.getOrNull() ?: return@LaunchedEffect
        val url = detail.episodes?.firstOrNull()?.serverData?.firstOrNull { it.streamUrl != null }?.streamUrl ?: return@LaunchedEffect
        exo.setMediaItem(MediaItem.fromUri(url))
        exo.prepare()
        // Wait for the duration, seek past the opening, then loop a 45s window.
        while (exo.duration <= 0) delay(250)
        val start = if (exo.duration > 600_000) 240_000L else exo.duration / 10
        exo.seekTo(start)
        exo.play()
        while (true) {
            delay(500)
            if (!visible && exo.isPlaying && exo.currentPosition > start + 300) visible = true
            if (exo.currentPosition > start + 45_000) exo.seekTo(start)
        }
    }
    DisposableEffect(slug) { onDispose { exo.release() } }
    // Pause while the app is in the background or the full player covers it.
    LifecycleStartEffect(exo) {
        if (exo.playbackState != Player.STATE_IDLE) exo.play()
        onStopOrDispose { exo.pause() }
    }

    AndroidView(
        factory = { ctx ->
            PlayerView(ctx).apply {
                useController = false
                resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                setShutterBackgroundColor(android.graphics.Color.TRANSPARENT)
                player = exo
            }
        },
        update = { it.player = exo },
        modifier = modifier.graphicsLayer { this.alpha = alpha },
    )
}
