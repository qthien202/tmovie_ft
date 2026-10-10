package com.thientech.tmovie.core.player

import android.content.Context
import android.content.Intent
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.network.PhimApi

/** Entry points for playback, used by every screen with a Play button. */
object Player {
    /** Plays `servers[server].serverData[index]`, resuming at the saved second. */
    fun play(context: Context, detail: FilmDetail, server: Int, index: Int) {
        context.startActivity(
            Intent(context, PlayerActivity::class.java)
                .putExtra(PlayerActivity.EXTRA_DETAIL, PhimApi.json.encodeToString(FilmDetail.serializer(), detail))
                .putExtra(PlayerActivity.EXTRA_SERVER, server)
                .putExtra(PlayerActivity.EXTRA_INDEX, index)
                .addFlags(if (context is android.app.Activity) 0 else Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    /** "Phát" / "Tiếp tục": the last watched episode, else the first playable one. False when nothing plays. */
    fun start(context: Context, detail: FilmDetail): Boolean {
        val servers = detail.episodes.orEmpty().map { it.serverData.orEmpty() }
        Library.record(detail.slug)?.let { r ->
            if (servers.getOrNull(r.serverIndex)?.getOrNull(r.episodeIndex)?.streamUrl != null) {
                play(context, detail, r.serverIndex, r.episodeIndex)
                return true
            }
        }
        servers.forEachIndexed { s, list ->
            val i = list.indexOfFirst { it.streamUrl != null }
            if (i >= 0) {
                play(context, detail, s, i)
                return true
            }
        }
        return false
    }
}
