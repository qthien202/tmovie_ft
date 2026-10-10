package com.thientech.tmovie.core.player

import android.app.Activity
import android.content.Context
import android.media.AudioManager
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import kotlin.math.abs

/** What a drag is doing, shown as a HUD while it lasts. */
sealed interface DragHud {
    data class Seek(val target: Long, val delta: Long) : DragHud
    data class Brightness(val level: Float) : DragHud
    data class Volume(val level: Float) : DragHud
}

/** Double-tap seek on one side: accumulates while the user keeps tapping. */
data class TapSeek(val forward: Boolean, val seconds: Int, val id: Long)

/**
 * Gesture state for the player surface:
 * - tap toggles controls; double-tap left/right seeks ∓10s (taps accumulate)
 * - horizontal drag scrubs; vertical drag sets brightness (left half) or volume (right half)
 * - pinch switches between fit and zoom
 */
class PlayerGestures(private val activity: Activity, private val playback: PlaybackState) {
    var hud by mutableStateOf<DragHud?>(null); private set
    var tapSeek by mutableStateOf<TapSeek?>(null); private set
    var zoomed by mutableStateOf(false)

    private val audio = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val maxVolume = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
    private var lastTapAt = 0L

    fun doubleTap(forward: Boolean) {
        val now = System.currentTimeMillis()
        val current = tapSeek
        val seconds = if (current != null && current.forward == forward && now - lastTapAt < 900) current.seconds + 10 else 10
        lastTapAt = now
        playback.seekBy(if (forward) 10_000 else -10_000)
        tapSeek = TapSeek(forward, seconds, now)
    }

    fun clearTapSeek(id: Long) { if (tapSeek?.id == id) tapSeek = null }

    private fun brightness(): Float = activity.window.attributes.screenBrightness.takeIf { it >= 0 } ?: 0.5f

    private fun setBrightness(level: Float) {
        val attrs = activity.window.attributes
        attrs.screenBrightness = level.coerceIn(0.01f, 1f)
        activity.window.attributes = attrs
    }

    private fun volume(): Float = audio.getStreamVolume(AudioManager.STREAM_MUSIC).toFloat() / maxVolume

    private fun setVolume(level: Float) {
        audio.setStreamVolume(AudioManager.STREAM_MUSIC, (level.coerceIn(0f, 1f) * maxVolume).toInt(), 0)
    }

    fun modifier(enabled: Boolean, onTap: () -> Unit): Modifier = Modifier
        .pointerInput(enabled) {
            if (!enabled) return@pointerInput detectTapGestures(onTap = { onTap() })
            detectTapGestures(
                onTap = { onTap() },
                onDoubleTap = { p -> doubleTap(forward = p.x > size.width / 2) },
            )
        }
        .pointerInput(enabled) {
            if (!enabled) return@pointerInput
            awaitEachGesture {
                val down = awaitFirstDown(requireUnconsumed = false)
                val leftHalf = down.position.x < size.width / 2
                val slop = viewConfiguration.touchSlop
                var mode = 0 // 0 undecided, 1 seek, 2 vertical, 3 pinch
                var total = Offset.Zero
                var pinch = 1f
                val startPos = playback.exo.currentPosition
                val startLevel = if (leftHalf) brightness() else volume()
                do {
                    val event = awaitPointerEvent()
                    if (event.changes.size >= 2) {
                        mode = 3
                        pinch *= event.calculateZoom()
                    } else if (mode != 3) {
                        total += event.calculatePan()
                        if (mode == 0 && (abs(total.x) > slop || abs(total.y) > slop)) {
                            mode = if (abs(total.x) > abs(total.y)) 1 else 2
                        }
                        when (mode) {
                            1 -> {
                                // A full-width swipe covers 90 s.
                                val delta = (total.x / size.width * 90_000).toLong()
                                val target = (startPos + delta).coerceIn(0, playback.duration.takeIf { it > 0 } ?: Long.MAX_VALUE)
                                hud = DragHud.Seek(target, target - startPos)
                            }
                            2 -> {
                                val level = (startLevel - total.y / (size.height * 0.8f)).coerceIn(0f, 1f)
                                if (leftHalf) { setBrightness(level); hud = DragHud.Brightness(level) }
                                else { setVolume(level); hud = DragHud.Volume(level) }
                            }
                        }
                    }
                    if (mode != 0) event.changes.forEach { if (it.positionChange() != Offset.Zero) it.consume() }
                } while (event.changes.any { it.pressed })
                when (mode) {
                    1 -> (hud as? DragHud.Seek)?.let { playback.seekTo(it.target) }
                    3 -> if (pinch > 1.15f) zoomed = true else if (pinch < 0.87f) zoomed = false
                }
                hud = null
            }
        }
}
