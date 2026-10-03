import SwiftUI

/// The community feed: user-uploaded posts, one per full-screen page.
struct UserFeedView: View {
    @EnvironmentObject var postService: PostService
    @EnvironmentObject var likeManager: LikeManager

    @State private var showingUpload = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if postService.posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No posts yet")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Be the first to post something funny.")
                            .foregroundColor(.gray)
                        Button("Upload a meme") { showingUpload = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(postService.posts) { post in
                                PostPageView(post: post, likeManager: likeManager)
                                    .containerRelativeFrame(.vertical)
                                    .id(post.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .ignoresSafeArea()
                }
            }
            .navigationTitle("GifScroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingUpload = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingUpload) {
                UploadView()
            }
            .task {
                await postService.refresh()
            }
        }
    }
}
