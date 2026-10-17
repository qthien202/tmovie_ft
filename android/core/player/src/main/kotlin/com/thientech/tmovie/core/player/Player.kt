package com.thientech.tmovie.core.player

import android.content.Context
import android.content.Intent
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.network.PhimApi

/** Entry points for playback, used by every screen with a Play button. */
object Player {
    /** Plays `servers[server].serverData[index]`, resuming at the saved second. */
    /** [fromDetail]: the film's detail page is underneath, so the player needn't offer it. */
    fun play(context: Context, detail: FilmDetail, server: Int, index: Int, fromDetail: Boolean = false) {
        context.startActivity(
            Intent(context, PlayerActivity::class.java)
                .putExtra(PlayerActivity.EXTRA_DETAIL, PhimApi.json.encodeToString(FilmDetail.serializer(), detail))
                .putExtra(PlayerActivity.EXTRA_SERVER, server)
                .putExtra(PlayerActivity.EXTRA_INDEX, index)
                .putExtra(PlayerActivity.EXTRA_FROM_DETAIL, fromDetail)
                .addFlags(if (context is android.app.Activity) 0 else Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    /** A live TV channel ([LiveActivity]). */
    fun live(context: Context, name: String, url: String, userAgent: String? = null, referrer: String? = null) {
        context.startActivity(
            Intent(context, LiveActivity::class.java)
                .putExtra(LiveActivity.EXTRA_NAME, name)
                .putExtra(LiveActivity.EXTRA_URL, url)
                .putExtra(LiveActivity.EXTRA_USER_AGENT, userAgent)
                .putExtra(LiveActivity.EXTRA_REFERRER, referrer)
                .addFlags(if (context is android.app.Activity) 0 else Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    /** "Phát" / "Tiếp tục": the last watched episode, else the first playable one. False when nothing plays. */
    fun start(context: Context, detail: FilmDetail, fromDetail: Boolean = false): Boolean {
        val servers = detail.episodes.orEmpty().map { it.serverData.orEmpty() }
        Library.record(detail.slug)?.let { r ->
            if (servers.getOrNull(r.serverIndex)?.getOrNull(r.episodeIndex)?.streamUrl != null) {
                play(context, detail, r.serverIndex, r.episodeIndex, fromDetail)
                return true
            }
        }
        servers.forEachIndexed { s, list ->
            val i = list.indexOfFirst { it.streamUrl != null }
            if (i >= 0) {
                play(context, detail, s, i, fromDetail)
                return true
            }
        }
        return false
    }
}
