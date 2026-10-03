# GifScroll — iOS (SwiftUI)

A TikTok-style comedy GIF feed with a community layer: swipe through funny GIFs,
react, comment, and upload your own memes. Zero third-party SDKs.

## Tabs

- **Feed** — full-screen swipeable comedy GIF feed (Giphy), ranked by your reactions
- **Upload** — community meme feed; post your own photos with captions
- **Account** — sign up / sign in (Supabase Auth)

## Features

- Laugh-react button; the feed learns your taste from keywords in what you react to
- Comments on every GIF and post — anonymous allowed
- Reporting on memes and comments (moderation queue in Supabase)
- Supabase backend (PostgREST + Storage + Auth) with on-device fallback

## Run it

1. Open `GifScroll.xcodeproj` in Xcode on your Mac.
2. Your Giphy API key is already in `Services/GiphyService.swift`.
3. Your Supabase project URL + publishable key are in `Services/SupabaseManager.swift`.
4. Run the SQL in `docs/` (or your notes) in the Supabase SQL editor to create the
   `posts`, `comments`, and `reports` tables plus the `post-images` storage bucket.
5. Add your app icon PNG as `GifScroll/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`.
6. Pick your team in Signing & Capabilities, hit Run.

## What's in here

- `GifScrollApp.swift` — app entry point
- `Views/MainTabView.swift` — Upload / Feed / Account tabs
- `Views/ContentView.swift` — comedy GIF feed (Giphy)
- `Views/UserFeedView.swift` — community meme feed (Supabase)
- `Views/UploadView.swift` — photo picker + caption + post
- `Views/PostPageView.swift` / `Views/GifPageView.swift` — full-screen pages
- `Views/CommentsView.swift` — comment threads
- `Views/ReportView.swift` — report memes and comments
- `Views/AuthView.swift` / `Views/AccountView.swift` — accounts
- `Services/GiphyService.swift` — Giphy API: comedy feed
- `Services/PostService.swift` — posts, Supabase-first with local fallback
- `Services/SupabaseManager.swift` — Supabase REST client (no SDK)
- `Services/AuthManager.swift` — auth session
- `Services/LikeManager.swift` — reaction tracking + keyword ranking
- `Models/` — `Gif`, `Post`, `Comment`
