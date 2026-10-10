package com.thientech.tmovie.core.player

import androidx.annotation.OptIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import kotlinx.coroutines.delay

/** One row in the quality / audio / subtitle pickers. */
data class TrackOption(val label: String, val selected: Boolean, val apply: () -> Unit)

/**
 * Observable view of the ExoPlayer for the Compose controls: play state, buffering, errors,
 * position (polled 4×/s), speed and the track menus (quality, audio, subtitles).
 */
@Stable
@OptIn(UnstableApi::class)
class PlaybackState(val exo: ExoPlayer) {
    var isPlaying by mutableStateOf(false); private set
    var buffering by mutableStateOf(true); private set
    var ended by mutableStateOf(false); private set
    var error by mutableStateOf<PlaybackException?>(null); private set
    var position by mutableLongStateOf(0L); private set
    var duration by mutableLongStateOf(0L); private set
    var buffered by mutableLongStateOf(0L); private set
    var speed by mutableFloatStateOf(1f); private set
    private var tracks by mutableStateOf(Tracks.EMPTY)

    internal val listener = object : Player.Listener {
        override fun onIsPlayingChanged(playing: Boolean) { isPlaying = playing }
        override fun onPlaybackStateChanged(state: Int) {
            buffering = state == Player.STATE_BUFFERING
            ended = state == Player.STATE_ENDED
            if (state == Player.STATE_READY) error = null
            tick()
        }
        override fun onPlayerError(e: PlaybackException) { error = e; buffering = false }
        override fun onTracksChanged(t: Tracks) { tracks = t }
    }

    fun tick() {
        position = exo.currentPosition.coerceAtLeast(0)
        duration = exo.duration.takeIf { it > 0 } ?: 0
        buffered = exo.bufferedPosition.coerceAtLeast(0)
    }

    fun toggle() = if (exo.isPlaying) exo.pause() else { if (ended) exo.seekTo(0); exo.play() }

    fun seekTo(ms: Long) {
        exo.seekTo(ms.coerceIn(0, duration.takeIf { it > 0 } ?: Long.MAX_VALUE))
        tick()
    }

    fun seekBy(ms: Long) = seekTo(exo.currentPosition + ms)

    fun changeSpeed(value: Float) {
        exo.setPlaybackSpeed(value)
        speed = value
    }

    fun retry() {
        error = null
        exo.prepare()
        exo.play()
    }

    /** "Tự động" plus each HLS rendition, highest first. */
    fun qualityOptions(): List<TrackOption> {
        val groups = tracks.groups.filter { it.type == C.TRACK_TYPE_VIDEO }
        val overridden = exo.trackSelectionParameters.overrides.keys.any { it.type == C.TRACK_TYPE_VIDEO }
        val auto = TrackOption("Tự động", !overridden) {
            exo.trackSelectionParameters = exo.trackSelectionParameters.buildUpon().clearOverridesOfType(C.TRACK_TYPE_VIDEO).build()
        }
        val renditions = groups.flatMap { g ->
            (0 until g.length).filter { g.isTrackSupported(it) }.map { i ->
                val f = g.getTrackFormat(i)
                f.height to TrackOption(if (f.height > 0) "${f.height}p" else "Mặc định", overridden && g.isTrackSelected(i)) {
                    exo.trackSelectionParameters = exo.trackSelectionParameters.buildUpon()
                        .setOverrideForType(TrackSelectionOverride(g.mediaTrackGroup, i)).build()
                }
            }
        }.distinctBy { it.first }.sortedByDescending { it.first }.map { it.second }
        return if (renditions.size > 1) listOf(auto) + renditions else emptyList()
    }

    fun audioOptions(): List<TrackOption> = optionsFor(C.TRACK_TYPE_AUDIO, offLabel = null)

    fun subtitleOptions(): List<TrackOption> = optionsFor(C.TRACK_TYPE_TEXT, offLabel = "Tắt")

    private fun optionsFor(type: Int, offLabel: String?): List<TrackOption> {
        val groups = tracks.groups.filter { it.type == type }
        val options = groups.flatMap { g ->
            (0 until g.length).filter { g.isTrackSupported(it) }.map { i ->
                val f = g.getTrackFormat(i)
                TrackOption(f.label ?: f.language?.uppercase() ?: "Track ${i + 1}", g.isTrackSelected(i)) {
                    exo.trackSelectionParameters = exo.trackSelectionParameters.buildUpon()
                        .setTrackTypeDisabled(type, false)
                        .setOverrideForType(TrackSelectionOverride(g.mediaTrackGroup, i)).build()
                }
            }
        }
        if (offLabel == null) return if (options.size > 1) options else emptyList()
        if (options.isEmpty()) return emptyList()
        val disabled = exo.trackSelectionParameters.disabledTrackTypes.contains(type)
        val off = TrackOption(offLabel, disabled || options.none { it.selected }) {
            exo.trackSelectionParameters = exo.trackSelectionParameters.buildUpon().setTrackTypeDisabled(type, true).build()
        }
        return listOf(off) + options
    }
}

@Composable
fun rememberPlaybackState(exo: ExoPlayer): PlaybackState {
    val state = remember(exo) { PlaybackState(exo) }
    DisposableEffect(exo) {
        exo.addListener(state.listener)
        onDispose { exo.removeListener(state.listener) }
    }
    LaunchedEffect(exo) {
        while (true) {
            state.tick()
            delay(250)
        }
    }
    return state
}

/** 75s → "1:15", 3725s → "1:02:05". */
fun formatTime(ms: Long): String {
    val total = (ms / 1000).coerceAtLeast(0)
    val h = total / 3600
    val m = (total % 3600) / 60
    val s = total % 60
    return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%d:%02d".format(m, s)
}
