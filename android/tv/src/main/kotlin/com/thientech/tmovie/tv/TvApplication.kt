package com.thientech.tmovie.tv

import android.app.Application
import com.thientech.tmovie.core.data.Account
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.data.Settings
import com.thientech.tmovie.core.player.Player

class TvApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Settings.init(this)
        Library.init(this)
        Account.init(this)  // no google-services.json in the TV build: stays signed out, 18+ hidden
        Player.activity = TvPlayerActivity::class.java
    }
}
