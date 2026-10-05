package com.emckeon97.gifscroll.ui

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.SentimentSatisfied
import androidx.compose.material.icons.filled.SentimentVerySatisfied
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.emckeon97.gifscroll.data.AppContainer
import com.emckeon97.gifscroll.model.Post
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** The community feed: user-uploaded memes, one full-screen page each. */
@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun UploadFeedScreen(container: AppContainer, modifier: Modifier = Modifier) {
    val posts by container.postService.posts.collectAsState()
    var showUpload by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { container.postService.refresh() }

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { Text("GifScroll") },
                actions = {
                    IconButton(onClick = { showUpload = true }) {
                        Icon(Icons.Filled.Add, contentDescription = "Upload")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Black,
                    titleContentColor = Color.White,
                    actionIconContentColor = Color.White
                )
            )
        },
        containerColor = Color.Black
    ) { inner ->
        Box(
            Modifier
                .padding(inner)
                .fillMaxSize()
                .background(Color.Black)
        ) {
            if (posts.isEmpty()) {
                Column(
                    Modifier.align(Alignment.Center).padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text("No posts yet", color = Color.White)
                    Text(
                        "Be the first to post something funny.",
                        color = Color.Gray,
                        textAlign = TextAlign.Center
                    )
                    Spacer(Modifier.height(8.dp))
                    Button(onClick = { showUpload = true }) {
                        Text("Upload a meme")
                    }
                }
            } else {
                val pagerState = rememberPagerState(pageCount = { posts.size })
                VerticalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxSize()
                ) { page ->
                    PostPage(post = posts[page], container = container)
                }
            }
        }
    }

    if (showUpload) {
        UploadSheet(container = container, onDismiss = { showUpload = false })
    }
}

@Composable
fun PostPage(post: Post, container: AppContainer) {
    var liked by remember(post.id) {
        mutableStateOf(container.likeManager.isLiked(post.id))
    }
    var showComments by remember { mutableStateOf(false) }
    var showReport by remember { mutableStateOf(false) }

    // Remote URL or on-device file.
    val model: Any? = post.imageUrl
        ?: container.postService.fileFor(post)

    Box(Modifier.fillMaxSize().background(Color.Black)) {
        if (model != null) {
            AsyncImage(
                model = model,
                contentDescription = post.caption,
                imageLoader = rememberGifImageLoader(),
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Fit
            )
        } else {
            CircularProgressIndicator(
                Modifier.align(Alignment.Center),
                color = Color.White
            )
        }

        Column(Modifier.align(Alignment.BottomCenter)) {
            if (post.caption.isNotEmpty()) {
                Text(
                    post.caption,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                )
                Spacer(Modifier.height(8.dp))
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 100.dp),
                horizontalArrangement = Arrangement.spacedBy(
                    16.dp,
                    Alignment.CenterHorizontally
                )
            ) {
                CircleButton(
                    icon = if (liked) Icons.Filled.SentimentVerySatisfied
                    else Icons.Filled.SentimentSatisfied,
                    tint = if (liked) Color.Yellow else Color.White,
                    onClick = {
                        container.likeManager.toggleLike(post.id, post.caption)
                        liked = container.likeManager.isLiked(post.id)
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
            }
        }
    }

    if (showComments) {
        CommentsSheet(
            postId = post.id,
            gifId = null,
            container = container,
            onDismiss = { showComments = false }
        )
    }
    if (showReport) {
        ReportDialog(
            target = ReportTarget.Post(post.id),
            container = container,
            onDismiss = { showReport = false }
        )
    }
}

/** New-post sheet: pick a photo, add a caption, post it. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UploadSheet(container: AppContainer, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var imageUri by remember { mutableStateOf<Uri?>(null) }
    var caption by remember { mutableStateOf("") }
    var posting by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    val picker = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri -> imageUri = uri }

    LaunchedEffect(Unit) { picker.launch("image/*") }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            imageUri?.let { uri ->
                AsyncImage(
                    model = uri,
                    contentDescription = null,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(300.dp),
                    contentScale = ContentScale.Fit
                )
            }
            OutlinedTextField(
                value = caption,
                onValueChange = { caption = it },
                label = { Text("Add a caption…") },
                modifier = Modifier.fillMaxWidth()
            )
            error?.let { Text(it, color = Color.Red) }
            Button(
                onClick = {
                    val uri = imageUri ?: return@Button
                    posting = true
                    error = null
                    scope.launch {
                        try {
                            val bytes = withContext(Dispatchers.IO) {
                                context.contentResolver.openInputStream(uri)
                                    ?.readBytes()
                                    ?: throw RuntimeException("couldn't read image")
                            }
                            container.postService.createPost(bytes, caption)
                            onDismiss()
                        } catch (e: Exception) {
                            error = "Couldn't post. Check your connection and try again."
                        }
                        posting = false
                    }
                },
                enabled = imageUri != null && !posting,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(if (posting) "Posting…" else "Post")
            }
        }
    }
}
