import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct GifScrollApp: App {
    init() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
