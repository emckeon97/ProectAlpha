import SwiftUI

struct MainTabView: View {
    @StateObject private var postService = LocalPostService()
    @StateObject private var likeManager = LikeManager()

    var body: some View {
        TabView {
            UserFeedView()
                .tabItem {
                    Label("Fresh", systemImage: "flame")
                }

            ContentView()
                .tabItem {
                    Label("GIFs", systemImage: "magnifyingglass")
                }
        }
        .environmentObject(postService)
        .environmentObject(likeManager)
    }
}
