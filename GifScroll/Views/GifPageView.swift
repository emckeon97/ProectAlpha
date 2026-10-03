import SwiftUI

/// One full-screen page in the meme feed: image, GIF, or video.
struct FeedItemView: View {
    let item: FeedItem
    @ObservedObject var likeManager: LikeManager
    @EnvironmentObject var repostService: RepostService
    @EnvironmentObject var auth: AuthManager

    @State private var showingComments = false
    @State private var showingReport = false

    var body: some View {
        ZStack {
            if item.kind == .video {
                VideoPlayerView(url: item.url)
            } else {
                AnimatedGifView(url: item.url)
                    .ignoresSafeArea()
            }

            VStack {
                Spacer()

                HStack(spacing: 16) {
                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            likeManager.toggleLike(id: item.id, title: item.title, url: item.url, kind: item.kind)
                        }
                    } label: {
                        Image(systemName: likeManager.isLiked(id: item.id) ? "face.smiling.fill" : "face.smiling")
                            .font(.title2)
                            .foregroundColor(likeManager.isLiked(id: item.id) ? .yellow : .white)
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

                    Menu {
                        Button {
                            repostService.share(item: item, userId: auth.userId)
                        } label: {
                            Label("Share to my page", systemImage: "person.crop.square")
                        }
                        .disabled(repostService.isShared(itemId: item.id))

                        ShareLink(item: item.url) {
                            Label("Share…", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
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
        .sheet(isPresented: $showingComments) {
            CommentsView(postID: nil, gifID: item.id)
        }
        .sheet(isPresented: $showingReport) {
            ReportView(target: .gif(id: item.id, title: item.title))
        }
    }
}
