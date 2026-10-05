package com.emckeon97.gifscroll.data

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Owns the Supabase auth session: sign up, sign in, sign out.
 * The session token is persisted so sign-in survives app restarts.
 */
class AuthManager(context: Context) {
    private val prefs =
        context.getSharedPreferences("gifscroll.auth", Context.MODE_PRIVATE)

    private val _isSignedIn = MutableStateFlow(false)
    val isSignedIn: StateFlow<Boolean> = _isSignedIn

    private val _email = MutableStateFlow<String?>(null)
    val email: StateFlow<String?> = _email

    private val _displayName = MutableStateFlow<String?>(null)
    val displayName: StateFlow<String?> = _displayName

    val currentDisplayName: String get() = _displayName.value ?: "anon"

    init {
        prefs.getString(KEY_TOKEN, null)?.let { token ->
            SupabaseManager.authToken = token
            _email.value = prefs.getString(KEY_EMAIL, null)
            _displayName.value = prefs.getString(KEY_NAME, null)
            _isSignedIn.value = true
        }
    }

    /** Returns true when signed in immediately, false when email confirmation is pending. */
    suspend fun signUp(email: String, password: String, displayName: String): Boolean {
        val r = SupabaseManager.signUp(email, password, displayName)
        val token = r.accessToken ?: return false
        persist(token, r.email ?: email, displayName)
        return true
    }

    suspend fun signIn(email: String, password: String) {
        val r = SupabaseManager.signIn(email, password)
        val token = r.accessToken ?: throw RuntimeException("sign in failed")
        val name = (r.email ?: email).substringBefore("@").ifEmpty { "anon" }
        persist(token, r.email ?: email, name)
    }

    fun signOut() {
        SupabaseManager.authToken = null
        prefs.edit().clear().apply()
        _isSignedIn.value = false
        _email.value = null
        _displayName.value = null
    }

    private fun persist(token: String, email: String, displayName: String) {
        SupabaseManager.authToken = token
        prefs.edit()
            .putString(KEY_TOKEN, token)
            .putString(KEY_EMAIL, email)
            .putString(KEY_NAME, displayName)
            .apply()
        _email.value = email
        _displayName.value = displayName
        _isSignedIn.value = true
    }

    companion object {
        private const val KEY_TOKEN = "token"
        private const val KEY_EMAIL = "email"
        private const val KEY_NAME = "name"
    }
}
