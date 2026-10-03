import SwiftUI

/// One full-screen page for a user post in the Fresh feed.
struct PostPageView: View {
    let post: Post
    @ObservedObject var likeManager: LikeManager

    @EnvironmentObject var postService: PostService
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .clipped()
            } else {
                ProgressView()
                    .tint(.white)
            }

            VStack {
                Spacer()

                if !post.caption.isEmpty {
                    Text(post.caption)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .shadow(radius: 4)
                }

                HStack(spacing: 16) {
                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            likeManager.toggleLike(id: post.id, title: post.caption)
                        }
                    } label: {
                        Image(systemName: likeManager.isLiked(id: post.id) ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(likeManager.isLiked(id: post.id) ? .red : .white)
                            .padding(12)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.bottom, 60)
            }
        }
        .task {
            image = await postService.loadImage(for: post)
        }
    }
}
