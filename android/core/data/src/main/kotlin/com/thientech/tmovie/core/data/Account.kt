package com.thientech.tmovie.core.data

import android.content.Context
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.FirebaseFirestore
import com.thientech.tmovie.core.model.ContentPolicy
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * Google sign-in through Firebase Auth (same Firebase project and collections as the Flutter app),
 * plus per-account settings: `entitlements/{uid}.allowAdult` turns 18+ titles on for that account.
 * Entitlements are read-only for clients; the owner sets them in the Firebase console.
 */
object Account {
    data class User(val uid: String, val name: String?, val email: String?, val photoUrl: String?)

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val _user = MutableStateFlow<User?>(null)
    private val _allowAdult = MutableStateFlow(false)

    val user: StateFlow<User?> = _user.asStateFlow()
    val allowAdult: StateFlow<Boolean> = _allowAdult.asStateFlow()

    /** False when the build has no google-services.json; the UI then hides sign-in. */
    var available = false
        private set

    fun init(context: Context) {
        available = FirebaseApp.getApps(context).isNotEmpty()
        if (!available) return
        FirebaseAuth.getInstance().addAuthStateListener { auth ->
            val u = auth.currentUser
            _user.value = u?.let { User(it.uid, it.displayName, it.email, it.photoUrl?.toString()) }
            scope.launch { onUser(u?.uid) }
        }
    }

    private suspend fun onUser(uid: String?) {
        if (uid == null) {
            setAllowAdult(false)
            LibrarySync.stop()
            return
        }
        val entitlement = runCatching {
            FirebaseFirestore.getInstance().collection("entitlements").document(uid).get().await()
        }.getOrNull()
        setAllowAdult(entitlement?.getBoolean("allowAdult") == true)
        LibrarySync.start(uid)
    }

    private fun setAllowAdult(on: Boolean) {
        ContentPolicy.allowAdult = on
        _allowAdult.value = on
    }

    /** Shows the Google account picker; [context] must be an Activity. */
    suspend fun signIn(context: Context): Result<Unit> = runCatching {
        check(available) { "Firebase is not configured in this build" }
        val clientIdRes = context.resources.getIdentifier("default_web_client_id", "string", context.packageName)
        check(clientIdRes != 0) { "default_web_client_id missing" }
        val option = GetGoogleIdOption.Builder()
            .setServerClientId(context.getString(clientIdRes))
            .setFilterByAuthorizedAccounts(false)
            .setAutoSelectEnabled(true)
            .build()
        val result = CredentialManager.create(context)
            .getCredential(context, GetCredentialRequest.Builder().addCredentialOption(option).build())
        val credential = result.credential
        check(credential is CustomCredential && credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
            "Unexpected credential"
        }
        val idToken = GoogleIdTokenCredential.createFrom(credential.data).idToken
        FirebaseAuth.getInstance().signInWithCredential(GoogleAuthProvider.getCredential(idToken, null)).await()
        Unit
    }

    fun signOut(context: Context) {
        if (!available) return
        FirebaseAuth.getInstance().signOut()
        scope.launch { runCatching { CredentialManager.create(context).clearCredentialState(ClearCredentialStateRequest()) } }
    }
}
