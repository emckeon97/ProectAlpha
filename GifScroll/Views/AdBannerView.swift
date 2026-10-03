import SwiftUI
import GoogleMobileAds

/// AdMob config — live IDs. Change adEveryNItems to adjust ad frequency.
enum AdConfig {
    static let bannerUnitID = "ca-app-pub-8263714518098380/5630499497"
    /// Ad slots follow this repeating pattern: 5 memes, ad, 10 memes, ad, ...
    static let adPattern = [5, 10]
}

/// Full-screen ad page slotted into the vertical feed.
struct AdPageView: View {
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Advertisement")
                .font(.caption)
                .foregroundColor(.gray)
            AdBannerView()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = AdConfig.bannerUnitID
        let width = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? UIScreen.main.bounds.width
        banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
