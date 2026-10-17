package com.thientech.tmovie.core.player

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.ServerData
import com.thientech.tmovie.core.voiceover.AiVoiceOver
import com.thientech.tmovie.core.voiceover.VoiceModel
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.platform.LocalContext

enum class AspectMode(val label: String) { Fit("Vừa"), Zoom("Phóng"), Fill("Giãn") }

/** Sleep timer choices; minutes, or -1 for "end of this episode". */
val sleepChoices = listOf(0 to "Tắt", 15 to "15 phút", 30 to "30 phút", 45 to "45 phút", 60 to "60 phút", -1 to "Hết tập này")

@Composable
private fun Panel(title: String, onClose: () -> Unit, content: @Composable () -> Unit) {
    Column(
        Modifier.fillMaxHeight().width(400.dp).background(Color(0xF20B0F12)).padding(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(title, color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            IconButton(onClick = onClose) { Icon(Icons.Filled.Close, "Đóng", tint = Color.White) }
        }
        content()
    }
}

@Composable
private fun Section(title: String, options: List<Pair<String, Boolean>>, onPick: (Int) -> Unit) {
    if (options.isEmpty()) return
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title.uppercase(), color = TMovieColors.Secondary, fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            options.forEachIndexed { i, (label, selected) ->
                Text(
                    label,
                    color = if (selected) Color.Black else Color.White,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp,
                    modifier = Modifier.clip(CircleShape)
                        .background(if (selected) Color.White else Color.White.copy(alpha = 0.10f))
                        .clickable { onPick(i) }
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                )
            }
        }
    }
}

@Composable
fun SettingsPanel(
    playback: PlaybackState,
    voiceOver: AiVoiceOver?,
    aspect: AspectMode,
    onAspect: (AspectMode) -> Unit,
    sleepMinutes: Int,
    onSleep: (Int) -> Unit,
    onClose: () -> Unit,
) {
    Panel("Cài đặt phát", onClose) {
        Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            val speeds = listOf(0.5f, 0.75f, 1f, 1.25f, 1.5f, 2f)
            Section("Tốc độ", speeds.map { (if (it == 1f) "Bình thường" else "${it.toString().removeSuffix(".0")}×") to (it == playback.speed) }) {
                playback.changeSpeed(speeds[it])
            }
            val quality = playback.qualityOptions()
            Section("Chất lượng", quality.map { it.label to it.selected }) { quality[it].apply() }
            val audio = playback.audioOptions()
            Section("Âm thanh", audio.map { it.label to it.selected }) { audio[it].apply() }
            val subs = playback.subtitleOptions()
            Section("Phụ đề", subs.map { it.label to it.selected }) { subs[it].apply() }
            voiceOver?.let { VoiceOverSection(it) }
            Section("Khung hình", AspectMode.entries.map { it.label to (it == aspect) }) { onAspect(AspectMode.entries[it]) }
            Section("Hẹn giờ tắt", sleepChoices.map { it.second to (it.first == sleepMinutes) }) { onSleep(sleepChoices[it].first) }
        }
    }
}

/** "Thuyết minh AI": download the voice model, then on/off and the voice. */
@Composable
private fun VoiceOverSection(voiceOver: AiVoiceOver) {
    val model by VoiceModel.state.collectAsState()
    val on by voiceOver.enabled.collectAsState()
    val voice by voiceOver.voice.collectAsState()
    when (val m = model) {
        VoiceModel.State.Unsupported -> {}
        VoiceModel.State.Missing, is VoiceModel.State.Failed ->
            Section("Thuyết minh AI", listOf("Tải giọng đọc (${VoiceModel.totalBytes / 1_000_000} MB)" to false)) { VoiceModel.download() }
        is VoiceModel.State.Downloading ->
            Section("Thuyết minh AI", listOf("Đang tải ${(m.progress * 100).toInt()}% · Huỷ" to true)) { VoiceModel.cancel() }
        VoiceModel.State.Ready -> {
            Section("Thuyết minh AI", listOf("Tắt" to !on, "Bật" to on)) { voiceOver.setEnabled(it == 1) }
            if (on) {
                val voices = AiVoiceOver.voices(LocalContext.current)
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Section("Giọng đọc", voices.map { it.first to (it.first == voice) }) { voiceOver.setVoice(voices[it].first) }
                    voices.firstOrNull { it.first == voice }?.let { Text(it.second, color = TMovieColors.Secondary, fontSize = 13.sp) }
                }
            }
        }
    }
}

@Composable
fun EpisodePanel(
    servers: List<String>,
    lists: List<List<ServerData>>,
    currentServer: Int,
    currentIndex: Int,
    onPick: (Int, Int) -> Unit,
    onClose: () -> Unit,
) {
    var shown by remember { mutableIntStateOf(currentServer) }
    val grid = rememberLazyGridState()
    LaunchedEffect(Unit) { if (shown == currentServer) grid.scrollToItem((currentIndex - 6).coerceAtLeast(0)) }
    Panel("Danh sách tập", onClose) {
        if (servers.size > 1) {
            Section("Server", servers.mapIndexed { i, s -> s to (i == shown) }) { shown = it }
        }
        LazyVerticalGrid(
            GridCells.Fixed(3),
            state = grid,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(bottom = 16.dp),
        ) {
            itemsIndexed(lists.getOrNull(shown).orEmpty()) { i, ep ->
                val current = shown == currentServer && i == currentIndex
                Box(
                    Modifier
                        .height(44.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(if (current) TMovieColors.Brand else Color.White.copy(alpha = 0.10f))
                        .clickable(enabled = ep.streamUrl != null) { onPick(shown, i) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        ep.name ?: "${i + 1}",
                        color = if (ep.streamUrl == null) Color.White.copy(alpha = 0.3f) else Color.White,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}
