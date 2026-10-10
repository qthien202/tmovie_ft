package com.thientech.tmovie.core.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.Filter
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import kotlin.coroutines.cancellation.CancellationException

/**
 * Page-by-page loader for grids and feeds, observable from Compose. [include] filters client-side
 * for lists the API can't slice (airing vs completed series); paging continues until enough remain.
 */
class Pager(
    source: Source,
    private val api: PhimApi = PhimApi.shared,
    private val include: (FilmItem) -> Boolean = { true },
) {
    val items = mutableStateListOf<FilmItem>()
    var loading by mutableStateOf(false)
        private set
    var failed by mutableStateOf(false)
        private set
    var source by mutableStateOf(source)
        private set
    var filter by mutableStateOf(Filter())
        private set

    private var page = 0
    private var hasMore = true

    fun update(source: Source = this.source, filter: Filter = this.filter) {
        if (source == this.source && filter == this.filter) return
        this.source = source
        this.filter = filter
        items.clear()
        page = 0
        hasMore = true
        loading = false
        failed = false
    }

    suspend fun loadMore() {
        if (!hasMore || loading) return
        loading = true
        failed = false
        val (source, filter) = this.source to this.filter
        try {
            var added = 0
            repeat(4) {
                if (!hasMore || added >= 8) return@repeat
                val result = api.list(source, page + 1, filter)
                if (source != this.source || filter != this.filter) return  // reset mid-flight
                val seen = items.mapTo(HashSet()) { it.slug }
                val fresh = result.items.filter { include(it) && seen.add(it.slug) }
                items += fresh
                added += fresh.size
                page += 1
                hasMore = result.hasMore
            }
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            failed = true
        } finally {
            if (source == this.source && filter == this.filter) loading = false
        }
    }
}
