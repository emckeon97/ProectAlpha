import SwiftUI

struct MainTabView: View {
    @StateObject private var postService = PostService()
    @StateObject private var likeManager = LikeManager()
    @StateObject private var auth = AuthManager()
    @State private var selectedTab = 1 // Feed is the landing tab.

    var body: some View {
        TabView(selection: $selectedTab) {
            UserFeedView()
                .tabItem {
                    Label("Upload", systemImage: "tray.and.arrow.up.fill")
                }
                .tag(0)

            ContentView()
                .tabItem {
                    Label("Feed", systemImage: "flame")
                }
                .tag(1)

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                }
                .tag(2)
        }
        .environmentObject(postService)
        .environmentObject(likeManager)
        .environmentObject(auth)
    }
}
