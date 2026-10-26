package com.thientech.tmovie.tv

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.Backspace
import androidx.compose.material.icons.rounded.SpaceBar
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import kotlinx.coroutines.delay

private val keys = "abcdefghijklmnopqrstuvwxyz1234567890".map(Char::toString)

/**
 * Netflix-style search: an on-screen keyboard on the left (no system keyboard to fight with the
 * remote; PhimAPI matches without diacritics), results on the right as you type.
 */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun SearchTab(onOpen: (FilmItem) -> Unit, editRequest: Int = 0) {
    var query by rememberSaveable { mutableStateOf("") }
    var results by remember { mutableStateOf<List<FilmItem>?>(null) }
    val firstKey = remember { FocusRequester() }
    LaunchedEffect(query) {
        val q = query.trim()
        if (q.isNotEmpty()) delay(400)
        results = null
        val source = if (q.isEmpty()) Source.Type("phim-moi-cap-nhat") else Source.Search(q)
        results = runCatching { PhimApi.shared.list(source).items }.getOrDefault(emptyList())
    }
    // The remote's search key lands on the keyboard.
    LaunchedEffect(editRequest) {
        if (editRequest == 0) return@LaunchedEffect
        repeat(10) { withFrameNanos {}; if (runCatching { firstKey.requestFocus() }.isSuccess) return@LaunchedEffect }
    }

    Row(Modifier.fillMaxSize().padding(start = Tv.Start, top = 40.dp)) {
        Column(Modifier.width(318.dp).focusRestorer(firstKey)) {
            Text("Tìm kiếm", color = Color.White, fontSize = 30.sp, fontWeight = FontWeight.Bold)
            Box(
                Modifier.padding(top = 16.dp, bottom = 16.dp).fillMaxWidth().height(52.dp)
                    .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(10.dp)).padding(horizontal = 16.dp),
                contentAlignment = Alignment.CenterStart,
            ) {
                Text(
                    if (query.isEmpty()) "Tên phim, diễn viên…" else "$query▏",
                    color = if (query.isEmpty()) TMovieColors.Secondary else Color.White, fontSize = 22.sp,
                    maxLines = 1, overflow = TextOverflow.StartEllipsis,
                )
            }
            keys.chunked(6).forEachIndexed { r, row ->
                Row(Modifier.padding(bottom = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    row.forEachIndexed { c, k ->
                        Key(Modifier.size(46.dp), focus = if (r == 0 && c == 0) firstKey else null, onClick = { query += k }) { fg ->
                            Text(k.uppercase(), color = fg, fontSize = 20.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Key(Modifier.width(154.dp).height(46.dp), onClick = { if (query.isNotEmpty() && !query.endsWith(" ")) query += " " }) { fg ->
                    Icon(Icons.Rounded.SpaceBar, "Dấu cách", tint = fg)
                }
                Key(Modifier.width(100.dp).height(46.dp), onClick = { query = query.dropLast(1) }) { fg ->
                    Icon(Icons.AutoMirrored.Rounded.Backspace, "Xoá", tint = fg, modifier = Modifier.size(22.dp))
                }
                Key(Modifier.width(46.dp).height(46.dp), onClick = { query = "" }) { fg -> Text("✕", color = fg, fontSize = 18.sp, fontWeight = FontWeight.Bold) }
            }
        }
        Column(Modifier.weight(1f).padding(start = 32.dp)) {
            Text(
                if (query.isBlank()) "Mới cập nhật" else "Kết quả cho “${query.trim()}”",
                color = Color.White.copy(alpha = 0.9f), fontSize = 20.sp, fontWeight = FontWeight.SemiBold, maxLines = 1,
                modifier = Modifier.padding(top = 8.dp),
            )
            val list = results
            when {
                list == null -> Box(Modifier.fillMaxSize()) { CircularProgressIndicator(Modifier.align(Alignment.Center), color = TMovieColors.BrandLight) }
                list.isEmpty() -> Text("Không tìm thấy phim nào. Thử gõ tên khác, không cần dấu.", color = TMovieColors.Secondary, fontSize = 18.sp, modifier = Modifier.padding(top = 24.dp))
                else -> LazyVerticalGrid(
                    GridCells.Fixed(3),
                    Modifier.focusRestorer(),
                    contentPadding = PaddingValues(end = Tv.End, top = 18.dp, bottom = 48.dp),
                    horizontalArrangement = Arrangement.spacedBy(18.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) { items(list, { it.slug }) { f -> WideCard(f, { onOpen(f) }, Modifier.fillMaxWidth()) } }
            }
        }
    }
}

@Composable
private fun Key(modifier: Modifier, focus: FocusRequester? = null, onClick: () -> Unit, content: @Composable (Color) -> Unit) {
    FocusCard(onClick, modifier, RoundedCornerShape(8.dp), scale = 1.12f, focusRequester = focus ?: remember { FocusRequester() }) { focused ->
        Box(Modifier.fillMaxSize().background(if (focused) Color.White else Color.White.copy(alpha = 0.08f)), Alignment.Center) {
            content(if (focused) Color.Black else Color.White)
        }
    }
}
