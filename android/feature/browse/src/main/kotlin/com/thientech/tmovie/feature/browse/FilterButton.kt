package com.thientech.tmovie.feature.browse

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
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
import androidx.compose.ui.unit.dp
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmCategory
import com.thientech.tmovie.core.network.Filter
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.ui.Pager
import java.time.Year

/** Filters a [Pager] by sort, year, genre and country; a submenu per dimension. */
@Composable
fun FilterButton(pager: Pager, source: Source, reload: () -> Unit) {
    var open by remember { mutableStateOf(false) }
    var sub by remember { mutableStateOf<String?>(null) }
    var genres by remember { mutableStateOf<List<FilmCategory>>(emptyList()) }
    var countries by remember { mutableStateOf<List<FilmCategory>>(emptyList()) }
    LaunchedEffect(Unit) {
        genres = runCatching { PhimApi.shared.taxonomy(PhimApi.Taxonomy.Genres) }.getOrDefault(emptyList())
        countries = runCatching { PhimApi.shared.taxonomy(PhimApi.Taxonomy.Countries) }.getOrDefault(emptyList())
    }
    fun apply(f: Filter) { pager.update(filter = f); open = false; sub = null; reload() }
    val f = pager.filter

    Box {
        Box(Modifier.size(40.dp).clip(CircleShape).glass(CircleShape, tint = if (f != Filter()) TMovieColors.Brand else null).clickable { open = true },
            contentAlignment = Alignment.Center) { Icon(Icons.Filled.FilterList, "Bộ lọc", tint = Color.White) }
        DropdownMenu(open, onDismissRequest = { open = false; sub = null }) {
            when (sub) {
                null -> {
                    listOf(null to "Mới cập nhật", "year" to "Năm phát hành", "_id" to "Mới thêm").forEach { (key, label) ->
                        DropdownMenuItem({ Text(label) }, { apply(f.copy(sortField = key)) },
                            trailingIcon = { if (f.sortField == key) Icon(Icons.Filled.Check, null) })
                    }
                    HorizontalDivider()
                    DropdownMenuItem({ Text("Năm" + (f.year?.let { ": $it" } ?: "")) }, { sub = "year" }, trailingIcon = { Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null) })
                    if (source !is Source.Country) DropdownMenuItem({ Text("Quốc gia") }, { sub = "country" }, trailingIcon = { Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null) })
                    if (source !is Source.Genre) DropdownMenuItem({ Text("Thể loại") }, { sub = "genre" }, trailingIcon = { Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null) })
                    if (f != Filter()) DropdownMenuItem({ Text("Bỏ lọc", color = Color(0xFFFF6B6B)) }, { apply(Filter()) })
                }
                "year" -> {
                    DropdownMenuItem({ Text("Tất cả") }, { apply(f.copy(year = null)) })
                    (Year.now().value downTo 2000).forEach { y -> DropdownMenuItem({ Text("$y") }, { apply(f.copy(year = y)) }) }
                }
                "genre" -> {
                    DropdownMenuItem({ Text("Tất cả") }, { apply(f.copy(category = null)) })
                    genres.forEach { g -> DropdownMenuItem({ Text(g.name.orEmpty()) }, { apply(f.copy(category = g.slug)) }) }
                }
                "country" -> {
                    DropdownMenuItem({ Text("Tất cả") }, { apply(f.copy(country = null)) })
                    countries.forEach { c -> DropdownMenuItem({ Text(c.name.orEmpty()) }, { apply(f.copy(country = c.slug)) }) }
                }
            }
        }
    }
}
