# GifScroll — Windows Port (.NET MAUI)

A Windows port of **GifScroll**, the TikTok-style comedy GIF/meme app.
Same feed (Reddit's meme communities, like-based keyword ranking), same
Supabase backend for comments/reports/uploads/auth.

## Tech

- **.NET 10 MAUI**, Windows-only target (`net10.0-windows10.0.19041.0`)
- **CommunityToolkit.Maui** `MediaElement` for video posts (looping, autoplay)
- MAUI `Image` for stills and animated GIFs
- Raw `HttpClient` REST for Reddit + Supabase (no SDK dependencies)

## Build it (on Windows)

You need the **.NET 10 SDK** and **Visual Studio 2026** with the
“.NET Multi-platform App UI development” workload.

```powershell
cd windows\GifScroll.Windows
dotnet restore
dotnet build -c Release
dotnet run -c Release -f net10.0-windows10.0.19041.0
```

Or open the `.csproj` in Visual Studio and press F5 (target: Windows Machine).

> MAUI Windows targets must be built on Windows (your Parallels VM works).

## Project map

| File | What |
|------|------|
| `Services/RedditService.cs` | Meme feed: r/memes, r/dankmemes, r/funny (rotated), 50 per load, User-Agent header |
| `Services/LikeManager.cs` | Local like store + keyword ranking (persisted) |
| `Services/SupabaseClient.cs` | Auth, comments, reports, uploads feed (REST, publishable key ships in-app like the mobile ports) |
| `Views/FeedPage` | Vertical swipe feed (CarouselView, snap-to-page), 😂/💬/🚩 actions |
| `Views/CommentsPage` | Comments per meme (anonymous posting OK) |
| `Views/UploadsPage` | Community uploads from Supabase |
| `Views/AccountPage` | Sign in / sign up / sign out (session persisted) |

## Notes

- The Supabase **publishable** key is baked in, exactly like the iOS and
  Android apps ship it — it's designed for client use.
- Likes and keyword scores persist locally (`gifscroll.likedIDs`,
  `gifscroll.keywordScores`); the auth token persists too.
- No ads on Windows (no AdMob for MAUI Windows) — the premium edition.
