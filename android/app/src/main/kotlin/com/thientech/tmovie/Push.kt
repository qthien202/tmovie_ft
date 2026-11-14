package com.thientech.tmovie

import android.Manifest
import android.app.Application
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.thientech.tmovie.core.data.AccessGate
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.network.PhimApi
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import okhttp3.Request

/**
 * Pushes from the owner's Apps Script (private/apps-script/notify.gs), sent to FCM topics:
 * `new` for films new to the catalogue, `ep_{slug}` when a series gets an episode. The app follows `new`
 * and the series in its watch history (newest 50), and draws the notification itself from the data
 * message, Netflix style: the film's still as a big picture, its name, "Tập 12 đã có".
 */
object Push {
    private const val EPISODES = "episodes"
    private const val NEW_FILMS = "new_films"
    private const val MAX_FOLLOWED = 50
    private val topicName = Regex("[a-zA-Z0-9-_.~%]{1,900}")
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    fun init(app: Application) {
        NotificationManagerCompat.from(app).createNotificationChannelsCompat(listOf(
            NotificationChannelCompat.Builder(EPISODES, NotificationManagerCompat.IMPORTANCE_HIGH)
                .setName("Tập mới").setDescription("Phim bạn đang xem có tập mới").build(),
            NotificationChannelCompat.Builder(NEW_FILMS, NotificationManagerCompat.IMPORTANCE_DEFAULT)
                .setName("Phim mới").setDescription("Phim mới lên TMovie").build(),
        ))
        if (FirebaseApp.getApps(app).isEmpty()) return  // no google-services.json in this build
        val prefs = app.getSharedPreferences("push", Context.MODE_PRIVATE)
        scope.launch {
            combine(AccessGate.unlocked, Library.history) { open, history ->
                if (!open) emptySet()
                else history.asSequence()
                    .filter { it.film.type != "single" }  // a film has no next episode
                    .sortedByDescending { it.updatedAt }
                    .map { "ep_${it.film.slug}" }
                    .filter(topicName::matches)
                    .take(MAX_FOLLOWED)
                    .toSet() + "new"
            }.distinctUntilChanged().collect { want ->
                // Subscribe/unsubscribe only the difference; a failed call is retried on the next change.
                val had = prefs.getStringSet("topics", emptySet()).orEmpty()
                val now = had.toMutableSet()
                runCatching {
                    (want - had).forEach { FirebaseMessaging.getInstance().subscribeToTopic(it).await(); now += it }
                    (had - want).forEach { FirebaseMessaging.getInstance().unsubscribeFromTopic(it).await(); now -= it }
                }
                prefs.edit().putStringSet("topics", now).apply()
            }
        }
    }

    /** A new FCM token drops the topics, so the next start subscribes them again. */
    fun forgetTopics(context: Context) =
        context.getSharedPreferences("push", Context.MODE_PRIVATE).edit().remove("topics").apply()

    fun show(context: Context, data: Map<String, String>) {
        if (!AccessGate.unlocked.value) return
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        val slug = data["slug"] ?: return
        val episode = data["type"] == "episode"
        val title = data["title"].orEmpty()
        val body = data["body"].orEmpty()
        val image = data["image"]?.let(::download)
        val open = PendingIntent.getActivity(
            context, slug.hashCode(),
            Intent(Intent.ACTION_VIEW, Uri.parse("tmovie://phim/$slug"), context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val style = if (image != null) NotificationCompat.BigPictureStyle().bigPicture(image).bigLargeIcon(null as Bitmap?).setSummaryText(body)
        else NotificationCompat.BigTextStyle().bigText(body)
        val notification = NotificationCompat.Builder(context, if (episode) EPISODES else NEW_FILMS)
            .setSmallIcon(R.drawable.ic_stat_tmovie)
            .setColor(0xFF0F9190.toInt())
            .setSubText(if (episode) "Tập mới" else "Phim mới")
            .setContentTitle(title)
            .setContentText(body)
            .setLargeIcon(image)
            .setStyle(style)
            .setContentIntent(open)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_RECOMMENDATION)
            .build()
        // One notification per film: a later episode replaces the earlier one.
        NotificationManagerCompat.from(context).notify(slug.hashCode(), notification)
    }

    /** The film's still, scaled to about 1000 px wide; null if it can't be had within the call timeout. */
    private fun download(url: String): Bitmap? = runCatching {
        val bytes = PhimApi.defaultClient.newCall(Request.Builder().url(url).build()).execute().use { it.body!!.bytes() }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= 1000) sample *= 2
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })
    }.getOrNull()
}

class PushService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) = Push.show(this, message.data)
    override fun onNewToken(token: String) = Push.forgetTopics(this)
}
