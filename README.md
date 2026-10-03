# GifScroll

A comedy GIF and meme app for iOS. Swipe through an endless feed of funny GIFs,
react with a laugh, talk trash in the comments, and upload your own memes for
the community. Built with SwiftUI — no third-party SDKs.

## What it does

- **Feed** — full-screen, TikTok-style swipe feed of comedy GIFs (Giphy). The feed
  leans funny by default and learns your taste: reacting to GIFs teaches it which
  keywords you like, so similar ones surface first.
- **Upload** — community meme feed. Pick a photo, add a caption, post it. Your
  uploads live in the cloud and show up for everyone.
- **Comments** — every GIF and every meme has its own thread. No account needed;
  signed-in users post under their display name, everyone else shows as "anon".
- **Reactions** — one-tap laugh react on anything.
- **Reports** — flag button on every meme and comment feeds a moderation queue.
- **Accounts** — email sign-up / sign-in, session persists across launches.

## How it's built

- **SwiftUI** throughout, iOS 17+
- **Giphy API** for the comedy GIF feed
- **Supabase** (REST, no SDK) for everything else:
  - PostgREST — `posts`, `comments`, `reports` tables
  - Storage — `post-images` bucket for uploads
  - Auth — email sign-up / sign-in
- On-device fallback: posts keep working locally when the backend is unreachable

## Project layout

```
GifScroll/
├── GifScrollApp.swift          # App entry point
├── Info.plist
├── Assets.xcassets/            # App icon (add AppIcon-1024.png here)
├── Models/                     # Gif, Post, Comment
├── Services/
│   ├── GiphyService.swift      # Giphy API: comedy feed
│   ├── SupabaseManager.swift   # Supabase REST client (posts, comments, reports, auth, storage)
│   ├── PostService.swift       # Post store: Supabase-first, local fallback
│   ├── AuthManager.swift        # Auth session
│   └── LikeManager.swift       # Reaction tracking + keyword ranking
└── Views/
    ├── MainTabView.swift        # Upload / Feed / Account tabs
    ├── ContentView.swift        # Comedy GIF feed
    ├── UserFeedView.swift       # Community meme feed
    ├── GifPageView.swift        # Full-screen GIF page
    ├── PostPageView.swift       # Full-screen meme page
    ├── UploadView.swift         # Photo picker + caption + post
    ├── CommentsView.swift       # Comment threads
    ├── ReportView.swift         # Report memes and comments
    ├── AuthView.swift           # Sign in / sign up
    └── AccountView.swift        # Account tab
```

## Backend setup (Supabase)

Keys live in `Services/SupabaseManager.swift` (project URL + publishable key).
Run this once in the Supabase SQL editor, in order:

```sql
-- 1. Posts table + image bucket
create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  caption text not null default '',
  like_count int not null default 0,
  created_at timestamptz not null default now()
);
alter table posts enable row level security;
drop policy if exists "public read" on posts;
create policy "public read" on posts for select using (true);
drop policy if exists "public insert" on posts;
create policy "public insert" on posts for insert with check (true);

insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do nothing;

drop policy if exists "public read storage" on storage.objects;
create policy "public read storage" on storage.objects
for select using (bucket_id = 'post-images');
drop policy if exists "public upload storage" on storage.objects;
create policy "public upload storage" on storage.objects
for insert with check (bucket_id = 'post-images');

-- 2. Comments (user posts + GIF threads)
create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references posts(id) on delete cascade,
  gif_id text,
  user_id uuid references auth.users(id) on delete set null,
  display_name text not null default 'anon',
  body text not null,
  created_at timestamptz not null default now()
);
alter table comments enable row level security;
drop policy if exists "public read comments" on comments;
create policy "public read comments" on comments for select using (true);
drop policy if exists "public insert comments" on comments;
create policy "public insert comments" on comments for insert with check (true);

-- 3. Reports (write-only; review in the dashboard)
create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references posts(id) on delete cascade,
  gif_id text,
  comment_id uuid references comments(id) on delete cascade,
  reason text not null,
  details text not null default '',
  reporter_name text not null default 'anon',
  created_at timestamptz not null default now()
);
alter table reports enable row level security;
drop policy if exists "public insert reports" on reports;
create policy "public insert reports" on reports for insert with check (true);
```

Tip: under Authentication → Providers → Email, turn off "Confirm email" if you
don't want new signups to verify before signing in.

## Running it

1. Open `GifScroll.xcodeproj` in Xcode.
2. Drop your icon PNG into `GifScroll/Assets.xcassets/AppIcon.appiconset/` as `AppIcon-1024.png`.
3. Pick your team in Signing & Capabilities, hit Run.

© 2026 Elijah McKeon. All rights reserved.
