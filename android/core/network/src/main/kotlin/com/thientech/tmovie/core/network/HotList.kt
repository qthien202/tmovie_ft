package com.thientech.tmovie.core.network

import com.thientech.tmovie.core.model.ContentPolicy
import com.thientech.tmovie.core.model.FilmItem
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import okhttp3.Request

/**
 * What's hot in Vietnam right now: Netflix's weekly Top 10 (TV + films) matched to PhimAPI films
 * by `tools/hot/crawl_hot.py`, which a GitHub Action publishes every 6 hours on `hot-data`.
 */
data class HotList(val films: List<FilmItem>, val series: List<FilmItem>, val week: String?) {
    companion object {
        private const val URL = "https://raw.githubusercontent.com/qthien202/tmovie_ft/hot-data/hot.json"

        @Serializable private class File(val week: String? = null, val items: List<Entry> = emptyList())
        @Serializable private class Entry(val kind: String = "", val film: FilmItem)

        suspend fun fetch(): HotList? = runCatching {
            withContext(Dispatchers.IO) {
                val body = PhimApi.defaultClient.newCall(Request.Builder().url(URL).build()).execute().use {
                    if (!it.isSuccessful) return@withContext null
                    it.body?.string()
                } ?: return@withContext null
                parse(body)
            }
        }.getOrNull()

        fun parse(body: String): HotList {
            val file = PhimApi.json.decodeFromString(File.serializer(), body)
            val entries = file.items.filter { ContentPolicy.visible(it.film) }
            return HotList(entries.map { it.film }, entries.filter { it.kind == "tv" }.map { it.film }, file.week)
        }
    }
}
