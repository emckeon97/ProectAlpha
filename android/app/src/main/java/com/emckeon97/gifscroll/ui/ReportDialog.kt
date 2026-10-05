package com.emckeon97.gifscroll.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectable
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.emckeon97.gifscroll.data.AppContainer
import com.emckeon97.gifscroll.data.SupabaseManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

sealed interface ReportTarget {
    data class Post(val id: String) : ReportTarget
    data class Gif(val id: String) : ReportTarget
    data class Comment(val id: String) : ReportTarget
}

/** Report a meme or a comment. Reports land in the `reports` table for review. */
@Composable
fun ReportDialog(
    target: ReportTarget,
    container: AppContainer,
    onDismiss: () -> Unit
) {
    val reasons = listOf(
        "Spam", "Harassment", "Hate speech", "Sexual content", "Violence", "Other"
    )
    var reason by remember { mutableStateOf(reasons[0]) }
    var details by remember { mutableStateOf("") }
    var sending by remember { mutableStateOf(false) }
    var done by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Report") },
        text = {
            Column {
                if (done) {
                    Text("Thanks — we'll take a look.")
                } else {
                    reasons.forEach { r ->
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .selectable(
                                    selected = reason == r,
                                    onClick = { reason = r }
                                )
                                .padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = reason == r,
                                onClick = { reason = r }
                            )
                            Text(r, Modifier.padding(start = 8.dp))
                        }
                    }
                    OutlinedTextField(
                        value = details,
                        onValueChange = { details = it },
                        label = { Text("Details (optional)") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 8.dp)
                    )
                }
            }
        },
        confirmButton = {
            if (!done) {
                TextButton(
                    onClick = {
                        sending = true
                        scope.launch {
                            try {
                                withContext(Dispatchers.IO) {
                                    val name = container.authManager.currentDisplayName
                                    when (target) {
                                        is ReportTarget.Post -> SupabaseManager.insertReport(
                                            postId = target.id, reason = reason,
                                            details = details, reporterName = name
                                        )
                                        is ReportTarget.Gif -> SupabaseManager.insertReport(
                                            gifId = target.id, reason = reason,
                                            details = details, reporterName = name
                                        )
                                        is ReportTarget.Comment -> SupabaseManager.insertReport(
                                            commentId = target.id, reason = reason,
                                            details = details, reporterName = name
                                        )
                                    }
                                }
                                done = true
                            } catch (e: Exception) {
                                // Stay open so the user can retry.
                            }
                            sending = false
                        }
                    },
                    enabled = !sending
                ) {
                    Text("Submit")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(if (done) "Close" else "Cancel")
            }
        }
    )
}
