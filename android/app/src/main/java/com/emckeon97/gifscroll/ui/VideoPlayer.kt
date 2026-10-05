package com.emckeon97.gifscroll.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeOff
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView

/**
 * Full-screen looping video page. Tap toggles mute.
 * Plays only while [isPlaying] (the visible pager page).
 */
@Composable
fun VideoPage(url: String, isPlaying: Boolean, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    var muted by remember { mutableStateOf(false) }

    val player = remember(url) {
        ExoPlayer.Builder(context).build().apply {
            setMediaItem(MediaItem.fromUri(url))
            repeatMode = Player.REPEAT_MODE_ONE
            prepare()
        }
    }

    LaunchedEffect(isPlaying) {
        if (isPlaying) player.play() else player.pause()
    }
    LaunchedEffect(muted) {
        player.volume = if (muted) 0f else 1f
    }
    DisposableEffect(Unit) {
        onDispose { player.release() }
    }

    Box(
        modifier
            .fillMaxSize()
            .background(Color.Black)
            .clickable { muted = !muted }
    ) {
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    this.player = player
                    useController = false
                }
            },
            modifier = Modifier.fillMaxSize()
        )
        Icon(
            imageVector = if (muted) Icons.AutoMirrored.Filled.VolumeOff else Icons.AutoMirrored.Filled.VolumeUp,
            contentDescription = if (muted) "Unmute" else "Mute",
            tint = Color.White.copy(alpha = 0.85f),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(end = 16.dp, bottom = 170.dp)
        )
    }
}
