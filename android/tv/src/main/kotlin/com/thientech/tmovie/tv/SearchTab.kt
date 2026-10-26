package com.thientech.tmovie.tv

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Search
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.foundation.clickable
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import kotlinx.coroutines.delay

/** One search field (the TV's own keyboard or voice) over a grid of posters; empty shows what's new. */
@Composable
fun SearchTab(onOpen: (FilmItem) -> Unit) {
    var query by rememberSaveable { mutableStateOf("") }
    var results by remember { mutableStateOf<List<FilmItem>?>(null) }
    val focusManager = LocalFocusManager.current
    LaunchedEffect(query) {
        val q = query.trim()
        if (q.isNotEmpty()) delay(450)
        results = null
        val source = if (q.isEmpty()) Source.Type("phim-moi-cap-nhat") else Source.Search(q)
        results = runCatching { PhimApi.shared.list(source).items }.getOrDefault(emptyList())
    }

    Column(Modifier.fillMaxSize().padding(top = 40.dp)) {
        SearchField(query, { query = it }, onDone = { focusManager.moveFocus(FocusDirection.Down) })
        Text(
            if (query.isBlank()) "Mới cập nhật" else "Kết quả cho “${query.trim()}”",
            color = Color.White.copy(alpha = 0.9f), fontSize = 20.sp,
            modifier = Modifier.padding(start = Tv.Start, top = 28.dp, bottom = 4.dp),
        )
        val list = results
        when {
            list == null -> Box(Modifier.fillMaxSize()) { CircularProgressIndicator(Modifier.align(Alignment.Center), color = TMovieColors.BrandLight) }
            list.isEmpty() -> Text("Không tìm thấy phim nào", color = TMovieColors.Secondary, fontSize = 18.sp, modifier = Modifier.padding(start = Tv.Start, top = 24.dp))
            else -> LazyVerticalGrid(
                GridCells.Adaptive(Tv.PosterWidth),
                contentPadding = PaddingValues(start = Tv.Start, end = Tv.End, top = 16.dp, bottom = 48.dp),
                horizontalArrangement = Arrangement.spacedBy(20.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp),
            ) { items(list, { it.slug }) { f -> PosterCard(f, { onOpen(f) }) } }
        }
    }
}

/**
 * The field only takes text focus (and the on-screen keyboard) on OK, so moving focus across it
 * doesn't pop the keyboard; leaving it (or the keyboard's search key) ends editing.
 */
@Composable
private fun SearchField(value: String, onChange: (String) -> Unit, onDone: () -> Unit) {
    val field = remember { FocusRequester() }
    var editing by remember { mutableStateOf(false) }
    var focused by remember { mutableStateOf(false) }
    var typing by remember { mutableStateOf(false) }
    LaunchedEffect(editing) { if (editing) runCatching { field.requestFocus() } }
    Row(
        Modifier
            .padding(start = Tv.Start, end = Tv.End)
            .fillMaxWidth(0.6f)
            .height(60.dp)
            .background(Color.White.copy(alpha = if (focused || typing) 0.16f else 0.08f), CircleShape)
            .border(2.dp, if (focused || typing) Color.White else Color.Transparent, CircleShape)
            .onFocusChanged { focused = it.isFocused }
            .clickable(remember { MutableInteractionSource() }, indication = null) { editing = true }
            .padding(horizontal = 22.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Icon(Icons.Rounded.Search, null, tint = if (focused || typing) Color.White else TMovieColors.Secondary, modifier = Modifier.size(28.dp))
        Box {
            if (value.isEmpty()) Text("Tên phim, diễn viên…", color = TMovieColors.Secondary, fontSize = 22.sp)
            BasicTextField(
                value, onChange,
                singleLine = true,
                textStyle = TextStyle(color = Color.White, fontSize = 22.sp),
                cursorBrush = SolidColor(TMovieColors.BrandLight),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { onDone() }),
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(field)
                    .focusProperties { canFocus = editing }
                    .onFocusChanged { if (typing && !it.isFocused) editing = false; typing = it.isFocused },
            )
        }
    }
}
