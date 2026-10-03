import SwiftUI
import GoogleMobileAds

@main
struct GifScrollApp: App {
    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
