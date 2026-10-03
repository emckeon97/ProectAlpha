import SwiftUI

/// One full-screen page in the swipe feed.
struct GifPageView: View {
    let gif: Gif
    @ObservedObject var likeManager: LikeManager

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
                        Image(systemName: likeManager.isLiked(gif) ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(likeManager.isLiked(gif) ? .red : .white)
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
    }
}
