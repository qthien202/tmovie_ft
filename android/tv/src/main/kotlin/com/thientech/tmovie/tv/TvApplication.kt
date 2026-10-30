package com.thientech.tmovie.tv

import coil3.disk.DiskCache
import coil3.network.okhttp.OkHttpNetworkFetcherFactory
import okhttp3.Dispatcher
import okhttp3.OkHttpClient
import okio.Path.Companion.toOkioPath
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
     *
     * phimimg.com holds every image request ~8 s however small or parallel, so: many requests in
     * flight (OkHttp's default is 5 per host, i.e. a screen of 20 cards took 30+ s), and a roomy
     * disk cache so each image waits only once.
     */
    override fun newImageLoader(context: PlatformContext): ImageLoader {
        val lowRam = getSystemService(ActivityManager::class.java).isLowRamDevice
        return ImageLoader.Builder(context)
            .memoryCache { MemoryCache.Builder().maxSizePercent(context, if (lowRam) 0.1 else 0.15).build() }
            .allowRgb565(lowRam)
            .diskCache { DiskCache.Builder().directory(context.cacheDir.resolve("image_cache").toOkioPath()).maxSizeBytes(200L * 1024 * 1024).build() }
            .components {
                add(OkHttpNetworkFetcherFactory(callFactory = {
                    OkHttpClient.Builder().dispatcher(Dispatcher().apply { maxRequests = 64; maxRequestsPerHost = 32 }).build()
                }))
            }
            .build()
    }
}
