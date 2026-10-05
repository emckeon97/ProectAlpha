package com.emckeon97.gifscroll.data

import com.emckeon97.gifscroll.model.FeedItem
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * The main feed: funny memes, GIFs, and videos from Reddit's meme
 * communities, via the Arctic Shift mirror. Free, no API key —
 * Reddit's own endpoints now bot-block unauthenticated requests.
 */
object RedditService {
    private val client = OkHttpClient()
    private val headClient = OkHttpClient.Builder()
        .connectTimeout(6, TimeUnit.SECONDS)
        .readTimeout(6, TimeUnit.SECONDS)
        .callTimeout(8, TimeUnit.SECONDS)
        .build()
    private val subreddits = listOf("memes", "dankmemes", "funny")

    suspend fun memeFeed(): List<FeedItem> = withContext(Dispatchers.IO) {
        val sub = subreddits.random()
        val request = Request.Builder()
            .url("https://arctic-shift.photon-reddit.com/api/posts/search?subreddit=$sub&sort=desc&limit=50")
            .header("User-Agent", "GifScroll/1.0 (by /u/gifscroll)")
            .build()
        val body = client.newCall(request).execute().use { resp ->
            if (!resp.isSuccessful) throw IOException("HTTP ${resp.code}")
            resp.body?.string() ?: throw IOException("empty body")
        }
        // Drop dead media in the background before anything is shown.
        filterDeadMedia(parse(body))
    }

    /**
     * HEAD-checks every media URL concurrently and drops the dead ones.
     * Fail-open: timeouts, network errors, and servers that don't support
     * HEAD (405/501) keep the item — only definitive 4xx/5xx drops it.
     */
    private suspend fun filterDeadMedia(items: List<FeedItem>): List<FeedItem> =
        coroutineScope {
            val limiter = Dispatchers.IO.limitedParallelism(8)
            items.map { item ->
                async(limiter) { if (urlIsAlive(item.url)) item else null }
            }.awaitAll().filterNotNull()
        }

    private fun urlIsAlive(url: String): Boolean {
        return try {
            val req = Request.Builder().url(url).head().build()
            headClient.newCall(req).execute().use { resp ->
                val code = resp.code
                if (code == 405 || code == 501) return true // HEAD unsupported — keep
                if (code !in 200..399) return false
                // Drop HTML error pages masquerading as media.
                val contentType = resp.header("Content-Type")?.lowercase()
                if (contentType != null && contentType.startsWith("text/")) return false
                true
            }
        } catch (e: Exception) {
            true // fail open on timeouts / network errors
        }
    }

    private fun parse(json: String): List<FeedItem> {
        val out = mutableListOf<FeedItem>()
        val posts = JSONObject(json).optJSONArray("data") ?: return out
        for (i in 0 until posts.length()) {
            val p = posts.getJSONObject(i)
            if (p.optBoolean("over_18") || p.optBoolean("stickied")) continue
            if (p.optBoolean("is_gallery")) continue
            val title = p.optString("title").trim()
            if (title.isEmpty() || title == "[deleted]" || title == "[removed]") continue
            val id = p.optString("id")
            if (id.isEmpty()) continue

            // Video posts: use the direct MP4 fallback, not the v.redd.it page URL.
            if (p.optBoolean("is_video")) {
                val fallback = p.optJSONObject("media")
                    ?.optJSONObject("reddit_video")
                    ?.optString("fallback_url")
                    ?.replace("&amp;", "&")
                if (!fallback.isNullOrEmpty()) {
                    out.add(FeedItem(id, title, FeedItem.Kind.VIDEO, fallback))
                    continue
                }
            }

            val url = p.optString("url_overridden_by_dest").ifEmpty { p.optString("url") }
            if (url.isEmpty()) continue
            val ext = url.substringAfterLast('.', "").substringBefore('?').lowercase()
            when (ext) {
                "gif" -> out.add(FeedItem(id, title, FeedItem.Kind.GIF, url))
                "jpg", "jpeg", "png" ->
                    out.add(FeedItem(id, title, FeedItem.Kind.IMAGE, url))
            }
        }
        return out
    }
}
