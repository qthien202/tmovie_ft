package com.thientech.tmovie.core.data

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import com.thientech.tmovie.core.network.PhimApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

/**
 * The app is for the owner and friends: a new device asks for access with a name and an email, the owner
 * approves it from the mail they get (the owner's Apps Script, private/apps-script/access.gs), and the
 * device, which alone holds the request's random id, opens. Once a device is in, it stays in.
 * Same contract as the iOS app.
 */
object AccessGate {
    private const val URL = "https://script.google.com/macros/s/AKfycbzM71C8tRgkWqKWYBpr97IcZCOkouZTTU55rWiU1n4g3MZHEq8dm9B9pHd6SC4kicSk-Q/exec"
    private const val TTL = 48 * 60 * 60 * 1000L  // 24 h to approve + 24 h to pick it up; the script decides

    enum class Status { Open, Pending, Expired }

    private lateinit var prefs: SharedPreferences
    private val _unlocked = MutableStateFlow(false)
    val unlocked: StateFlow<Boolean> = _unlocked.asStateFlow()

    fun init(context: Context) {
        prefs = context.getSharedPreferences("access", Context.MODE_PRIVATE)
        _unlocked.value = prefs.getBoolean("unlocked", false)
    }

    /** The email of a request still waiting for approval, else null. */
    fun pendingEmail(): String? =
        prefs.getString("email", null)?.takeIf { prefs.getString("id", null) != null && System.currentTimeMillis() - prefs.getLong("requestedAt", 0) < TTL }

    fun forgetRequest() = prefs.edit().remove("id").apply()

    suspend fun request(name: String, email: String, platform: String): Result<Unit> = runCatching {
        val id = post("action" to "request", "name" to name, "email" to email, "platform" to platform, "device" to "${Build.MANUFACTURER} ${Build.MODEL}")
            .takeIf { it.flag("ok") }?.get("id")?.jsonPrimitive?.content ?: error("request refused")
        prefs.edit().putString("email", email).putString("id", id).putLong("requestedAt", System.currentTimeMillis()).apply()
    }

    /** Asks whether the pending request was approved; on [Status.Open] the device stays open from now on. */
    suspend fun check(): Result<Status> = runCatching {
        val id = prefs.getString("id", null)?.takeIf { pendingEmail() != null } ?: return@runCatching Status.Expired
        val res = post("action" to "status", "id" to id)
        when {
            res.flag("ok") -> {
                prefs.edit().putBoolean("unlocked", true).remove("id").apply()
                _unlocked.value = true
                Status.Open
            }
            res.flag("pending") -> Status.Pending
            else -> { forgetRequest(); Status.Expired }
        }
    }

    // Apps Script answers a POST with a redirect to the result, which OkHttp follows as a GET.
    private suspend fun post(vararg fields: Pair<String, String>): JsonObject = withContext(Dispatchers.IO) {
        val body = JsonObject(fields.associate { (k, v) -> k to JsonPrimitive(v) }).toString()
        val request = Request.Builder().url(URL).post(body.toRequestBody("application/json".toMediaType())).build()
        PhimApi.defaultClient.newCall(request).execute().use { res ->
            check(res.isSuccessful) { "HTTP ${res.code}" }
            PhimApi.json.parseToJsonElement(res.body!!.string()).jsonObject
        }
    }

    private fun JsonObject.flag(key: String) = this[key]?.jsonPrimitive?.booleanOrNull == true
}
