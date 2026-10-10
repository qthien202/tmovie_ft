package com.thientech.tmovie.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// PhimAPI models (https://phimapi.com/v1/api). Only the fields the app reads; unknown keys are ignored.

@Serializable
data class FilmCategory(
    val id: String? = null,
    val name: String? = null,
    val slug: String? = null,
) {
    companion object {
        /** The "Phim 18+" genre, which the app never lists or shows. PhimAPI uses `phim-18`, OPhim used `18-plus`. */
        val adultSlugs = setOf("phim-18", "18-plus")
    }
}

@Serializable
data class TmdbInfo(
    val type: String? = null,
    @Serializable(LooseStringSerializer::class) val id: String? = null,
    val season: Int? = null,
    @SerialName("vote_average") val voteAverage: Double? = null,
    @SerialName("vote_count") val voteCount: Int? = null,
)

@Serializable
data class ImdbInfo(
    @Serializable(LooseStringSerializer::class) val id: String? = null,
    @SerialName("vote_average") val voteAverage: Double? = null,
    @SerialName("vote_count") val voteCount: Int? = null,
)

/** List item from `/danh-sach`, `/the-loai`, `/quoc-gia`, `/tim-kiem`. */
@Serializable
data class FilmItem(
    val name: String,
    val slug: String,
    @SerialName("origin_name") val originName: String? = null,
    val type: String? = null,
    @SerialName("thumb_url") val thumbUrl: String? = null,
    @SerialName("poster_url") val posterUrl: String? = null,
    val time: String? = null,
    @SerialName("episode_current") val episodeCurrent: String? = null,
    val quality: String? = null,
    val lang: String? = null,
    val year: Int? = null,
    val category: List<FilmCategory>? = null,
    val country: List<FilmCategory>? = null,
    val tmdb: TmdbInfo? = null,
    val imdb: ImdbInfo? = null,
) {
    val thumbImage: String? get() = phimImageUrl(thumbUrl)
    val posterImage: String? get() = phimImageUrl(posterUrl)

    /** Hidden everywhere. */
    val isAdult: Boolean get() = category.orEmpty().any { it.slug in FilmCategory.adultSlugs }

    /** Trailer-only entries; shown only in the "Sắp chiếu" list. */
    val isTrailer: Boolean get() = episodeCurrent?.lowercase() == "trailer"

    /** Donghua / anime, kept out of the hero. */
    val isAnimation: Boolean
        get() = type?.lowercase() == "hoathinh" || category.orEmpty().any {
            it.slug == "hoat-hinh" || it.name.orEmpty().lowercase().contains("hoạt hình")
        }

    /** TMDB score, else IMDb, when either is above zero. */
    val rating: Double? get() = listOfNotNull(tmdb?.voteAverage, imdb?.voteAverage).firstOrNull { it > 0 }
}

/** `/phim/{slug}` → `data.item`. */
@Serializable
data class FilmDetail(
    val name: String,
    val slug: String,
    @SerialName("origin_name") val originName: String? = null,
    val content: String? = null,
    val type: String? = null,
    val status: String? = null,
    @SerialName("thumb_url") val thumbUrl: String? = null,
    @SerialName("poster_url") val posterUrl: String? = null,
    @SerialName("trailer_url") val trailerUrl: String? = null,
    val time: String? = null,
    @SerialName("episode_current") val episodeCurrent: String? = null,
    @SerialName("episode_total") @Serializable(LooseStringSerializer::class) val episodeTotal: String? = null,
    val quality: String? = null,
    val lang: String? = null,
    val year: Int? = null,
    val view: Int? = null,
    val actor: List<String>? = null,
    val director: List<String>? = null,
    val category: List<FilmCategory>? = null,
    val country: List<FilmCategory>? = null,
    val episodes: List<Episode>? = null,
    val tmdb: TmdbInfo? = null,
    val imdb: ImdbInfo? = null,
) {
    /** The list-item view, for saving to My List / history and for routing. */
    fun toItem() = FilmItem(
        name = name, slug = slug, originName = originName, type = type, thumbUrl = thumbUrl, posterUrl = posterUrl,
        time = time, episodeCurrent = episodeCurrent, quality = quality, lang = lang, year = year,
        category = category, country = country, tmdb = tmdb, imdb = imdb,
    )

    /** Whether any episode on any server has an HLS link. */
    val isPlayable: Boolean get() = episodes.orEmpty().any { s -> s.serverData.orEmpty().any { it.streamUrl != null } }
}

/** One server (Vietsub, Thuyết minh, ...) with its episode list. */
@Serializable
data class Episode(
    @SerialName("server_name") val serverName: String? = null,
    @SerialName("server_data") val serverData: List<ServerData>? = null,
)

@Serializable
data class ServerData(
    val name: String? = null,
    val slug: String? = null,
    val filename: String? = null,
    @SerialName("link_embed") val linkEmbed: String? = null,
    @SerialName("link_m3u8") val linkM3u8: String? = null,
) {
    /** HLS only: `link_embed` is a web page ExoPlayer cannot play. */
    val streamUrl: String? get() = linkM3u8?.takeIf { it.isNotBlank() }
}

/** TMDB image from `/phim/{slug}/images`. */
@Serializable
data class FilmImage(
    val width: Int? = null,
    val height: Int? = null,
    @SerialName("aspect_ratio") val aspectRatio: Double? = null,
    val type: String? = null,
    @SerialName("file_path") val filePath: String? = null,
    @SerialName("iso_639_1") val iso6391: String? = null,
) {
    fun url(size: String = "w780"): String? = tmdbImageUrl(filePath, size)
}

/** Cast member from `/phim/{slug}/peoples`. */
@Serializable
data class FilmPerson(
    val name: String? = null,
    @SerialName("original_name") val originalName: String? = null,
    val character: String? = null,
    @SerialName("known_for_department") val knownForDepartment: String? = null,
    @SerialName("profile_path") val profilePath: String? = null,
) {
    fun profileUrl(size: String = "w185"): String? = tmdbImageUrl(profilePath, size)
}

/** One page of a list endpoint. */
data class FilmPage(val items: List<FilmItem>, val currentPage: Int, val totalPages: Int) {
    val hasMore: Boolean get() = currentPage < totalPages
}
