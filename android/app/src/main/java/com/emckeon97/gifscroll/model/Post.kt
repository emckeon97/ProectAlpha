package com.emckeon97.gifscroll.model

import org.json.JSONObject

/** A community meme post. Either imageFileName (local) or imageUrl (remote) is set. */
data class Post(
    val id: String,
    val imageFileName: String?,
    val imageUrl: String?,
    val caption: String,
    val createdAt: Long,
    val likeCount: Int
) {
    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("imageFileName", imageFileName)
        .put("image_url", imageUrl)
        .put("caption", caption)
        .put("created_at", createdAt)
        .put("like_count", likeCount)

    companion object {
        fun fromSupabase(o: JSONObject): Post? {
            val id = o.optString("id").ifEmpty { return null }
            val imageUrl = o.optString("image_url").ifEmpty { return null }
            return Post(
                id = id,
                imageFileName = null,
                imageUrl = imageUrl,
                caption = o.optString("caption"),
                createdAt = parseDate(o.optString("created_at")),
                likeCount = o.optInt("like_count")
            )
        }

        fun fromJson(o: JSONObject): Post = Post(
            id = o.getString("id"),
            imageFileName = o.optString("imageFileName").ifEmpty { null },
            imageUrl = o.optString("image_url").ifEmpty { null },
            caption = o.optString("caption"),
            createdAt = o.optLong("created_at"),
            likeCount = o.optInt("like_count")
        )

        private fun parseDate(raw: String): Long =
            try {
                java.time.OffsetDateTime.parse(raw).toInstant().toEpochMilli()
            } catch (e: Exception) {
                System.currentTimeMillis()
            }
    }
}
