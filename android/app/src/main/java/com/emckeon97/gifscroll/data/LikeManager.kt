package com.emckeon97.gifscroll.data

import android.content.Context
import org.json.JSONObject

/**
 * Tracks laugh-reacts and learns which keywords the user likes,
 * so the feed can rank matching GIFs first. Persisted locally.
 */
class LikeManager(context: Context) {
    private val prefs =
        context.getSharedPreferences("gifscroll.likes", Context.MODE_PRIVATE)

    private val stopwords = setOf(
        "the", "a", "an", "and", "or", "for", "with", "you", "your",
        "this", "that", "these", "those", "from", "have", "has", "was",
        "were", "are", "is", "it", "its", "of", "to", "in", "on",
        "at", "be", "gif", "gifs"
    )

    fun isLiked(id: String): Boolean =
        prefs.getStringSet(KEY_IDS, emptySet())?.contains(id) == true

    fun toggleLike(id: String, title: String) {
        val ids = prefs.getStringSet(KEY_IDS, emptySet())?.toMutableSet() ?: mutableSetOf()
        val scores = keywordScores().toMutableMap()
        if (ids.contains(id)) {
            ids.remove(id)
            adjust(scores, title, -1)
        } else {
            ids.add(id)
            adjust(scores, title, 1)
        }
        prefs.edit()
            .putStringSet(KEY_IDS, ids)
            .putString(KEY_SCORES, JSONObject(scores as Map<*, *>).toString())
            .apply()
    }

    /** How strongly a title matches the user's liked keywords. Higher = show first. */
    fun score(title: String): Double =
        keywords(title).sumOf { keywordScores()[it] ?: 0.0 }

    private fun keywords(title: String): List<String> =
        title.lowercase()
            .split(Regex("[^a-z0-9]+"))
            .filter { it.length > 2 && it !in stopwords }

    private fun adjust(scores: MutableMap<String, Double>, title: String, by: Int) {
        keywords(title).forEach { scores[it] = (scores[it] ?: 0.0) + by }
    }

    private fun keywordScores(): Map<String, Double> {
        val raw = prefs.getString(KEY_SCORES, null) ?: return emptyMap()
        return try {
            val o = JSONObject(raw)
            o.keys().asSequence().associateWith { o.optDouble(it) }
        } catch (e: Exception) {
            emptyMap()
        }
    }

    companion object {
        private const val KEY_IDS = "liked_ids"
        private const val KEY_SCORES = "keyword_scores"
    }
}
