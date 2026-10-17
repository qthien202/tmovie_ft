package com.thientech.tmovie

import android.app.Application
import android.os.Build
import com.thientech.tmovie.core.data.Account
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.data.Settings

class TMovieApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // The voice-over's synthesis runs in its own process (":voice"), which needs none of this.
        if (Build.VERSION.SDK_INT >= 28 && getProcessName() != packageName) return
        Settings.init(this)
        Library.init(this)
        Account.init(this)
    }
}
