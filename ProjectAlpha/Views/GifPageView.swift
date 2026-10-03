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

                if let url = gif.fullURL {
                    ShareLink(item: url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}
