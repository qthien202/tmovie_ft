package com.thientech.tmovie.feature.browse

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
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
import com.thientech.tmovie.core.designsystem.Pill
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.player.Player
import com.thientech.tmovie.core.ui.PickerOverlay
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.URL

/** One channel of an extended M3U playlist. */
data class Channel(
    val name: String, val logo: String?, val url: String, val userAgent: String?, val referrer: String?, val geoBlocked: Boolean,
    /** ISO code from iptv-org's `tvg-id` ("VTV1.vn@SD" → "vn"); null for other playlists. */
    val country: String? = null,
    /** `group-title`, split on ";" ("Movies;Series"); iptv-org's "Undefined" counts as none. */
    val categories: List<String> = emptyList(),
)

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
                    country = attr(i, "tvg-id")?.substringBefore('@')?.substringAfterLast('.', "")?.lowercase()?.takeIf { it.length == 2 },
                    categories = attr(i, "group-title")?.split(';')?.map { it.trim() }?.filter { it.isNotEmpty() && it != "Undefined" }.orEmpty(),
                )
                info = null; ua = null; ref = null
            }
        }
    }
    return out
}

/** iptv-org's whole index (~11k channels; every country and category in one file). */
private const val IPTV_ORG = "https://iptv-org.github.io/iptv/index.m3u"
private const val ALL = "iptv-org"

/** iptv-org's categories, in Vietnamese. */
private val categoryNames = mapOf(
    "General" to "Tổng hợp", "News" to "Tin tức", "Entertainment" to "Giải trí", "Movies" to "Phim", "Series" to "Phim bộ",
    "Sports" to "Thể thao", "Kids" to "Thiếu nhi", "Animation" to "Hoạt hình", "Music" to "Âm nhạc", "Documentary" to "Tài liệu",
    "Education" to "Giáo dục", "Comedy" to "Hài", "Culture" to "Văn hoá", "Lifestyle" to "Đời sống", "Classic" to "Kinh điển",
    "Family" to "Gia đình", "Travel" to "Du lịch", "Cooking" to "Ẩm thực", "Outdoor" to "Ngoài trời", "Science" to "Khoa học",
    "Business" to "Kinh doanh", "Auto" to "Ô tô", "Weather" to "Thời tiết", "Relax" to "Thư giãn", "Shop" to "Mua sắm",
    "Religious" to "Tôn giáo", "Legislative" to "Nghị viện", "Public" to "Công cộng", "Interactive" to "Tương tác",
)

private fun categoryName(c: String) = categoryNames[c] ?: c

/** "🇻🇳 Việt Nam" from "vn" (iptv-org writes the UK as "uk"). */
private fun countryName(code: String): String {
    val iso = if (code == "uk") "GB" else code.uppercase()
    val flag = iso.takeIf { it.length == 2 && it.all(Char::isLetter) }?.map { Character.toChars(0x1F1E6 + (it - 'A')).concatToString() }?.joinToString("").orEmpty()
    return "$flag ${java.util.Locale("", iso).getDisplayCountry(java.util.Locale("vi")).ifBlank { iso }}".trim()
}

/** Playlists load once per run: iptv-org's index is 2.5 MB. */
private val cache = HashMap<String, List<Channel>>()

private fun customLists(context: Context) =
    context.getSharedPreferences("live", Context.MODE_PRIVATE).getStringSet("lists", emptySet()).orEmpty().sorted()

private fun saveCustomLists(context: Context, urls: List<String>) =
    context.getSharedPreferences("live", Context.MODE_PRIVATE).edit().putStringSet("lists", urls.toSet()).apply()

/**
 * "Truyền hình": iptv-org's channels by country and category (Việt Nam first), plus M3U lists the
 * user adds. Lists play as published; only DASH, which the player doesn't support, is skipped.
 * Search covers every country.
 */
