package com.emckeon97.gifscroll.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.emckeon97.gifscroll.data.AppContainer
import kotlinx.coroutines.launch

/** The account tab: sign in/up form, or the signed-in profile with sign out. */
@Composable
fun AccountScreen(container: AppContainer, modifier: Modifier = Modifier) {
    val signedIn by container.authManager.isSignedIn.collectAsState()

    Box(
        modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        if (signedIn) {
            val email by container.authManager.email.collectAsState()
            val name by container.authManager.displayName.collectAsState()
            Column(
                Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Spacer(Modifier.height(32.dp))
                Icon(
                    Icons.Filled.Person,
                    contentDescription = null,
                    tint = Color.Gray,
                    modifier = Modifier.padding(8.dp)
                )
                Text(
                    name ?: "anon",
                    color = Color.White,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold
                )
                email?.let { Text(it, color = Color.Gray) }
                Spacer(Modifier.height(16.dp))
                OutlinedButton(onClick = { container.authManager.signOut() }) {
                    Text("Sign Out", color = Color.Red)
                }
            }
        } else {
            AuthForm(container)
        }
    }
}

@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
private fun AuthForm(container: AppContainer) {
    var mode by remember { mutableIntStateOf(0) } // 0 = sign in, 1 = sign up
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var working by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    Column(
        Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Spacer(Modifier.height(24.dp))
        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
            SegmentedButton(
                selected = mode == 0,
                onClick = { mode = 0 },
                shape = SegmentedButtonDefaults.itemShape(0, 2)
            ) { Text("Sign In") }
            SegmentedButton(
                selected = mode == 1,
                onClick = { mode = 1 },
                shape = SegmentedButtonDefaults.itemShape(1, 2)
            ) { Text("Sign Up") }
        }
        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth()
        )
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth()
        )
        if (mode == 1) {
            OutlinedTextField(
                value = displayName,
                onValueChange = { displayName = it },
                label = { Text("Display name") },
                modifier = Modifier.fillMaxWidth()
            )
        }
        error?.let { Text(it, color = Color.Red) }
        notice?.let { Text(it, color = Color.Green) }
        Button(
            onClick = {
                working = true
                error = null
                notice = null
                scope.launch {
                    try {
                        if (mode == 0) {
                            container.authManager.signIn(email, password)
                        } else {
                            val immediate = container.authManager.signUp(
                                email, password, displayName
                            )
                            if (!immediate) {
                                notice = "Account created — check your email to confirm, then sign in."
                            }
                        }
                    } catch (e: Exception) {
                        error = "That didn't work. Check your details and try again."
                    }
                    working = false
                }
            },
            enabled = !working && email.isNotBlank() && password.isNotBlank() &&
                (mode == 0 || displayName.isNotBlank()),
            modifier = Modifier.fillMaxWidth()
        ) {
            if (working) {
                CircularProgressIndicator(
                    modifier = Modifier.padding(4.dp),
                    color = Color.White
                )
            } else {
                Text(if (mode == 0) "Sign In" else "Create Account")
            }
        }
        TextButton(onClick = { /* reserved for password reset */ }) { }
    }
}
