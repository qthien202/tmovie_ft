package com.thientech.tmovie.tv

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.FilmItem
import kotlinx.coroutines.delay

/** What's been watched (with progress) and My List, like the phone's "Của tôi"; history can be cleared. */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun HistoryTab(onOpen: (FilmItem) -> Unit) {
    val history by Library.history.collectAsStateWithLifecycle()
    val saved by Library.saved.collectAsStateWithLifecycle()
    var showSaved by rememberSaveable { mutableStateOf(false) }
    // Clearing takes a second press, so one stray OK doesn't wipe it.
    var confirm by remember { mutableStateOf(false) }
    LaunchedEffect(confirm) { if (confirm) { delay(3_000); confirm = false } }
    val first = remember { FocusRequester() }

    Column(Modifier.fillMaxSize().padding(top = 36.dp)) {
        Row(Modifier.padding(start = Tv.Start).focusRestorer(first), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Chip("Đã xem · ${history.size}", { showSaved = false }, selected = !showSaved, focusRequester = first)
            Chip("Danh sách của tôi · ${saved.size}", { showSaved = true }, selected = showSaved)
            if (!showSaved && history.isNotEmpty()) {
                Chip(if (confirm) "Nhấn lần nữa để xoá" else "Xoá lịch sử", { if (confirm) { Library.clearHistory(); confirm = false } else confirm = true })
            }
        }
        val empty = if (showSaved) saved.isEmpty() else history.isEmpty()
        if (empty) {
            Text(
                if (showSaved) "Chưa có phim nào. Bấm + ở trang phim để thêm vào danh sách." else "Chưa xem phim nào. Phim bạn xem sẽ hiện ở đây để xem tiếp.",
                color = TMovieColors.Secondary, fontSize = 18.sp, modifier = Modifier.padding(start = Tv.Start, top = 32.dp),
            )
            return@Column
        }
        LazyVerticalGrid(
            GridCells.Fixed(4),
            Modifier.focusRestorer(),
            contentPadding = PaddingValues(start = Tv.Start, end = Tv.End, top = 24.dp, bottom = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            if (showSaved) items(saved, { it.film.slug }) { WideCard(it.film, { onOpen(it.film) }, Modifier.fillMaxWidth()) }
            else items(history, { it.film.slug }) { ContinueCard(it, { onOpen(it.film) }, Modifier.fillMaxWidth()) }
        }
    }
}