@Composable
fun LiveTvScreen() {
    val context = LocalContext.current
    var custom by remember { mutableStateOf(customLists(context)) }
    var source by remember { mutableStateOf(ALL) }
    var country by remember { mutableStateOf<String?>("vn") }
    var category by remember { mutableStateOf<String?>(null) }
    var picking by remember { mutableStateOf<String?>(null) }  // "country" / "category"
    var channels by remember { mutableStateOf<List<Channel>?>(null) }
    var failed by remember { mutableStateOf(false) }
    var query by remember { mutableStateOf("") }
    var adding by remember { mutableStateOf(false) }

    LaunchedEffect(source) {
        channels = cache[source]
        failed = false
        if (channels != null) return@LaunchedEffect
        runCatching {
            withContext(Dispatchers.IO) { parseM3u(URL(if (source == ALL) IPTV_ORG else source).readText()).filter { !it.url.contains(".mpd") } }
        }.onSuccess { cache[source] = it; channels = it }.onFailure { failed = true }
    }

    val all = channels.orEmpty()
    val countries = remember(all) { all.mapNotNull { it.country }.groupingBy { it }.eachCount() }
    val categories = remember(all) { all.flatMap { it.categories }.groupingBy { it }.eachCount() }
    val q = query.trim()
    val shown = remember(all, country, category, q) {
        all.filter { c ->
            (q.isNotEmpty() || country == null || c.country == country) &&  // search covers every country
                (category == null || category in c.categories) &&
                (q.isEmpty() || c.name.contains(q, ignoreCase = true))
        }
    }

    Column(Modifier.fillMaxSize()) {
        Column(Modifier.statusBarsPadding().padding(vertical = 8.dp)) {
            Text("Truyền hình", style = TMovieType.Title, color = Color.White, modifier = Modifier.padding(horizontal = 16.dp))
            OutlinedTextField(
                query, { query = it }, singleLine = true,
                placeholder = { Text("Tìm trong ${"%,d".format(all.size).replace(',', '.')} kênh") },
                leadingIcon = { Icon(Icons.Filled.Search, null) },
                shape = CircleShape,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
            )
            // Same pills as Home's header.
            Row(
                Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                if (countries.isNotEmpty()) PickerPill(country?.let(::countryName) ?: "Quốc gia", country != null) { picking = "country" }
                if (categories.isNotEmpty()) PickerPill(category?.let(::categoryName) ?: "Thể loại", category != null) { picking = "category" }
                if (custom.isNotEmpty()) Pill("iptv-org", { source = ALL }, selected = source == ALL)
                custom.forEach { url ->
                    // Long-press removes a list the user added.
                    Pill(android.net.Uri.parse(url).host ?: url, { source = url; country = null; category = null }, selected = source == url,
                        onLongClick = { custom = (custom - url).also { saveCustomLists(context, it) }; if (source == url) source = ALL })
                }
                Pill("＋ Danh sách", { adding = true })
            }
        }

        when {
            failed -> Message("Không tải được danh sách kênh")
            channels == null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = TMovieColors.Brand) }
            shown.isEmpty() -> Message("Không có kênh nào")
            else -> LazyVerticalGrid(
                GridCells.Adaptive(104.dp), Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 120.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp), verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                item(span = { GridItemSpan(maxLineSpan) }) {
                    Text("${shown.size} kênh", color = TMovieColors.Secondary, fontSize = 13.sp)
                }
                items(shown, key = { it.url + it.name }) { ChannelTile(it) }
            }
        }
    }

    when (picking) {
        "country" -> PickerOverlay(
            listOf<Pair<String?, String>>(null to "Tất cả quốc gia") +
                // Việt Nam first, then by name.
                countries.keys.sortedWith(compareBy({ it != "vn" }, { countryName(it).substringAfter(' ') })).map { it to "${countryName(it)} · ${countries[it]}" },
            country, onDismiss = { picking = null },
        ) { country = it; picking = null }
        "category" -> PickerOverlay(
            listOf<Pair<String?, String>>(null to "Tất cả thể loại") +
                categories.keys.sortedBy { categoryName(it) }.map { it to "${categoryName(it)} · ${categories[it]}" },
            category, onDismiss = { picking = null },
        ) { category = it; picking = null }
    }

    if (adding) AddListDialog(onDismiss = { adding = false }) { url ->
        adding = false
        if (url !in custom) custom = (custom + url).also { saveCustomLists(context, it) }
        source = url
        country = null
        category = null
    }
}

@Composable
private fun PickerPill(title: String, selected: Boolean, onClick: () -> Unit) =
    Pill(title, onClick, selected = selected) {
        Icon(Icons.Filled.KeyboardArrowDown, null, tint = if (selected) Color.Black else Color.White, modifier = Modifier.size(18.dp))
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
