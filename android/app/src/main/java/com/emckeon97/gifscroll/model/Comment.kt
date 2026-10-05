package com.emckeon97.gifscroll.model

import org.json.JSONObject

/** A comment on a user post or a GIF. */
data class Comment(
    val id: String,
    val postId: String?,
    val gifId: String?,
    val displayName: String,
    val body: String,
    val createdAt: Long
) {
    companion object {
        fun fromSupabase(o: JSONObject): Comment? {
            val id = o.optString("id").ifEmpty { return null }
            val body = o.optString("body").ifEmpty { return null }
            return Comment(
                id = id,
                postId = o.optString("post_id").ifEmpty { null },
                gifId = o.optString("gif_id").ifEmpty { null },
                displayName = o.optString("display_name").ifEmpty { "anon" },
                body = body,
                createdAt = try {
                    java.time.OffsetDateTime.parse(o.optString("created_at")).toInstant().toEpochMilli()
                } catch (e: Exception) {
                    System.currentTimeMillis()
                }
            )
        }
    }
}
