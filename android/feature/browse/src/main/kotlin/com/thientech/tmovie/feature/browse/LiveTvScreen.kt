package com.thientech.tmovie.feature.browse

import android.content.Context
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.player.Player
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.URL

/** One channel of an extended M3U playlist. */
data class Channel(val name: String, val logo: String?, val url: String, val userAgent: String?, val referrer: String?, val geoBlocked: Boolean)

/**
 * Parses an extended M3U: `#EXTINF:-1 tvg-logo="…" http-user-agent="…",Name`, optional
 * `#EXTVLCOPT:http-…` lines, then the URL. Names lose their "(1080p)" / "[Geo-blocked]" tags.
 */
fun parseM3u(text: String): List<Channel> {
    fun attr(line: String, key: String) = Regex("""$key="([^"]*)"""").find(line)?.groupValues?.get(1)?.ifBlank { null }
    val out = ArrayList<Channel>()
    var info: String? = null
    var ua: String? = null
    var ref: String? = null
    for (raw in text.lineSequence()) {
        val line = raw.trim()
        when {
            line.startsWith("#EXTINF") -> { info = line; ua = attr(line, "http-user-agent"); ref = attr(line, "http-referrer") }
            line.startsWith("#EXTVLCOPT:http-user-agent=") -> ua = line.substringAfter('=')
            line.startsWith("#EXTVLCOPT:http-referrer=") -> ref = line.substringAfter('=')
            line.isEmpty() || line.startsWith("#") -> {}
            else -> {
                val i = info ?: continue
                // The name follows the last attribute (`…",Name`); attributes may hold commas themselves.
                val q = i.lastIndexOf("\",")
                val name = if (q >= 0) i.substring(q + 2) else i.substringAfter(',')
                out += Channel(
                    name = name.replace(Regex("""\s*[\[(][^\])]*[\])]"""), "").trim().ifEmpty { name },
                    logo = attr(i, "tvg-logo"), url = line, userAgent = ua, referrer = ref,
                    geoBlocked = name.contains("[Geo-blocked]"),
                )
                info = null; ua = null; ref = null
            }
        }
    }
    return out
}

/** Restreams of paid services (FPT Play, SCTV's DRM feed) and re-hosting sites: never in our lists. */
private val unlicensed = listOf("fptplay.net", "sctvdrm", "dethich.pw", "freem3u.xyz", "vietanhtv")

private class Playlist(val title: String, val url: String, val custom: Boolean = false) {
    /** Our lists keep the broadcasters' own free streams; a list the user adds plays as it is. */
    fun keep(c: Channel) = !c.url.contains(".mpd") && (custom || unlicensed.none { c.url.contains(it) } && !(c.geoBlocked && title != VN))

    companion object { const val VN = "Việt Nam" }
}

private val builtIn = listOf(
    Playlist(Playlist.VN, "https://iptv-org.github.io/iptv/countries/vn.m3u"),
    Playlist("Thể thao", "https://iptv-org.github.io/iptv/categories/sports.m3u"),
    Playlist("Tin tức", "https://iptv-org.github.io/iptv/categories/news.m3u"),
)

private fun customLists(context: Context) =
    context.getSharedPreferences("live", Context.MODE_PRIVATE).getStringSet("lists", emptySet()).orEmpty().sorted()

private fun saveCustomLists(context: Context, urls: List<String>) =
    context.getSharedPreferences("live", Context.MODE_PRIVATE).edit().putStringSet("lists", urls.toSet()).apply()

/** "Truyền hình": free-to-air channels from iptv-org's public playlists, plus M3U lists the user adds. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun LiveTvScreen() {
    val context = LocalContext.current
    var custom by remember { mutableStateOf(customLists(context)) }
    val lists = builtIn + custom.map { Playlist(android.net.Uri.parse(it).host ?: it, it, custom = true) }
    var selected by remember { mutableStateOf(builtIn.first().url) }
    val playlist = lists.firstOrNull { it.url == selected } ?: builtIn.first()
    val loaded = remember { mutableStateMapOf<String, Result<List<Channel>>>() }
    var query by remember { mutableStateOf("") }
    var adding by remember { mutableStateOf(false) }

    LaunchedEffect(playlist.url) {
        if (loaded[playlist.url]?.isSuccess == true) return@LaunchedEffect
        loaded.remove(playlist.url)
        loaded[playlist.url] = runCatching {
            withContext(Dispatchers.IO) { parseM3u(URL(playlist.url).readText()) }.filter(playlist::keep)
        }
    }

    Column(Modifier.fillMaxSize()) {
        Column(Modifier.statusBarsPadding().padding(vertical = 8.dp)) {
            Text("Truyền hình", style = TMovieType.Title, color = Color.White, modifier = Modifier.padding(horizontal = 16.dp))
            Row(
                Modifier.padding(top = 12.dp).horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp)
                    .clip(CircleShape).glass(CircleShape).padding(4.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                lists.forEach { p ->
                    val on = p.url == playlist.url
                    Text(
                        p.title,
                        color = if (on) Color.Black else Color.White,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clip(CircleShape).background(if (on) Color.White else Color.Transparent)
                            // Long-press removes a list the user added.
                            .combinedClickable(onLongClick = if (p.custom) ({ custom = (custom - p.url).also { saveCustomLists(context, it) } }) else null) { selected = p.url }
                            .padding(horizontal = 14.dp, vertical = 8.dp),
                    )
                }
                Text("＋", color = Color.White, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.clip(CircleShape).clickable { adding = true }.padding(horizontal = 14.dp, vertical = 8.dp))
            }
            OutlinedTextField(
                query, { query = it }, singleLine = true, placeholder = { Text("Tìm kênh") },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            )
        }

        val result = loaded[playlist.url]
        val channels = result?.getOrNull()
        when {
            result == null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = TMovieColors.Brand) }
            channels == null -> Message("Không tải được danh sách kênh")
            else -> {
                val shown = if (query.isBlank()) channels else channels.filter { it.name.contains(query.trim(), ignoreCase = true) }
                if (shown.isEmpty()) Message("Không có kênh nào") else LazyVerticalGrid(
                    GridCells.Adaptive(104.dp), Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 120.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp), verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    items(shown, key = { it.url + it.name }) { ChannelTile(it) }
                }
            }
        }
    }

    if (adding) AddListDialog(onDismiss = { adding = false }) { url ->
        adding = false
        if (url !in custom) custom = (custom + url).also { saveCustomLists(context, it) }
        selected = url
    }
}

@Composable
private fun ChannelTile(channel: Channel) {
    val context = LocalContext.current
    Column(
        Modifier.clip(RoundedCornerShape(10.dp)).clickable { Player.live(context, channel.name, channel.url, channel.userAgent, channel.referrer) },
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(Modifier.fillMaxWidth().aspectRatio(16f / 9f).clip(RoundedCornerShape(10.dp)).glass(RoundedCornerShape(10.dp)), contentAlignment = Alignment.Center) {
            if (channel.logo != null) RemoteImage(channel.logo, Modifier.fillMaxSize().padding(12.dp), channel.name, ContentScale.Fit)
            else Text(channel.name.take(2).uppercase(), color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
        }
        Text(channel.name, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Medium, maxLines = 2)
    }
}

@Composable
private fun Message(text: String) =
    Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) { Text(text, color = TMovieColors.Secondary) }

@Composable
private fun AddListDialog(onDismiss: () -> Unit, onAdd: (String) -> Unit) {
    var url by remember { mutableStateOf("") }
    val valid = url.trim().let { it.startsWith("http://") || it.startsWith("https://") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Thêm danh sách kênh") },
        text = { OutlinedTextField(url, { url = it }, singleLine = true, placeholder = { Text("Link danh sách .m3u") }) },
        confirmButton = { TextButton(onClick = { onAdd(url.trim()) }, enabled = valid) { Text("Thêm") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Huỷ") } },
    )
}
