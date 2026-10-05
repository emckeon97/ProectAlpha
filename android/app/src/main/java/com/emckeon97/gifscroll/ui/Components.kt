package com.emckeon97.gifscroll.ui

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp

/** Round dark button used for laugh / comment / flag / share actions. */
@Composable
fun CircleButton(
    icon: ImageVector,
    tint: Color = Color.White,
    onClick: () -> Unit
) {
    IconButton(
        onClick = onClick,
        modifier = Modifier
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.55f))
            .padding(4.dp)
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(28.dp))
    }
}

/** Shares a URL through the Android share sheet. */
fun shareUrl(context: Context, url: String) {
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, url)
    }
    context.startActivity(Intent.createChooser(intent, "Share"))
}
