import SwiftUI

struct GifDetailView: View {
    let gif: Gif

    var body: some View {
        VStack(spacing: 16) {
            AnimatedGifView(url: gif.fullURL)
                .frame(maxWidth: .infinity, maxHeight: 400)
                .cornerRadius(12)
                .padding()

            Text(gif.title.isEmpty ? "Untitled GIF" : gif.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let url = gif.fullURL {
                ShareLink(item: url) {
                    Label("Share GIF", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .navigationTitle("GIF")
        .navigationBarTitleDisplayMode(.inline)
    }
}
