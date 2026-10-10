package com.thientech.tmovie.core.data

import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestore
import com.thientech.tmovie.core.model.FilmItem
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * Two-way sync of the library with the Flutter app's Firestore layout:
 * `users/{uid}/favorites/{slug}` and `users/{uid}/history/{slug}` hold
 * `{slug, name, originName, thumbUrl, episode, timestamp}`, and
 * `users/{uid}/playback/{slug}_{episodeName}` holds `{position}` in seconds.
 * On sign-in remote entries are merged in (newest wins); afterwards local changes are pushed.
 */
@OptIn(FlowPreview::class)
internal object LibrarySync {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var job: Job? = null

    fun start(uid: String) {
        job?.cancel()
        job = scope.launch {
            val user = FirebaseFirestore.getInstance().collection("users").document(uid)
            runCatching {
                val favorites = user.collection("favorites").get().await().documents.mapNotNull { it.entry() }
                val history = user.collection("history").get().await().documents.mapNotNull { it.entry() }
                val playback = user.collection("playback").get().await().documents
                    .associate { it.id to (it.getDouble("position") ?: 0.0) }
                Library.mergeRemote(favorites, history, playback)
            }

            var pushedSaved = Library.saved.value.map { it.film.slug }.toSet()
            launch {
                Library.saved.drop(1).collect { list ->
                    val now = list.associateBy { it.film.slug }
                    (now.keys - pushedSaved).forEach { slug ->
                        val s = now.getValue(slug)
                        runCatching { user.collection("favorites").document(slug).set(s.film.toEntry(null, s.addedAt)).await() }
                    }
                    (pushedSaved - now.keys).forEach { slug -> runCatching { user.collection("favorites").document(slug).delete().await() } }
                    pushedSaved = now.keys
                }
            }

            var pushedHistory = Library.history.value.associate { it.film.slug to it.updatedAt }
            launch {
                Library.history.drop(1).debounce(3000).collect { list ->
                    list.filter { pushedHistory[it.film.slug] != it.updatedAt }.forEach { r ->
                        runCatching {
                            user.collection("history").document(r.film.slug).set(r.film.toEntry(r.episodeName, r.updatedAt)).await()
                            r.positions[r.lastEpisodeSlug]?.let { pos ->
                                user.collection("playback").document("${r.film.slug}_${r.episodeName}").set(mapOf("position" to pos.toInt())).await()
                            }
                        }
                    }
                    val now = list.map { it.film.slug }.toSet()
                    (pushedHistory.keys - now).forEach { slug -> runCatching { user.collection("history").document(slug).delete().await() } }
                    pushedHistory = list.associate { it.film.slug to it.updatedAt }
                }
            }
        }
    }

    fun stop() {
        job?.cancel()
        job = null
    }

    /** A favorite / history doc in the Flutter `WatchHistoryEntry` shape. */
    class Entry(val film: FilmItem, val episode: String?, val timestamp: Long)

    private fun DocumentSnapshot.entry(): Entry? {
        val slug = getString("slug") ?: return null
        val name = getString("name") ?: return null
        val film = FilmItem(name = name, slug = slug, originName = getString("originName"), thumbUrl = getString("thumbUrl"))
        return Entry(film, getString("episode"), getLong("timestamp") ?: 0L)
    }

    private fun FilmItem.toEntry(episode: String?, timestamp: Long) = mapOf(
        "slug" to slug,
        "name" to name,
        "originName" to originName,
        "thumbUrl" to (thumbUrl ?: posterUrl),
        "episode" to episode,
        "description" to null,
        "timestamp" to timestamp,
    )
}
