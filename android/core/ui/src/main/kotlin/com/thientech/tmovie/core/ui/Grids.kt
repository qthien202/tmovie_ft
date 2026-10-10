package com.thientech.tmovie.core.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridScope
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.layout
import androidx.compose.ui.unit.dp
import com.thientech.tmovie.core.designsystem.TMovieColors

/**
 * Poster cells for a 3-column `LazyVerticalGrid` fed by a [Pager]; reaching the last cell loads
 * the next page. Put headers and shelves in the same grid with full-span items.
 */
fun LazyGridScope.posterItems(pager: Pager, idPrefix: String, onLoadMore: () -> Unit) {
    items(pager.items, key = { "$idPrefix/${it.slug}" }) { film ->
        PosterCard(film, "$idPrefix/${film.slug}", width = null)
        if (film.slug == pager.items.lastOrNull()?.slug) LaunchedEffect(pager.items.size) { onLoadMore() }
    }
    item(span = { GridItemSpan(maxLineSpan) }, key = "$idPrefix/footer") {
        Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
            when {
                pager.loading -> CircularProgressIndicator(color = TMovieColors.Brand)
                pager.failed -> OutlinedButton(onClick = onLoadMore) { Text("Thử lại") }
            }
        }
    }
}

fun LazyGridScope.fullSpan(key: Any, content: @androidx.compose.runtime.Composable () -> Unit) {
    item(key = key, span = { GridItemSpan(maxLineSpan) }) { content() }
}

/** Lets a full-span item ignore the grid's horizontal content padding (for edge-to-edge shelves). */
fun androidx.compose.ui.Modifier.bleed(horizontal: androidx.compose.ui.unit.Dp): androidx.compose.ui.Modifier =
    this.then(
        androidx.compose.ui.Modifier.layout { measurable, constraints ->
            val extra = horizontal.roundToPx()
            val placeable = measurable.measure(
                constraints.copy(minWidth = constraints.minWidth + 2 * extra, maxWidth = constraints.maxWidth + 2 * extra),
            )
            layout(constraints.maxWidth, placeable.height) { placeable.place(-extra, 0) }
        },
    )
