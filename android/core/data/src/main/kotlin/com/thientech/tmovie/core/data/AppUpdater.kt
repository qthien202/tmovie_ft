package com.thientech.tmovie.core.data

import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import com.thientech.tmovie.core.network.PhimApi
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.Serializable
import okhttp3.Request

data class AppUpdate(val version: String, val notes: String, val apkUrl: String)

/**
 * OTA updates from GitHub Releases: the newest published release that carries an APK whose name
 * contains the app keyword ("mobile" / "tv"), offered when its tag is a newer semver than the
 * installed version. A release ships only the apps that changed, so a TV-only release doesn't
 * nag phones, and doesn't hide the phone's own latest update either.
 */
object AppUpdater {
    private const val RELEASES = "https://api.github.com/repos/qthien202/tmovie_ft/releases?per_page=15"

    @Serializable private class Release(
        @SerialName("tag_name") val tag: String = "",
        val body: String? = null,
        val draft: Boolean = false,
        val prerelease: Boolean = false,
        val assets: List<Asset> = emptyList(),
    )
    @Serializable private class Asset(val name: String = "", @SerialName("browser_download_url") val url: String = "")

    suspend fun check(currentVersion: String, keyword: String = "mobile"): AppUpdate? = runCatching {
        withContext(Dispatchers.IO) {
            val request = Request.Builder().url(RELEASES).header("Accept", "application/vnd.github+json").build()
            val body = PhimApi.defaultClient.newCall(request).execute().use { it.body?.string() } ?: return@withContext null
            fun Release.apk() = assets.firstOrNull { it.name.endsWith(".apk") && it.name.contains(keyword, true) }
            // Newest first, as GitHub lists them.
            val release = PhimApi.json.decodeFromString(ListSerializer(Release.serializer()), body)
                .firstOrNull { !it.draft && !it.prerelease && it.apk() != null } ?: return@withContext null
            val apk = release.apk()!!
            val version = release.tag.removePrefix("v")
            if (isNewer(currentVersion, version)) AppUpdate(version, release.body.orEmpty(), apk.url) else null
        }
    }.getOrNull()

    /** Streams the APK into the cache dir, reporting bytes done and total (total ≤ 0 when unknown). */
    suspend fun download(context: Context, url: String, onProgress: (done: Long, total: Long) -> Unit): File = withContext(Dispatchers.IO) {
        val out = File(context.cacheDir, "updates/tmovie_update.apk").apply { parentFile?.mkdirs(); delete() }
        PhimApi.defaultClient.newCall(Request.Builder().url(url).build()).execute().use { res ->
            val body = res.body ?: error("empty body")
            val total = body.contentLength()
            body.byteStream().use { input ->
                out.outputStream().use { output ->
                    val buf = ByteArray(64 * 1024)
                    var done = 0L
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        output.write(buf, 0, n)
                        done += n
                        onProgress(done, total)
                    }
                }
            }
        }
        out
    }

    /** Hands the APK to the system installer (needs REQUEST_INSTALL_PACKAGES + the FileProvider). */
    fun install(context: Context, apk: File) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", apk)
        context.startActivity(
            Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    fun isNewer(current: String, remote: String): Boolean {
        val c = current.split('.').map { it.toIntOrNull() ?: 0 }
        val r = remote.split('.').map { it.toIntOrNull() ?: 0 }
        for (i in 0 until 3) {
            val a = c.getOrElse(i) { 0 }
            val b = r.getOrElse(i) { 0 }
            if (b != a) return b > a
        }
        return false
    }
}
