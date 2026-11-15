package com.thientech.tmovie.core.data

import android.content.Context
import java.io.File

/**
 * The frame on screen when the viewer paused or left a film, for its "Xem tiếp" card. Written by
 * the player (PlayerActivity.snapshot), read by ContinueCard; one JPEG per film in the cache dir.
 */
object ContinueFrames {
    fun file(context: Context, slug: String): File =
        File(context.cacheDir, "continue-frames").apply { mkdirs() }.resolve(slug.replace('/', '_') + ".jpg")
}
