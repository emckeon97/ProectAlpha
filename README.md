# GifScroll

A comedy meme app for iOS, iPadOS, and macOS. Swipe through an endless feed of funny memes, GIFs, and videos, react with a laugh, talk trash in the comments, and upload your own memes for the community.

## Compatibility

- **iOS** 17 and later (iPhone)
- **iPadOS** 17 and later (iPad, all orientations)
- **macOS** (via Mac Catalyst — runs natively on Apple silicon and Intel Macs; no ads on Mac)

## What it does

- **Feed** — full-screen, TikTok-style swipe feed of memes, GIFs, and videos, powered by Reddit's meme communities (no API key needed). Videos play inline with tap-to-mute. The feed leans funny by default and learns your taste: laugh-reacting teaches it which keywords you like, so similar ones surface first. Broken links and dead images are filtered out automatically before they reach you.
- **Upload** — community meme feed. Post your own memes for everyone to see.
- **Profile** — your personal page: an Uploads grid of your memes, a Shared grid of feed memes you reposted to your page, and a Favorites grid of everything you laugh-reacted to.
- **Comments** — every meme has its own thread. No account needed; signed-in users post under their display name, everyone else shows as "anon".
- **Reactions** — one-tap laugh react on anything.
- **Reports** — flag anything that crosses the line; reports go to moderation.
- **Accounts** — optional email sign-in to post under your own name.

## Backend

GifScroll uses Supabase for auth, uploads, comments, and reports. The SQL setup (tables for posts, comments, reports, and reposts, plus the `post-images` storage bucket) lives in the release notes. An Android port shares the same backend.

© 2026 Elijah McKeon. All rights reserved.
