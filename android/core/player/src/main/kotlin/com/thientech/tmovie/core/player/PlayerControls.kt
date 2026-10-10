package com.thientech.tmovie.core.player

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.BrightnessMedium
import androidx.compose.material.icons.filled.Forward10
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PictureInPictureAlt
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Replay10
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.VideoLibrary
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.glass
import kotlinx.coroutines.delay

/** Everything drawn over the video. Callbacks keep this free of activity / episode logic. */
@Composable
fun PlayerControls(
    playback: PlaybackState,
    gestures: PlayerGestures,
    title: String,
    episodeName: String,
    nextEpisodeName: String?,
    nextThumb: String?,
    visible: Boolean,
    locked: Boolean,
    hasEpisodes: Boolean,
    offline: Boolean,
    sleepLabel: String?,
    onBack: () -> Unit,
    onInteract: () -> Unit,
    onToggleLock: () -> Unit,
    onPip: () -> Unit,
    onSettings: () -> Unit,
    onEpisodes: () -> Unit,
    onNext: () -> Unit,
) {
    Box(Modifier.fillMaxSize()) {
        // Scrims behind the bars.
        AnimatedVisibility(visible && !locked, enter = fadeIn(), exit = fadeOut()) {
            Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0f to Color.Black.copy(alpha = 0.7f), 0.25f to Color.Transparent, 0.7f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.8f))))
        }

        // Offline: a banner instead of an error; playback resumes on its own when the network returns.
        AnimatedVisibility(offline, enter = fadeIn() + slideInVertically { -it }, exit = fadeOut() + slideOutVertically { -it },
            modifier = Modifier.align(Alignment.TopCenter).padding(top = 72.dp)) {
            OfflineBanner()
        }

        if (playback.buffering && playback.error == null) {
            CircularProgressIndicator(Modifier.align(Alignment.Center).size(56.dp), color = TMovieColors.BrandLight, strokeWidth = 3.dp)
        }

        TapSeekBubbles(gestures)
        DragHudView(gestures.hud, Modifier.align(Alignment.Center))

        if (locked) {
            AnimatedVisibility(visible, enter = fadeIn(), exit = fadeOut(), modifier = Modifier.align(Alignment.CenterStart).padding(start = 32.dp)) {
                RoundIcon(Icons.Filled.Lock, "Mở khoá", size = 56) { onToggleLock() }
            }
            return@Box
        }

        // Top bar.
        AnimatedVisibility(visible, enter = fadeIn() + slideInVertically { -it }, exit = fadeOut() + slideOutVertically { -it }, modifier = Modifier.align(Alignment.TopCenter)) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                RoundIcon(Icons.AutoMirrored.Filled.ArrowBack, "Quay lại", onClick = onBack)
                Column(Modifier.weight(1f).padding(horizontal = 14.dp)) {
                    Text(title, color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(
                        listOfNotNull(episodeName.ifBlank { null }, sleepLabel).joinToString(" · "),
                        color = TMovieColors.Secondary, fontSize = 13.sp, maxLines = 1,
                    )
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (playback.speed != 1f) Chip("${playback.speed.toString().removeSuffix(".0")}×") { onSettings() }
                    RoundIcon(Icons.Filled.LockOpen, "Khoá màn hình", onClick = onToggleLock)
                    RoundIcon(Icons.Filled.PictureInPictureAlt, "Hình trong hình", onClick = onPip)
                    RoundIcon(Icons.Filled.Settings, "Cài đặt", onClick = onSettings)
                    if (hasEpisodes) RoundIcon(Icons.Filled.VideoLibrary, "Danh sách tập", onClick = onEpisodes)
                }
            }
        }

        // Center transport.
        AnimatedVisibility(visible && playback.error == null, enter = fadeIn() + scaleIn(initialScale = 0.9f), exit = fadeOut() + scaleOut(targetScale = 0.9f), modifier = Modifier.align(Alignment.Center)) {
            Row(horizontalArrangement = Arrangement.spacedBy(48.dp), verticalAlignment = Alignment.CenterVertically) {
                RoundIcon(Icons.Filled.Replay10, "Lùi 10 giây", size = 56) { playback.seekBy(-10_000); onInteract() }
                Box(
                    Modifier.size(84.dp).clip(CircleShape).glass(CircleShape).clickable { playback.toggle(); onInteract() },
                    contentAlignment = Alignment.Center,
                ) {
                    AnimatedContent(if (playback.ended) 2 else if (playback.isPlaying) 1 else 0, transitionSpec = { scaleIn() togetherWith scaleOut() }, label = "play") { s ->
                        Icon(
                            when (s) { 2 -> Icons.Filled.Replay; 1 -> Icons.Filled.Pause; else -> Icons.Filled.PlayArrow },
                            if (s == 1) "Tạm dừng" else "Phát",
                            tint = Color.White,
                            modifier = Modifier.size(44.dp),
                        )
                    }
                }
                RoundIcon(Icons.Filled.Forward10, "Tới 10 giây", size = 56) { playback.seekBy(10_000); onInteract() }
            }
        }

        // Error (network errors are handled by the offline banner + auto-resume).
        playback.error?.takeIf { !(offline && it.errorCode in 2000..2999) }?.let {
            Column(Modifier.align(Alignment.Center).clip(RoundedCornerShape(20.dp)).glass(RoundedCornerShape(20.dp)).padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Không phát được tập này", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                Text("Thử lại hoặc đổi server trong danh sách tập.", color = TMovieColors.Secondary, fontSize = 13.sp)
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Chip("Thử lại", highlighted = true) { playback.retry() }
                    if (hasEpisodes) Chip("Đổi server") { onEpisodes() }
                }
            }
        }

        // Skip intro: the first couple of minutes of an episode.
        val showSkip = playback.position in 5_000..150_000 && playback.duration > 600_000 && !playback.buffering
        AnimatedVisibility(showSkip, enter = fadeIn() + slideInHorizontally { it }, exit = fadeOut() + slideOutHorizontally { it },
            modifier = Modifier.align(Alignment.BottomEnd).padding(end = 24.dp, bottom = if (visible) 110.dp else 32.dp)) {
            Chip("Bỏ qua giới thiệu  ⏭", highlighted = true) { playback.seekBy(85_000); onInteract() }
        }

        // Next episode card in the last 18 s (auto-plays at the end unless cancelled).
        NextEpisodeCard(playback, nextEpisodeName, nextThumb, onNext, Modifier.align(Alignment.BottomEnd).padding(end = 24.dp, bottom = if (visible) 110.dp else 32.dp))

        // Bottom bar.
        AnimatedVisibility(visible, enter = fadeIn() + slideInVertically { it }, exit = fadeOut() + slideOutVertically { it }, modifier = Modifier.align(Alignment.BottomCenter)) {
            Column(Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 16.dp)) {
                SeekBar(playback, onInteract)
                Row(Modifier.fillMaxWidth().padding(top = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("${formatTime(playback.position)} / ${formatTime(playback.duration)}", color = Color.White, fontSize = 13.sp)
                    Spacer(Modifier.weight(1f))
                    if (nextEpisodeName != null) {
                        Row(Modifier.clip(CircleShape).clickable(onClick = onNext).padding(horizontal = 10.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.SkipNext, null, tint = Color.White, modifier = Modifier.size(20.dp))
                            Text(" Tập tiếp", color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SeekBar(playback: PlaybackState, onInteract: () -> Unit) {
    var dragging by remember { mutableStateOf(false) }
    var dragFraction by remember { mutableFloatStateOf(0f) }
    val duration = playback.duration.coerceAtLeast(1)
    val fraction = if (dragging) dragFraction else playback.position.toFloat() / duration
    val bufferedFraction = playback.buffered.toFloat() / duration
    val thumb by animateFloatAsState(if (dragging) 18f else 12f, label = "thumb")

    BoxWithConstraints(
        Modifier
            .fillMaxWidth()
            .height(32.dp)
            .pointerInput(duration) {
                detectTapGestures { p -> playback.seekTo((p.x / size.width * duration).toLong()); onInteract() }
            }
            .pointerInput(duration) {
                detectHorizontalDragGestures(
                    onDragStart = { p -> dragging = true; dragFraction = (p.x / size.width).coerceIn(0f, 1f) },
                    onDragEnd = { playback.seekTo((dragFraction * duration).toLong()); dragging = false; onInteract() },
                    onDragCancel = { dragging = false },
                ) { change, _ -> dragFraction = (change.position.x / size.width).coerceIn(0f, 1f); onInteract() }
            },
        contentAlignment = Alignment.CenterStart,
    ) {
        val width = maxWidth
        Box(Modifier.fillMaxWidth().height(4.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.2f)))
        Box(Modifier.fillMaxWidth(bufferedFraction.coerceIn(0f, 1f)).height(4.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.35f)))
        Box(Modifier.fillMaxWidth(fraction.coerceIn(0f, 1f)).height(4.dp).clip(CircleShape).background(Brush.horizontalGradient(listOf(TMovieColors.Brand, TMovieColors.BrandLight))))
        Box(Modifier.offset(x = width * fraction.coerceIn(0f, 1f) - (thumb / 2).dp).size(thumb.dp).clip(CircleShape).background(Color.White))
        if (dragging) {
            Text(
                formatTime((dragFraction * duration).toLong()),
                color = Color.Black, fontSize = 13.sp, fontWeight = FontWeight.Bold,
                modifier = Modifier.offset(x = (width * dragFraction - 28.dp).coerceIn(0.dp, width - 56.dp), y = (-30).dp)
                    .clip(RoundedCornerShape(8.dp)).background(Color.White).padding(horizontal = 8.dp, vertical = 3.dp),
            )
        }
    }
}

@Composable
private fun NextEpisodeCard(playback: PlaybackState, nextName: String?, thumb: String?, onNext: () -> Unit, modifier: Modifier) {
    var cancelled by remember(nextName) { mutableStateOf(false) }
    val remaining = playback.duration - playback.position
    val show = nextName != null && !cancelled && playback.duration > 60_000 && remaining in 1..18_000
    LaunchedEffect(playback.ended, cancelled, nextName) { if (playback.ended && !cancelled && nextName != null) onNext() }
    AnimatedVisibility(show, enter = fadeIn() + slideInHorizontally { it / 2 }, exit = fadeOut() + slideOutHorizontally { it / 2 }, modifier = modifier) {
        Row(Modifier.width(360.dp).clip(RoundedCornerShape(18.dp)).background(Color(0xE6101418)).glass(RoundedCornerShape(18.dp)).padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(width = 120.dp, height = 68.dp).clip(RoundedCornerShape(10.dp))) {
                RemoteImage(thumb, Modifier.fillMaxSize())
                Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.3f)), contentAlignment = Alignment.Center) {
                    Text("${(remaining / 1000).coerceAtLeast(0)}", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Black)
                }
            }
            Column(Modifier.weight(1f).padding(horizontal = 12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("TẬP TIẾP THEO", color = TMovieColors.BrandLight, fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                Text(nextName.orEmpty(), color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Chip("Phát ngay", highlighted = true, onClick = onNext)
                    Chip("Huỷ") { cancelled = true }
                }
            }
        }
    }
}

/** "+30s" bubbles on the side that was double-tapped. */
@Composable
private fun TapSeekBubbles(gestures: PlayerGestures) {
    val tap = gestures.tapSeek ?: return
    LaunchedEffect(tap.id) {
        delay(700)
        gestures.clearTapSeek(tap.id)
    }
    Box(Modifier.fillMaxSize()) {
        Box(
            Modifier.align(if (tap.forward) Alignment.CenterEnd else Alignment.CenterStart)
                .fillMaxHeight().fillMaxWidth(0.35f)
                .clip(if (tap.forward) RoundedCornerShape(topStartPercent = 50, bottomStartPercent = 50) else RoundedCornerShape(topEndPercent = 50, bottomEndPercent = 50))
                .background(Color.White.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(if (tap.forward) Icons.Filled.Forward10 else Icons.Filled.Replay10, null, tint = Color.White, modifier = Modifier.size(40.dp))
                Text("${if (tap.forward) "+" else "−"}${tap.seconds}s", color = Color.White, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun DragHudView(hud: DragHud?, modifier: Modifier) {
    if (hud == null) return
    Row(modifier.clip(RoundedCornerShape(16.dp)).background(Color(0xCC101418)).glass(RoundedCornerShape(16.dp)).padding(horizontal = 18.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        when (hud) {
            is DragHud.Seek -> Text(
                "${formatTime(hud.target)}  (${if (hud.delta >= 0) "+" else "−"}${formatTime(kotlin.math.abs(hud.delta))})",
                color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold,
            )
            is DragHud.Brightness -> LevelHud(Icons.Filled.BrightnessMedium, hud.level)
            is DragHud.Volume -> LevelHud(Icons.AutoMirrored.Filled.VolumeUp, hud.level)
        }
    }
}

@Composable
private fun LevelHud(icon: ImageVector, level: Float) {
    Icon(icon, null, tint = Color.White)
    Box(Modifier.width(160.dp).height(6.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.2f))) {
        Box(Modifier.fillMaxWidth(level).height(6.dp).clip(CircleShape).background(TMovieColors.BrandLight))
    }
    Text("${(level * 100).toInt()}%", color = Color.White, fontWeight = FontWeight.SemiBold)
}

@Composable
private fun OfflineBanner() {
    val pulse by androidx.compose.animation.core.rememberInfiniteTransition(label = "offline").animateFloat(
        0.4f, 1f, androidx.compose.animation.core.infiniteRepeatable(androidx.compose.animation.core.tween(700), androidx.compose.animation.core.RepeatMode.Reverse), label = "pulse",
    )
    Row(
        Modifier.clip(CircleShape).background(Color(0xE6101418)).glass(CircleShape).padding(horizontal = 18.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(Icons.Filled.WifiOff, null, tint = Color(0xFFFFB74D), modifier = Modifier.size(20.dp).graphicsLayer { alpha = pulse })
        Text("Mất kết nối mạng · sẽ tự phát lại khi có mạng", color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
fun RoundIcon(icon: ImageVector, label: String, size: Int = 44, onClick: () -> Unit) {
    Box(Modifier.size(size.dp).clip(CircleShape).glass(CircleShape).clickable(onClick = onClick), contentAlignment = Alignment.Center) {
        Icon(icon, label, tint = Color.White, modifier = Modifier.size((size * 0.5f).dp))
    }
}

@Composable
fun Chip(text: String, highlighted: Boolean = false, onClick: () -> Unit) {
    Text(
        text,
        color = if (highlighted) Color.Black else Color.White,
        fontSize = 14.sp,
        fontWeight = FontWeight.SemiBold,
        modifier = Modifier.clip(CircleShape)
            .background(if (highlighted) Color.White else Color.White.copy(alpha = 0.14f))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
    )
}
