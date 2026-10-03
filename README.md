# Project Alpha — iOS (SwiftUI)

A basic GIF browser app: trending feed, search, GIF detail with share.
Zero third-party dependencies.

## Run it

1. Open `ProjectAlpha.xcodeproj` in Xcode on your Mac.
2. Your Giphy API key is already in `GiphyService.swift`.
3. Pick your team in Signing & Capabilities, hit Run.

## What's in here

- `ProjectAlphaApp.swift` — app entry point
- `Views/ContentView.swift` — searchable 2-column GIF grid
- `Views/GifDetailView.swift` — full-size GIF + share sheet
- `Views/AnimatedGifView.swift` — GIF rendering via WKWebView (no libs)
- `Services/GiphyService.swift` — Giphy API: trending + search
- `Models/Gif.swift` — Giphy response models

## Next steps (whenever)

- Favorites / saved GIFs (SwiftData)
- Keyboard extension target
- Dark mode polish, haptics
