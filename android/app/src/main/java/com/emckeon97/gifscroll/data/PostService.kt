package com.emckeon97.gifscroll.data

import android.content.Context
import com.emckeon97.gifscroll.model.Post
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.io.File
import java.util.UUID

/**
 * Post store backed by Supabase, with a local fallback when the backend
 * isn't reachable (or the tables haven't been created yet).
 */
class PostService(context: Context) {
    private val appContext = context.applicationContext
    private val prefs =
        appContext.getSharedPreferences("gifscroll.posts", Context.MODE_PRIVATE)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val _posts = MutableStateFlow<List<Post>>(emptyList())
    val posts: StateFlow<List<Post>> = _posts

    private var remoteAvailable = true

    init {
        loadCached()
    }

    fun refresh() {
        scope.launch {
            try {
                _posts.value = SupabaseManager.fetchPosts()
                remoteAvailable = true
                saveCached()
            } catch (e: Exception) {
                remoteAvailable = false
            }
        }
    }

    suspend fun createPost(imageBytes: ByteArray, caption: String) {
        val trimmed = caption.trim()
        if (remoteAvailable) {
            try {
                val url = SupabaseManager.uploadImage(imageBytes)
                val post = SupabaseManager.insertPost(url, trimmed)
                _posts.value = listOf(post) + _posts.value
                saveCached()
                return
            } catch (e: Exception) {
                remoteAvailable = false
            }
        }
        // Local fallback: store on-device so the post still works offline.
        val saved: Post = withContext(Dispatchers.IO) {
            val id = UUID.randomUUID().toString()
            File(appContext.filesDir, "$id.jpg").writeBytes(imageBytes)
            Post(id, "$id.jpg", null, trimmed, System.currentTimeMillis(), 0)
        }
        _posts.value = listOf(saved) + _posts.value
        saveCached()
    }

    /** Local image file for on-device posts, if it exists. */
    fun fileFor(post: Post): File? =
        post.imageFileName
            ?.let { File(appContext.filesDir, it) }
            ?.takeIf { it.exists() }

    private fun loadCached() {
        try {
            val raw = prefs.getString(KEY_POSTS, null) ?: return
            val arr = JSONArray(raw)
            _posts.value = (0 until arr.length())
                .map { Post.fromJson(arr.getJSONObject(it)) }
                .sortedByDescending { it.createdAt }
        } catch (e: Exception) {
            // Start empty.
        }
    }

    private fun saveCached() {
        try {
            val arr = JSONArray()
            _posts.value.forEach { arr.put(it.toJson()) }
            prefs.edit().putString(KEY_POSTS, arr.toString()).apply()
        } catch (e: Exception) {
            // Best effort.
        }
    }

    companion object {
        private const val KEY_POSTS = "posts"
    }
}
