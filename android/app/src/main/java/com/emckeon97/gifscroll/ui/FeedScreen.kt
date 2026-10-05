package com.emckeon97.gifscroll.ui

import android.os.Build
import android.util.Log
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.SentimentSatisfied
import androidx.compose.material.icons.filled.SentimentVerySatisfied
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import coil3.ImageLoader
import coil3.compose.AsyncImage
import coil3.gif.AnimatedImageDecoder
import coil3.gif.GifDecoder
import com.emckeon97.gifscroll.data.AppContainer
import com.emckeon97.gifscroll.data.RedditService
import com.emckeon97.gifscroll.model.FeedItem
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** ImageLoader with animated-GIF support. */
@Composable
fun rememberGifImageLoader(): ImageLoader {
    val context = LocalContext.current
    return remember {
        ImageLoader.Builder(context)
            .components {
                if (Build.VERSION.SDK_INT >= 28) {
                    add(AnimatedImageDecoder.Factory())
                } else {
                    add(GifDecoder.Factory())
                }
            }
            .build()
    }
}

/** The meme feed: one full-screen swipeable meme/GIF/video per page. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun FeedScreen(container: AppContainer, modifier: Modifier = Modifier) {
    var items by remember { mutableStateOf<List<FeedItem>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var reloadKey by remember { mutableIntStateOf(0) }

    LaunchedEffect(reloadKey) {
        loading = true
        error = null
        val fetched = withContext(Dispatchers.IO) {
            try {
                RedditService.memeFeed()
            } catch (e: Exception) {
                Log.e("GifScroll", "Feed load failed", e)
                error = e.message ?: e.toString()
                emptyList()
            }
        }
        // Rank by the user's liked keywords.
        items = fetched.sortedByDescending { container.likeManager.score(it.title) }
        if (items.isEmpty() && error == null) {
            error = "Reddit returned no usable posts."
        }
        loading = false
    }

    Box(modifier.fillMaxSize().background(Color.Black)) {
        when {
            loading -> CircularProgressIndicator(
                Modifier.align(Alignment.Center),
                color = Color.White
            )
            error != null && items.isEmpty() -> {
                Column(
                    Modifier.align(Alignment.Center).padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("Couldn't load memes", color = Color.White)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        error ?: "",
                        color = Color.Gray,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                    Spacer(Modifier.height(16.dp))
                    Button(onClick = { reloadKey++ }) {
                        Text("Retry")
                    }
                }
            }
            else -> {
                val pagerState = rememberPagerState(pageCount = { items.size })
                VerticalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxSize()
                ) { page ->
                    FeedPage(
                        item = items[page],
                        container = container,
                        isPlaying = pagerState.currentPage == page
                    )
                }
            }
        }
    }
}

@Composable
fun FeedPage(item: FeedItem, container: AppContainer, isPlaying: Boolean) {
    val context = LocalContext.current
    var liked by remember(item.id) {
        mutableStateOf(container.likeManager.isLiked(item.id))
    }
    var showComments by remember { mutableStateOf(false) }
    var showReport by remember { mutableStateOf(false) }

    Box(Modifier.fillMaxSize().background(Color.Black)) {
        if (item.kind == FeedItem.Kind.VIDEO) {
            VideoPage(url = item.url, isPlaying = isPlaying)
        } else {
            AsyncImage(
                model = item.url,
                contentDescription = item.title,
                imageLoader = rememberGifImageLoader(),
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Fit
            )
        }

        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 100.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            CircleButton(
                icon = if (liked) Icons.Filled.SentimentVerySatisfied
                else Icons.Filled.SentimentSatisfied,
                tint = if (liked) Color.Yellow else Color.White,
                onClick = {
                    container.likeManager.toggleLike(item.id, item.title)
                    liked = container.likeManager.isLiked(item.id)
                }
            )
            CircleButton(
                icon = Icons.Filled.ChatBubbleOutline,
                onClick = { showComments = true }
            )
            CircleButton(
                icon = Icons.Filled.Flag,
                onClick = { showReport = true }
            )
            CircleButton(
                icon = Icons.Filled.Share,
                onClick = { shareUrl(context, item.url) }
            )
        }
    }

    if (showComments) {
        CommentsSheet(
            postId = null,
            gifId = item.id,
            container = container,
            onDismiss = { showComments = false }
        )
    }
    if (showReport) {
        ReportDialog(
            target = ReportTarget.Gif(item.id),
            container = container,
            onDismiss = { showReport = false }
        )
    }
}
