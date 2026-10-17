package com.thientech.tmovie.core.ui

import androidx.compose.animation.AnimatedVisibilityScope
import androidx.compose.animation.SharedTransitionScope
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.Source
import kotlinx.serialization.Serializable

// Type-safe routes. Features only emit these; the app's NavHost maps them to screens,
// so features never depend on each other (same idea as iOS AppRouter).

@Serializable data object HomeRoute
@Serializable data object NewHotRoute
@Serializable data object LiveRoute
@Serializable data object SearchRoute
@Serializable data object ProfileRoute

/** A film; `sourceId` keys the shared-element transition from the card that was tapped. */
@Serializable
data class FilmRoute(
    val slug: String,
    val name: String,
    val thumb: String? = null,
    val poster: String? = null,
    val sourceId: String,
)

/** A paginated category: kind is "type", "genre" or "country". */
@Serializable
data class ListRoute(val title: String, val kind: String, val slug: String) {
    val source: Source
        get() = when (kind) {
            "genre" -> Source.Genre(slug)
            "country" -> Source.Country(slug)
            else -> Source.Type(slug)
        }

    companion object {
        fun type(title: String, slug: String) = ListRoute(title, "type", slug)
        fun genre(title: String, slug: String) = ListRoute(title, "genre", slug)
        fun country(title: String, slug: String) = ListRoute(title, "country", slug)
    }
}

fun FilmItem.route(sourceId: String) = FilmRoute(slug, name, thumbImage, posterImage, sourceId)

/** How screens push; provided by the app around its NavHost. */
class Navigator(
    val openFilm: (FilmRoute) -> Unit,
    val openList: (ListRoute) -> Unit,
    val back: () -> Unit,
)

val LocalNavigator = staticCompositionLocalOf { Navigator({}, {}, {}) }

// Shared-element transitions (the iOS zoom from poster to detail).
val LocalSharedScope = compositionLocalOf<SharedTransitionScope?> { null }
val LocalAnimatedScope = compositionLocalOf<AnimatedVisibilityScope?> { null }

/** Marks this view as the shared element for [key] between a card and the detail header. */
fun Modifier.sharedFilm(key: String): Modifier = composed {
    val shared = LocalSharedScope.current
    val animated = LocalAnimatedScope.current
    if (shared == null || animated == null) return@composed this
    with(shared) {
        this@composed.sharedBounds(rememberSharedContentState("film-$key"), animatedVisibilityScope = animated)
    }
}

@Composable
fun rememberNavigator(): Navigator = LocalNavigator.current
