package com.emckeon97.gifscroll.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Upload
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.emckeon97.gifscroll.data.AppContainer

@Composable
fun MainScreen(container: AppContainer) {
    var tab by remember { mutableIntStateOf(1) } // Feed is the landing tab.

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = tab == 0,
                    onClick = { tab = 0 },
                    icon = { Icon(Icons.Filled.Upload, null) },
                    label = { Text("Upload") }
                )
                NavigationBarItem(
                    selected = tab == 1,
                    onClick = { tab = 1 },
                    icon = { Icon(Icons.Filled.LocalFireDepartment, null) },
                    label = { Text("Feed") }
                )
                NavigationBarItem(
                    selected = tab == 2,
                    onClick = { tab = 2 },
                    icon = { Icon(Icons.Filled.Person, null) },
                    label = { Text("Account") }
                )
            }
        }
    ) { inner ->
        val mod = Modifier.padding(inner)
        when (tab) {
            0 -> UploadFeedScreen(container, mod)
            1 -> FeedScreen(container, mod)
            2 -> AccountScreen(container, mod)
        }
    }
}
