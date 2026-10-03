import SwiftUI

/// One full-screen page in the swipe feed.
struct GifPageView: View {
    let gif: Gif
    @ObservedObject var likeManager: LikeManager

    @State private var showingComments = false
    @State private var showingReport = false

    var body: some View {
        ZStack {
            AnimatedGifView(url: gif.fullURL)
                .ignoresSafeArea()

            VStack {
                Spacer()

                HStack(spacing: 16) {
                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            likeManager.toggleLike(gif)
                        }
                    } label: {
                        Image(systemName: likeManager.isLiked(gif) ? "face.smiling.fill" : "face.smiling")
                            .font(.title2)
                            .foregroundColor(likeManager.isLiked(gif) ? .yellow : .white)
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

                    if let url = gif.fullURL {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.55))
                                .clipShape(Circle())
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showingComments) {
            CommentsView(postID: nil, gifID: gif.id)
        }
        .sheet(isPresented: $showingReport) {
            ReportView(target: .gif(id: gif.id, title: gif.title))
        }
    }
}
