import SwiftUI

/// One full-screen page in the swipe feed.
struct GifPageView: View {
    let gif: Gif

    var body: some View {
        ZStack {
            AnimatedGifView(url: gif.fullURL)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 10) {
                    Text(gif.title.isEmpty ? "Untitled GIF" : gif.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .shadow(radius: 4)

                    if let url = gif.fullURL {
                        ShareLink(item: url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}
