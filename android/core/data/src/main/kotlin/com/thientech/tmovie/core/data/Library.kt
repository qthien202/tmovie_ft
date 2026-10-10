package com.thientech.tmovie.core.data

import android.content.Context
import com.thientech.tmovie.core.model.FilmItem
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class SavedFilm(val film: FilmItem, val addedAt: Long)

@Serializable
data class WatchRecord(
    val film: FilmItem,
    val serverIndex: Int = 0,
    val episodeIndex: Int = 0,
    val episodeName: String = "",
    val lastEpisodeSlug: String = "",
    /** Seconds watched / total, per episode slug, for resume and progress bars. */
    val positions: Map<String, Double> = emptyMap(),
    val durations: Map<String, Double> = emptyMap(),
    val updatedAt: Long = 0,
) {
    fun progress(episodeSlug: String): Float {
        val d = durations[episodeSlug] ?: return 0f
        return if (d > 0) ((positions[episodeSlug] ?: 0.0) / d).toFloat().coerceIn(0f, 1f) else 0f
    }

    /** Progress of the episode last played, for "Xem tiếp" cards. */
    val lastProgress: Float get() = progress(lastEpisodeSlug)
}

@Serializable
private data class LibraryFile(val saved: List<SavedFilm> = emptyList(), val history: List<WatchRecord> = emptyList())

/**
 * On-device library (replaces the Flutter Drift tables): My List, watch history, resume points.
 * Held in memory as StateFlows and written to one JSON file shortly after each change.
 */
// ponytail: one JSON file rewritten on change; move to Room if the library grows to thousands of rows.
@OptIn(FlowPreview::class)
object Library {
    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private lateinit var file: File

    private val _saved = MutableStateFlow<List<SavedFilm>>(emptyList())
    private val _history = MutableStateFlow<List<WatchRecord>>(emptyList())

    /** Newest first. */
    val saved: StateFlow<List<SavedFilm>> = _saved.asStateFlow()

    /** Most recently watched first. */
    val history: StateFlow<List<WatchRecord>> = _history.asStateFlow()

    fun init(context: Context) {
        file = File(context.filesDir, "library.json")
        runCatching { json.decodeFromString<LibraryFile>(file.readText()) }.getOrNull()?.let {
            _saved.value = it.saved
            _history.value = it.history
        }
        kotlinx.coroutines.flow.merge(_saved, _history).drop(2).debounce(500).onEach { persist() }.launchIn(scope)
    }

    private fun persist() {
        val tmp = File(file.parentFile, "library.json.tmp")
        tmp.writeText(json.encodeToString(LibraryFile.serializer(), LibraryFile(_saved.value, _history.value)))
        tmp.renameTo(file)
    }

    fun isSaved(slug: String) = _saved.value.any { it.film.slug == slug }

    fun record(slug: String): WatchRecord? = _history.value.firstOrNull { it.film.slug == slug }

    /** Adds or removes from My List; returns the new state. */
    fun toggleSaved(film: FilmItem): Boolean {
        val wasSaved = isSaved(film.slug)
        _saved.update { list ->
            if (wasSaved) list.filterNot { it.film.slug == film.slug }
            else listOf(SavedFilm(film, System.currentTimeMillis())) + list
        }
        return !wasSaved
    }

    /** Called by the player on start, every 10s, on episode switch and on close. */
    fun save(film: FilmItem, server: Int, episode: Int, episodeName: String, episodeSlug: String, position: Double, duration: Double) {
        _history.update { list ->
            val old = list.firstOrNull { it.film.slug == film.slug } ?: WatchRecord(film)
            val new = old.copy(
                film = film,
                serverIndex = server,
                episodeIndex = episode,
                episodeName = episodeName,
                lastEpisodeSlug = episodeSlug,
                positions = if (position > 0) old.positions + (episodeSlug to position) else old.positions,
                durations = if (duration > 0) old.durations + (episodeSlug to duration) else old.durations,
                updatedAt = System.currentTimeMillis(),
            )
            listOf(new) + list.filterNot { it.film.slug == film.slug }
        }
    }

    /**
     * Merges synced entries in: missing films are added, newer history wins. Playback positions
     * from the Flutter app are keyed `{slug}_{episodeName}`, so they are stored under the episode name.
     */
    internal fun mergeRemote(favorites: List<LibrarySync.Entry>, history: List<LibrarySync.Entry>, playback: Map<String, Double>) {
        _saved.update { local ->
            val known = local.map { it.film.slug }.toSet()
            (local + favorites.filter { it.film.slug !in known }.map { SavedFilm(it.film, it.timestamp) }).sortedByDescending { it.addedAt }
        }
        _history.update { local ->
            val bySlug = local.associateBy { it.film.slug }.toMutableMap()
            history.forEach { e ->
                val existing = bySlug[e.film.slug]
                if (existing == null || existing.updatedAt < e.timestamp) {
                    val name = e.episode.orEmpty()
                    val positions = playback.filterKeys { it.startsWith("${e.film.slug}_") }.mapKeys { it.key.removePrefix("${e.film.slug}_") }
                    bySlug[e.film.slug] = (existing ?: WatchRecord(e.film)).copy(
                        episodeName = name,
                        lastEpisodeSlug = existing?.lastEpisodeSlug?.takeIf { existing.episodeName == name } ?: name,
                        positions = (existing?.positions.orEmpty()) + positions,
                        updatedAt = e.timestamp,
                    )
                }
            }
            bySlug.values.sortedByDescending { it.updatedAt }
        }
    }

    fun remove(slug: String) = _history.update { list -> list.filterNot { it.film.slug == slug } }
    fun clearHistory() { _history.value = emptyList() }
    fun clearSaved() { _saved.value = emptyList() }
}
