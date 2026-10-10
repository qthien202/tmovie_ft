package com.thientech.tmovie.feature.detail

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.data.WatchRecord
import com.thientech.tmovie.core.designsystem.ProgressStrip
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.model.FilmImage

private const val CHUNK = 50

/** Netflix-style episode rows: still, number, progress. Long series are split into ranges of 50. */
@Composable
fun EpisodeList(detail: FilmDetail, record: WatchRecord?, stills: List<FilmImage>, play: (server: Int, index: Int) -> Unit) {
    val servers = detail.episodes.orEmpty()
    // Open on the episode last watched.
    var server by remember(detail.slug) { mutableIntStateOf(record?.serverIndex?.takeIf { it in servers.indices } ?: 0) }
    val list = servers.getOrNull(server)?.serverData.orEmpty()
    val ranges = (list.indices step CHUNK).map { it until minOf(it + CHUNK, list.size) }
    var range by remember(detail.slug, server) {
        mutableIntStateOf(if (record != null && record.serverIndex == server) (record.episodeIndex / CHUNK).coerceIn(0, maxOf(0, ranges.size - 1)) else 0)
    }

    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(Modifier.padding(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            if (servers.size > 1) {
                Menu(servers[server].serverName ?: "Server ${server + 1}", servers.indices.map { servers[it].serverName ?: "Server ${it + 1}" }) { server = it }
            }
            if (ranges.size > 1) {
                val label = { r: IntRange -> "Tập ${r.first + 1}–${r.last + 1}" }
                Menu(label(ranges[range.coerceIn(ranges.indices)]), ranges.map(label)) { range = it }
            }
        }
        ranges.getOrNull(range)?.forEach { i ->
            val ep = list[i]
            val progress = record?.progress(ep.slug.orEmpty()) ?: 0f
            val isLast = record != null && record.serverIndex == server && record.episodeIndex == i
            Row(
                Modifier
                    .fillMaxWidth()
                    .clickable(enabled = ep.streamUrl != null) { play(server, i) }
                    .alpha(if (ep.streamUrl == null) 0.4f else 1f)
                    .padding(horizontal = 16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Box(Modifier.width(128.dp).height(72.dp).clip(RoundedCornerShape(6.dp)), contentAlignment = Alignment.Center) {
                    RemoteImage(stills.getOrNull(i % maxOf(1, stills.size))?.url("w300") ?: detail.toItem().thumbImage, Modifier.matchParentSize())
                    Box(Modifier.size(32.dp).clip(CircleShape).glass(CircleShape), contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.PlayArrow, null, tint = Color.White, modifier = Modifier.size(18.dp))
                    }
                    if (progress > 0) ProgressStrip(progress, Modifier.align(Alignment.BottomCenter))
                }
                Column {
                    Text(ep.name ?: "Tập ${i + 1}", color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                    if (isLast) Text("Đang xem", color = TMovieColors.Brand, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

@Composable
private fun Menu(label: String, options: List<String>, onPick: (Int) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box {
        Row(
            Modifier.clip(RoundedCornerShape(8.dp)).glass(RoundedCornerShape(8.dp)).clickable { open = true }.height(36.dp).padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(label, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, maxLines = 1)
            Icon(Icons.Filled.KeyboardArrowDown, null, tint = Color.White)
        }
        DropdownMenu(open, onDismissRequest = { open = false }) {
            options.forEachIndexed { i, o -> DropdownMenuItem(text = { Text(o) }, onClick = { open = false; onPick(i) }) }
        }
    }
}
