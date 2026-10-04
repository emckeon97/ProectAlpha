import SwiftUI

struct ContentView: View {
    @StateObject private var service = KlipyService()
    @EnvironmentObject var likeManager: LikeManager
    @EnvironmentObject var auth: AuthManager

    /// Feed pages with ad slots (nil) interleaved on a repeating 5 / 10 pattern.
    /// On macOS (Catalyst) there is no AdMob SDK, so no ad slots are inserted.
    private var pages: [FeedItem?] {
        #if canImport(GoogleMobileAds)
        var result: [FeedItem?] = []
        var sinceAd = 0
        var patternIndex = 0
        for item in service.items {
            result.append(item)
            sinceAd += 1
            if sinceAd >= AdConfig.adPattern[patternIndex % AdConfig.adPattern.count] {
                result.append(nil)
                sinceAd = 0
                patternIndex += 1
            }
        }
        return result
        #else
        return service.items.map { Optional($0) }
        #endif
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if service.isLoading && service.items.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else if let error = service.errorMessage, service.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text(error)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0) {
                                ForEach(pages.indices, id: \.self) { index in
                                    if let item = pages[index] {
                                        FeedItemView(item: item, likeManager: likeManager)
                                            .containerRelativeFrame(.vertical)
                                            .id(item.id)
                                    } else {
                                        AdPageView()
                                            .containerRelativeFrame(.vertical)
                                            .id("ad-\(index)")
                                    }
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging)
                        .ignoresSafeArea()
                        .onChange(of: service.items.map(\.id)) { _, _ in
                            if let first = service.items.first {
                                withAnimation {
                                    proxy.scrollTo(first.id, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    GifScrollLogo(fontSize: 34)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                service.likeManager = likeManager
                service.memeFeed()
                likeManager.refresh(userId: auth.userId, signedIn: auth.isSignedIn)
            }
            .onChange(of: auth.isSignedIn) { _, signedIn in
                likeManager.refresh(userId: auth.userId, signedIn: signedIn)
            }
        }
    }
}
