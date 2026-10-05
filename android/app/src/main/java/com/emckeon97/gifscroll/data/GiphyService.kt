package com.emckeon97.gifscroll.data

import com.emckeon97.gifscroll.Secrets
import com.emckeon97.gifscroll.model.Gif
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.net.URLEncoder

/** Giphy API client. The key lives in Secrets.kt (gitignored). */
object GiphyService {
    private val client = OkHttpClient()
    private const val BASE = "https://api.giphy.com/v1/gifs"

    private val memeQueries = listOf(
        "meme",
        "dank memes",
        "funny memes",
        "shitpost",
        "relatable memes",
        "surreal meme",
        "cursed memes"
    )

    /** The main feed: iFunny-style meme GIFs, query rotated for variety. */
    suspend fun comedyFeed(): List<Gif> = search(memeQueries.random())

    suspend fun search(query: String): List<Gif> = withContext(Dispatchers.IO) {
        val url = "$BASE/search?api_key=${Secrets.GIPHY_API_KEY}" +
            "&q=${URLEncoder.encode(query, "UTF-8")}&limit=50&rating=pg-13"
        val request = Request.Builder().url(url).build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) return@withContext emptyList()
            parseGifs(response.body?.string() ?: return@withContext emptyList())
        }
    }

    private fun parseGifs(json: String): List<Gif> {
        val out = mutableListOf<Gif>()
        try {
            val data = JSONObject(json).optJSONArray("data") ?: return out
            for (i in 0 until data.length()) {
                val o = data.optJSONObject(i) ?: continue
                val id = o.optString("id")
                if (id.isEmpty()) continue
                val url = o.optJSONObject("images")
                    ?.optJSONObject("original")
                    ?.optString("url")
                    ?.ifEmpty { null } ?: continue
                out.add(Gif(id, o.optString("title"), url))
            }
        } catch (e: Exception) {
            // Return what we have.
        }
        return out
    }
}
