# GifScroll for Android

The Android port of GifScroll — a comedy GIF and meme app. Swipe through an
endless feed of funny GIFs, react with a laugh, talk trash in the comments,
and upload your own memes for the community.

Native Kotlin + Jetpack Compose. No third-party SDKs beyond image loading.

## What it does

- **Feed** — full-screen, TikTok-style swipe feed of comedy GIFs (Giphy). The feed
  leans funny by default and learns your taste: reacting to GIFs teaches it which
  keywords you like, so similar ones surface first.
- **Upload** — community meme feed. Pick a photo, add a caption, post it. Uploads
  live in the cloud and show up for everyone.
- **Comments** — every GIF and every meme has its own thread. No account needed;
  signed-in users post under their display name, everyone else shows as "anon".
- **Reactions** — one-tap laugh react on anything.
- **Reports** — flag button on every meme and comment feeds a moderation queue.
- **Accounts** — email sign-up / sign-in, session persists across launches.

## Compatibility

Android 8.0 (API 26) and later.

## Setup

1. Open this folder in Android Studio. It will sync Gradle automatically
   (no wrapper files needed).
2. Copy `app/src/main/java/com/emckeon97/gifscroll/Secrets.template.kt`
   to `Secrets.kt` in the same folder and paste your Giphy API key
   (get one at https://developers.giphy.com/dashboard/).
   `Secrets.kt` is gitignored and never committed.
3. The Supabase backend is shared with the iOS app — same project, same
   `posts` / `comments` / `reports` tables and `post-images` bucket.
   See the main GifScroll repo README for the SQL setup.
4. Run on a device or emulator.

## Tech

- Kotlin + Jetpack Compose (Material 3)
- OkHttp for networking (Giphy + Supabase REST, no SDKs)
- Coil for animated GIF loading
- SharedPreferences for reactions, auth session, and offline post cache

© 2026 Elijah McKeon. All rights reserved.
