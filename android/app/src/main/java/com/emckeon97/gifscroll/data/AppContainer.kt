package com.emckeon97.gifscroll.data

import android.content.Context

/** Service locator: one instance of each manager, created per process. */
class AppContainer(context: Context) {
    val likeManager = LikeManager(context)
    val authManager = AuthManager(context)
    val postService = PostService(context)
}
