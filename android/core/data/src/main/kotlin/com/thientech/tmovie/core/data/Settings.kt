package com.thientech.tmovie.core.data

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Small user preferences, observable. */
object Settings {
    private lateinit var prefs: SharedPreferences
    private val _heroAutoplay = MutableStateFlow(true)
    private val _heroMuted = MutableStateFlow(true)
    private val _onboarded = MutableStateFlow(false)
    private val _profileName = MutableStateFlow("Bạn")

    val heroAutoplay: StateFlow<Boolean> = _heroAutoplay.asStateFlow()
    val heroMuted: StateFlow<Boolean> = _heroMuted.asStateFlow()
    val onboarded: StateFlow<Boolean> = _onboarded.asStateFlow()
    val profileName: StateFlow<String> = _profileName.asStateFlow()

    fun init(context: Context) {
        prefs = context.getSharedPreferences("settings", Context.MODE_PRIVATE)
        _heroAutoplay.value = prefs.getBoolean("heroAutoplay", true)
        _heroMuted.value = prefs.getBoolean("heroMuted", true)
        _onboarded.value = prefs.getBoolean("onboarded", false)
        _profileName.value = prefs.getString("profileName", "Bạn") ?: "Bạn"
    }

    fun setHeroAutoplay(on: Boolean) { _heroAutoplay.value = on; prefs.edit().putBoolean("heroAutoplay", on).apply() }
    fun setHeroMuted(on: Boolean) { _heroMuted.value = on; prefs.edit().putBoolean("heroMuted", on).apply() }
    fun setOnboarded() { _onboarded.value = true; prefs.edit().putBoolean("onboarded", true).apply() }
    fun setProfileName(name: String) { _profileName.value = name; prefs.edit().putString("profileName", name).apply() }
}
