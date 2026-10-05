package com.emckeon97.gifscroll.data

import com.emckeon97.gifscroll.model.Comment
import com.emckeon97.gifscroll.model.Post
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Thin REST client for Supabase — no SDK dependency.
 * Uses the project's publishable key, which is designed to ship in clients.
 */
object SupabaseManager {
    private const val PROJECT_URL = "https://btfbjmdtnjntqkybpqrk.supabase.co"
    private const val API_KEY = "sb_publishable_NM4BBwTL1kRxlAjnNkGW9g_U0q-VDCF"

    private val client = OkHttpClient()
    private val jsonMedia = "application/json".toMediaType()

    /** Set after sign-in; used as the Bearer token instead of the anon key. */
    var authToken: String? = null
    private val bearer: String get() = authToken ?: API_KEY

    private fun base(url: String): Request.Builder =
        Request.Builder().url(url)
            .header("apikey", API_KEY)
            .header("Authorization", "Bearer $bearer")

    private fun jsonBody(vararg pairs: Pair<String, Any?>): okhttp3.RequestBody =
        JSONObject().apply {
            pairs.forEach { (k, v) -> if (v != null) put(k, v) }
        }.toString().toRequestBody(jsonMedia)

    // MARK: - Auth

    data class AuthResult(
        val accessToken: String?,
        val userId: String?,
        val email: String?
    )

    suspend fun signUp(email: String, password: String, displayName: String): AuthResult =
        withContext(Dispatchers.IO) {
            val body = JSONObject()
                .put("email", email)
                .put("password", password)
                .put("data", JSONObject().put("display_name", displayName))
                .toString().toRequestBody(jsonMedia)
            val req = Request.Builder().url("$PROJECT_URL/auth/v1/signup")
                .header("apikey", API_KEY)
                .post(body)
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) throw RuntimeException("sign up failed: ${resp.code}")
                parseAuth(resp.body?.string() ?: "{}")
            }
        }

    suspend fun signIn(email: String, password: String): AuthResult =
        withContext(Dispatchers.IO) {
            val body = JSONObject()
                .put("email", email)
                .put("password", password)
                .toString().toRequestBody(jsonMedia)
            val req = Request.Builder()
                .url("$PROJECT_URL/auth/v1/token?grant_type=password")
                .header("apikey", API_KEY)
                .post(body)
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) throw RuntimeException("sign in failed: ${resp.code}")
                parseAuth(resp.body?.string() ?: "{}")
            }
        }

    private fun parseAuth(json: String): AuthResult {
        val o = JSONObject(json)
        val user = o.optJSONObject("user")
        return AuthResult(
            accessToken = o.optString("access_token").ifEmpty { null },
            userId = user?.optString("id")?.ifEmpty { null },
            email = user?.optString("email")?.ifEmpty { null }
        )
    }

    // MARK: - Posts

    suspend fun fetchPosts(): List<Post> = withContext(Dispatchers.IO) {
        val url = "$PROJECT_URL/rest/v1/posts?select=*&order=created_at.desc&limit=100"
        client.newCall(base(url).build()).execute().use { resp ->
            if (!resp.isSuccessful) throw RuntimeException("fetch posts failed: ${resp.code}")
            val arr = JSONArray(resp.body?.string() ?: "[]")
            (0 until arr.length()).mapNotNull { Post.fromSupabase(arr.getJSONObject(it)) }
        }
    }

    suspend fun insertPost(imageUrl: String, caption: String): Post =
        withContext(Dispatchers.IO) {
            val req = base("$PROJECT_URL/rest/v1/posts")
                .header("Content-Type", "application/json")
                .header("Prefer", "return=representation")
                .post(jsonBody("image_url" to imageUrl, "caption" to caption))
                .build()
            client.newCall(req).execute().use { resp ->
                if (resp.code != 201) throw RuntimeException("insert post failed: ${resp.code}")
                val arr = JSONArray(resp.body?.string() ?: "[]")
                Post.fromSupabase(arr.getJSONObject(0))
                    ?: throw RuntimeException("bad post payload")
            }
        }

    /** Uploads JPEG bytes to the public `post-images` bucket. Returns the public URL. */
    suspend fun uploadImage(bytes: ByteArray): String = withContext(Dispatchers.IO) {
        val name = "${UUID.randomUUID()}.jpg"
        val req = base("$PROJECT_URL/storage/v1/object/post-images/$name")
            .header("Content-Type", "image/jpeg")
            .post(bytes.toRequestBody("image/jpeg".toMediaType()))
            .build()
        client.newCall(req).execute().use { resp ->
            if (!resp.isSuccessful) throw RuntimeException("upload failed: ${resp.code}")
            "$PROJECT_URL/storage/v1/object/public/post-images/$name"
        }
    }

    // MARK: - Comments

    suspend fun fetchComments(postId: String? = null, gifId: String? = null): List<Comment> =
        withContext(Dispatchers.IO) {
            val filter = when {
                postId != null -> "&post_id=eq.$postId"
                gifId != null -> "&gif_id=eq.$gifId"
                else -> ""
            }
            val url = "$PROJECT_URL/rest/v1/comments?select=*$filter&order=created_at.asc"
            client.newCall(base(url).build()).execute().use { resp ->
                if (!resp.isSuccessful) throw RuntimeException("fetch comments failed: ${resp.code}")
                val arr = JSONArray(resp.body?.string() ?: "[]")
                (0 until arr.length()).mapNotNull { Comment.fromSupabase(arr.getJSONObject(it)) }
            }
        }

    suspend fun insertComment(
        postId: String? = null,
        gifId: String? = null,
        body: String,
        displayName: String
    ): Comment = withContext(Dispatchers.IO) {
        val req = base("$PROJECT_URL/rest/v1/comments")
            .header("Content-Type", "application/json")
            .header("Prefer", "return=representation")
            .post(
                jsonBody(
                    "post_id" to postId,
                    "gif_id" to gifId,
                    "body" to body,
                    "display_name" to displayName
                )
            )
            .build()
        client.newCall(req).execute().use { resp ->
            if (resp.code != 201) throw RuntimeException("insert comment failed: ${resp.code}")
            val arr = JSONArray(resp.body?.string() ?: "[]")
            Comment.fromSupabase(arr.getJSONObject(0))
                ?: throw RuntimeException("bad comment payload")
        }
    }

    // MARK: - Reports

    suspend fun insertReport(
        postId: String? = null,
        gifId: String? = null,
        commentId: String? = null,
        reason: String,
        details: String,
        reporterName: String
    ) = withContext(Dispatchers.IO) {
        val req = base("$PROJECT_URL/rest/v1/reports")
            .header("Content-Type", "application/json")
            .post(
                jsonBody(
                    "post_id" to postId,
                    "gif_id" to gifId,
                    "comment_id" to commentId,
                    "reason" to reason,
                    "details" to details,
                    "reporter_name" to reporterName
                )
            )
            .build()
        client.newCall(req).execute().use { resp ->
            if (resp.code != 201) throw RuntimeException("insert report failed: ${resp.code}")
        }
    }
}
