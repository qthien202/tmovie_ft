package com.thientech.tmovie

import android.app.Application
import com.thientech.tmovie.core.data.Account
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.data.Settings

class TMovieApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Thuyết minh AI is gone from Android (v1.9.0): free the voice models it downloaded.
        Thread { noBackupFilesDir.listFiles { f -> f.name.startsWith("VieNeu") }?.forEach { it.deleteRecursively() } }.start()
        Settings.init(this)
        Library.init(this)
        Account.init(this)
    }
}
