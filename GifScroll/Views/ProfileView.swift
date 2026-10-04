import SwiftUI

/// The personal page: the signed-in user's profile, their uploads,
/// and the feed memes they've shared to their page.
struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var postService: PostService
    @EnvironmentObject var repostService: RepostService
    @EnvironmentObject var likeManager: LikeManager

    @State private var tab = 0 // 0 = Uploads, 1 = Shared, 2 = Favorites
    @State private var selectedPost: Post?
    @State private var selectedRepost: Repost?
    @State private var selectedLiked: LikedItem?

    private var uid: String? { auth.userId }
    private var myUploads: [Post] { postService.myPosts(userId: uid) }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    statsRow

                    Picker("Library", selection: $tab) {
                        Text("Uploads").tag(0)
                        Text("Shared").tag(1)
                        Text("Favorites").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if tab == 0 {
                        uploadsGrid
                    } else if tab == 1 {
                        sharedGrid
                    } else {
                        favoritesGrid
                    }
                }
                .padding(.top)
                .padding(.bottom, 32)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await repostService.refresh(userId: uid) }
        .onChange(of: uid) { _, newUid in
            Task { await repostService.refresh(userId: newUid) }
        }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post)
        }
        .sheet(item: $selectedRepost) { repost in
            RepostDetailView(repost: repost)
        }
        .sheet(item: $selectedLiked) { liked in
            LikedDetailView(liked: liked)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            Text(auth.currentDisplayName)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            if let email = auth.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Button("Sign Out") { auth.signOut() }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.top, 4)
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(myUploads.count)", label: "Uploads")
            statCell(value: "\(repostService.reposts.count)", label: "Shared")
            statCell(value: "\(likeManager.likedIDs.count)", label: "Likes")
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Grids

    private var uploadsGrid: some View {
        Group {
            if myUploads.isEmpty {
                emptyState(
                    icon: "photo.on.rectangle.angled",
                    title: "No uploads yet",
                    subtitle: "Post a meme and it'll show up here."
                )
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(myUploads) { post in
                        Button { selectedPost = post } label: {
                            UploadThumb(post: post)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var sharedGrid: some View {
        Group {
            if repostService.reposts.isEmpty {
                emptyState(
                    icon: "square.and.arrow.up",
                    title: "Nothing shared yet",
                    subtitle: "Use \"Share to my page\" on any feed meme."
                )
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(repostService.reposts) { repost in
                        Button { selectedRepost = repost } label: {
                            RepostThumb(repost: repost)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var favoritesGrid: some View {
        let favorites = likeManager.likedItems.filter { $0.url != nil }
        return Group {
            if favorites.isEmpty {
                emptyState(
                    icon: "face.smiling",
                    title: "No favorites yet",
                    subtitle: "Tap the laugh button on any meme to save it here."
                )
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(favorites) { liked in
                        Button { selectedLiked = liked } label: {
                            LikedThumb(liked: liked)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
}

// MARK: - Thumbnails

/// Square thumbnail for an uploaded post (local file or remote URL).
private struct UploadThumb: View {
    let post: Post
    @EnvironmentObject var postService: PostService
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color(white: 0.12)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .tint(.gray)
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .task { image = await postService.loadImage(for: post) }
    }
}

/// Square thumbnail for a shared feed meme.
private struct RepostThumb: View {
    let repost: Repost

    var body: some View {
        ZStack {
            Color(white: 0.12)
            if let url = repost.url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    default:
                        ProgressView().tint(.gray)
                    }
                }
            }
            if repost.kind == "video" {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
    }
}

// MARK: - Detail views

/// Full-screen view of one of the user's uploads, with delete.
private struct PostDetailView: View {
    let post: Post
    @EnvironmentObject var postService: PostService
    @Environment(\.dismiss) var dismiss

    @State private var image: UIImage?
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView()
                                .tint(.white)
                                .frame(height: 300)
                        }
                        if !post.caption.isEmpty {
                            Text(post.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                            Text("\(post.likeCount)")
                        }
                        .foregroundColor(.gray)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) { confirmingDelete = true } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .task { image = await postService.loadImage(for: post) }
            .confirmationDialog("Delete this post?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    postService.deletePost(post)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

/// Full-screen view of a shared feed meme, with remove.
private struct RepostDetailView: View {
    let repost: Repost
    @EnvironmentObject var repostService: RepostService
    @Environment(\.dismiss) var dismiss

    @State private var confirmingRemove = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    if repost.kind == "video", let url = repost.url {
                        VideoPlayerView(url: url)
                            .frame(height: 400)
                    } else if let url = repost.url {
                        AnimatedGifView(url: url)
                            .frame(height: 400)
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .frame(height: 300)
                    }
                    if !repost.title.isEmpty {
                        Text(repost.title)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Shared")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) { confirmingRemove = true } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .confirmationDialog("Remove from your page?", isPresented: $confirmingRemove, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    repostService.unshare(repost)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

/// Square thumbnail for a favorited (laugh-reacted) meme.
private struct LikedThumb: View {
    let liked: LikedItem

    var body: some View {
        ZStack {
            Color(white: 0.12)
            if let urlString = liked.url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    default:
                        ProgressView().tint(.gray)
                    }
                }
            }
            if liked.kind == "video" {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
    }
}

/// Full-screen view of a favorited meme, with unlike.
private struct LikedDetailView: View {
    let liked: LikedItem
    @EnvironmentObject var likeManager: LikeManager
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    if liked.kind == "video",
                       let urlString = liked.url, let url = URL(string: urlString) {
                        VideoPlayerView(url: url)
                            .frame(height: 400)
                    } else if let urlString = liked.url, let url = URL(string: urlString) {
                        AnimatedGifView(url: url)
                            .frame(height: 400)
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .frame(height: 300)
                    }
                    if !liked.title.isEmpty {
                        Text(liked.title)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Favorite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        likeManager.toggleLike(id: liked.id, title: liked.title, url: nil, kind: nil, userId: auth.userId, signedIn: auth.isSignedIn)
                        dismiss()
                    } label: {
                        Image(systemName: "face.smiling.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
    }
}
