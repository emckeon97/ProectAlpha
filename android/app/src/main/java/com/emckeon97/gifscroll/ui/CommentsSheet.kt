package com.emckeon97.gifscroll.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.emckeon97.gifscroll.data.AppContainer
import com.emckeon97.gifscroll.data.SupabaseManager
import com.emckeon97.gifscroll.model.Comment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Comment thread for a user post or a GIF.
 * Anonymous commenting is allowed; signed-in users post under their display name.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CommentsSheet(
    postId: String?,
    gifId: String?,
    container: AppContainer,
    onDismiss: () -> Unit
) {
    var comments by remember { mutableStateOf<List<Comment>>(emptyList()) }
    var draft by remember { mutableStateOf("") }
    var loading by remember { mutableStateOf(true) }
    var sending by remember { mutableStateOf(false) }
    var reporting by remember { mutableStateOf<Comment?>(null) }
    val scope = rememberCoroutineScope()
    val displayName = container.authManager.currentDisplayName

    LaunchedEffect(postId, gifId) {
        comments = try {
            withContext(Dispatchers.IO) {
                SupabaseManager.fetchComments(postId, gifId)
            }
        } catch (e: Exception) {
            emptyList()
        }
        loading = false
    }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.fillMaxHeight(0.85f)) {
            Text(
                "Comments",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(16.dp)
            )
            when {
                loading -> CircularProgressIndicator(
                    Modifier
                        .align(Alignment.CenterHorizontally)
                        .padding(32.dp)
                )
                comments.isEmpty() -> Column(
                    Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text("No comments yet.", color = Color.Gray)
                    Text("Start the conversation.", color = Color.Gray)
                }
                else -> LazyColumn(Modifier.weight(1f)) {
                    items(comments, key = { it.id }) { comment ->
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.Top
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    comment.displayName,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = Color.Gray
                                )
                                Text(comment.body)
                            }
                            IconButton(onClick = { reporting = comment }) {
                                Icon(
                                    Icons.Filled.Flag,
                                    contentDescription = "Report",
                                    tint = Color.Gray
                                )
                            }
                        }
                    }
                }
            }
            Row(
                Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surfaceVariant)
                    .padding(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextField(
                    value = draft,
                    onValueChange = { draft = it },
                    placeholder = { Text("Add a comment…") },
                    modifier = Modifier.weight(1f)
                )
                IconButton(
                    onClick = {
                        val body = draft.trim()
                        if (body.isEmpty()) return@IconButton
                        sending = true
                        scope.launch {
                            try {
                                val nc = withContext(Dispatchers.IO) {
                                    SupabaseManager.insertComment(
                                        postId, gifId, body, displayName
                                    )
                                }
                                comments = comments + nc
                                draft = ""
                            } catch (e: Exception) {
                                // Leave the draft in place so nothing is lost.
                            }
                            sending = false
                        }
                    },
                    enabled = draft.isNotBlank() && !sending
                ) {
                    Icon(Icons.AutoMirrored.Filled.Send, contentDescription = "Send")
                }
            }
        }
    }

    reporting?.let { comment ->
        ReportDialog(
            target = ReportTarget.Comment(comment.id),
            container = container,
            onDismiss = { reporting = null }
        )
    }
}
