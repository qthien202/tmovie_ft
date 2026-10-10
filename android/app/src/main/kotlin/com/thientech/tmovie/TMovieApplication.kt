package com.thientech.tmovie

import android.app.Application
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.data.Settings

class TMovieApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Settings.init(this)
        Library.init(this)
    }
}
