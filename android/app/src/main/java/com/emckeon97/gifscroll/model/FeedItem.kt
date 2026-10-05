package com.emckeon97.gifscroll.model

/** One item in the meme feed: a captioned image, GIF, or video from Reddit. */
data class FeedItem(
    val id: String,
    val title: String,
    val kind: Kind,
    val url: String
) {
    enum class Kind { IMAGE, GIF, VIDEO }
}
