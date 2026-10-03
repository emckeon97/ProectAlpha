import SwiftUI

struct MainTabView: View {
    @StateObject private var postService = PostService()
    @StateObject private var likeManager = LikeManager()
    @StateObject private var auth = AuthManager()

    var body: some View {
        TabView {
            UserFeedView()
                .tabItem {
                    Label("Upload", systemImage: "tray.and.arrow.up.fill")
                }

            ContentView()
                .tabItem {
                    Label("Feed", systemImage: "flame")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                }
        }
        .environmentObject(postService)
        .environmentObject(likeManager)
        .environmentObject(auth)
    }
}
