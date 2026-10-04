import SwiftUI

/// One full-screen page for a user post in the Fresh feed.
struct PostPageView: View {
    let post: Post
    @ObservedObject var likeManager: LikeManager

    @EnvironmentObject var postService: PostService
    @EnvironmentObject var auth: AuthManager
    @State private var image: UIImage?
    @State private var showingComments = false
    @State private var showingReport = false

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
                            likeManager.toggleLike(id: post.id, title: post.caption, url: post.imageURL.flatMap(URL.init(string:)), kind: .image, userId: auth.userId, signedIn: auth.isSignedIn)
                        }
                    } label: {
                        Image(systemName: likeManager.isLiked(id: post.id) ? "face.smiling.fill" : "face.smiling")
                            .font(.title2)
                            .foregroundColor(likeManager.isLiked(id: post.id) ? .yellow : .white)
                            .padding(12)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }

                    Button {
                        showingComments = true
                    } label: {
                        Image(systemName: "bubble.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }

                    Button {
                        showingReport = true
                    } label: {
                        Image(systemName: "flag")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.bottom, 100)
            }
        }
        .task {
            image = await postService.loadImage(for: post)
        }
        .sheet(isPresented: $showingComments) {
            CommentsView(postID: post.id, gifID: nil)
        }
        .sheet(isPresented: $showingReport) {
            ReportView(target: .post(post))
        }
    }
}
