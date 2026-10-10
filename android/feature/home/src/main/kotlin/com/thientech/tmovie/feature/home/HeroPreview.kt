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
import android.view.TextureView
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import com.thientech.tmovie.core.player.StreamPlayer
import androidx.media3.common.VideoSize
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
    val exo = remember(slug) { StreamPlayer.create(context, preview = true).apply { repeatMode = Player.REPEAT_MODE_OFF } }
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

    // TextureView, not PlayerView's default SurfaceView: a SurfaceView ignores Compose clipping,
    // so the zoomed video spilled out below the hero. Sized to aspect-fill, then clipped.
    var videoRatio by remember(slug) { mutableFloatStateOf(16f / 9f) }
    DisposableEffect(exo) {
        val listener = object : Player.Listener {
            override fun onVideoSizeChanged(size: VideoSize) {
                if (size.width > 0 && size.height > 0) videoRatio = size.width * size.pixelWidthHeightRatio / size.height
            }
        }
        exo.addListener(listener)
        onDispose { exo.removeListener(listener) }
    }
    BoxWithConstraints(modifier.clipToBounds().graphicsLayer { this.alpha = alpha }, contentAlignment = Alignment.Center) {
        val boxRatio = maxWidth / maxHeight
        val (w, h) = if (videoRatio > boxRatio) maxHeight * videoRatio to maxHeight else maxWidth to maxWidth / videoRatio
        AndroidView(
            factory = { ctx -> TextureView(ctx).also { exo.setVideoTextureView(it) } },
            update = { exo.setVideoTextureView(it) },
            modifier = Modifier.wrapContentSize(unbounded = true).requiredSize(w, h),
        )
    }
}
