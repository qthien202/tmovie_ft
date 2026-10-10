package com.thientech.tmovie.core.network

import com.thientech.tmovie.core.model.ContentPolicy
import com.thientech.tmovie.core.model.FilmCategory
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.model.FilmImage
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.model.FilmPage
import com.thientech.tmovie.core.model.FilmPerson
import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request

/** Paginated list sources, same as Flutter's `PaginatedSource` and iOS `PhimAPI.Source`. */
sealed interface Source {
    data class Type(val slug: String) : Source       // /danh-sach/{slug}: phim-moi-cap-nhat, phim-bo, ...
    data class Genre(val slug: String) : Source      // /the-loai/{slug}
    data class Country(val slug: String) : Source    // /quoc-gia/{slug}
    data class Search(val keyword: String) : Source  // /tim-kiem?keyword=
}

data class Filter(
    val category: String? = null,
    val country: String? = null,
    val year: Int? = null,
    val sortField: String? = null,
)

class HttpException(val code: Int) : IOException("HTTP $code")

/** Client for https://phimapi.com (port of the Flutter `ApiService`). */
class PhimApi(
    private val client: OkHttpClient = defaultClient,
    private val baseUrl: String = "https://phimapi.com/v1/api",
) {
    suspend fun list(source: Source, page: Int = 1, filter: Filter = Filter()): FilmPage =
        // "Sắp chiếu" is all trailers by definition, so only that list keeps them.
        parsePage(get(listUrl(source, page, filter)), keepTrailers = source == Source.Type("phim-sap-chieu"))

    suspend fun detail(slug: String): FilmDetail =
        json.decodeFromString<Envelope<DetailData>>(get(url("phim/$slug"))).data.item

    suspend fun images(slug: String): List<FilmImage> =
        json.decodeFromString<Envelope<ImagesData>>(get(url("phim/$slug/images"))).data.images.orEmpty()

    suspend fun peoples(slug: String): List<FilmPerson> =
        json.decodeFromString<Envelope<PeoplesData>>(get(url("phim/$slug/peoples"))).data.peoples.orEmpty()

    /** All genres (`/the-loai`) or countries (`/quoc-gia`); these live at the site root. */
    suspend fun taxonomy(kind: Taxonomy): List<FilmCategory> {
        val root = baseUrl.toHttpUrl().newBuilder().encodedPath("/").addPathSegment(kind.path).build()
        return json.decodeFromString<Envelope<TaxonomyData>>(get(root)).data.items.filter { ContentPolicy.visible(it) }
    }

    enum class Taxonomy(val path: String) { Genres("the-loai"), Countries("quoc-gia") }

    fun listUrl(source: Source, page: Int, filter: Filter): HttpUrl {
        val b = baseUrl.toHttpUrl().newBuilder()
        when (source) {
            is Source.Type -> b.addPathSegments("danh-sach/${source.slug}")
            is Source.Genre -> b.addPathSegments("the-loai/${source.slug}")
            is Source.Country -> b.addPathSegments("quoc-gia/${source.slug}")
            is Source.Search -> b.addPathSegment("tim-kiem")
        }
        b.addQueryParameter("page", page.toString())
        if (source is Source.Search) b.addQueryParameter("keyword", source.keyword)
        filter.category?.let { b.addQueryParameter("category", it) }
        filter.country?.let { b.addQueryParameter("country", it) }
        filter.year?.let { b.addQueryParameter("year", it.toString()) }
        filter.sortField?.let { b.addQueryParameter("sort_field", it) }
        return b.build()
    }

    private fun url(path: String): HttpUrl = baseUrl.toHttpUrl().newBuilder().addPathSegments(path).build()

    private suspend fun get(url: HttpUrl): String = withContext(Dispatchers.IO) {
        client.newCall(Request.Builder().url(url).build()).execute().use { res ->
            if (!res.isSuccessful) throw HttpException(res.code)
            res.body?.string() ?: throw HttpException(res.code)
        }
    }

    companion object {
        val shared by lazy { PhimApi() }

        val defaultClient: OkHttpClient = OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()

        val json = Json {
            ignoreUnknownKeys = true
            coerceInputValues = true
            explicitNulls = false
        }

        /** Drops adult titles (unless the account allows them) and trailer-only titles unless [keepTrailers]. */
        fun parsePage(body: String, keepTrailers: Boolean = false): FilmPage {
            val data = json.decodeFromString<Envelope<ListData>>(body).data
            val p = data.params?.pagination
            val perPage = p?.totalItemsPerPage ?: 0
            val computed = if (perPage > 0) ((p?.totalItems ?: 0) + perPage - 1) / perPage else 0
            return FilmPage(
                items = data.items.filter { ContentPolicy.visible(it) && (keepTrailers || !it.isTrailer) },
                currentPage = p?.currentPage ?: 1,
                totalPages = p?.totalPages ?: computed,
            )
        }
    }
}

@Serializable internal class Envelope<T>(val data: T)
@Serializable internal class ListData(val items: List<FilmItem> = emptyList(), val params: Params? = null)
@Serializable internal class Params(val pagination: Pagination? = null)
@Serializable internal class Pagination(
    val totalItems: Int? = null,
    val totalItemsPerPage: Int? = null,
    val currentPage: Int? = null,
    val totalPages: Int? = null,
)
@Serializable internal class DetailData(val item: FilmDetail)
@Serializable internal class ImagesData(val images: List<FilmImage>? = null)
@Serializable internal class PeoplesData(val peoples: List<FilmPerson>? = null)
@Serializable internal class TaxonomyData(val items: List<FilmCategory> = emptyList())
