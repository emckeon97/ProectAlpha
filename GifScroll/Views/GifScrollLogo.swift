import SwiftUI

/// The GifScroll wordmark: "Gif" in Instagram-style gradient, "Scroll" in white.
/// Bold, clean, dark-mode first.
struct GifScrollLogo: View {
    var fontSize: CGFloat = 28

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0x83/255, green: 0x3A/255, blue: 0xB4/255), // purple
                Color(red: 0xFD/255, green: 0x1D/255, blue: 0x1D/255), // pink-red
                Color(red: 0xFC/255, green: 0xB0/255, blue: 0x45/255), // orange
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("Gif")
                .font(.system(size: fontSize, weight: .black))
                .foregroundStyle(gradient)
            Text("Scroll")
                .font(.system(size: fontSize, weight: .black))
                .foregroundColor(.white)
        }
    }
}
