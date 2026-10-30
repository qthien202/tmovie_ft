package com.thientech.tmovie.tv

import android.app.ActivityManager
import android.app.Application
import coil3.ImageLoader
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.memory.MemoryCache
import coil3.request.allowRgb565
import com.thientech.tmovie.core.data.Account
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.data.Settings
import com.thientech.tmovie.core.player.Player

class TvApplication : Application(), SingletonImageLoader.Factory {
    override fun onCreate() {
        super.onCreate()
        Settings.init(this)
        Library.init(this)
        Account.init(this)  // no google-services.json in the TV build: stays signed out, 18+ hidden
        Player.activity = TvPlayerActivity::class.java
    }

    /**
     * TV boxes often have 1–2 GB of RAM shared with the video decoder: keep the image cache to a
     * small slice of the heap, and on low-RAM boxes decode posters at half the bytes (RGB 565).
     */
    override fun newImageLoader(context: PlatformContext): ImageLoader {
        val lowRam = getSystemService(ActivityManager::class.java).isLowRamDevice
        return ImageLoader.Builder(context)
            .memoryCache { MemoryCache.Builder().maxSizePercent(context, if (lowRam) 0.1 else 0.15).build() }
            .allowRgb565(lowRam)
            .build()
    }
}
