import SwiftUI
import GoogleMobileAds

/// AdMob config. These are Google's TEST ids — they always serve test ads.
/// When you're ready to earn: create an app + ad units at apps.admob.com and
/// swap the values here (and GADApplicationIdentifier in Info.plist).
enum AdConfig {
    static let bannerUnitID = "ca-app-pub-3940256099942544/6300978111"
    static let adEveryNItems = 5
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
