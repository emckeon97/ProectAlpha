import SwiftUI

struct ContentView: View {
    @StateObject private var service = RedditService()
    @EnvironmentObject var likeManager: LikeManager

    /// Feed pages with an ad slot (nil) interleaved every N memes.
    private var pages: [FeedItem?] {
        var result: [FeedItem?] = []
        for (index, item) in service.items.enumerated() {
            result.append(item)
            if (index + 1) % AdConfig.adEveryNItems == 0 {
                result.append(nil)
            }
        }
        return result
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
            .navigationTitle("GifScroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                service.likeManager = likeManager
                service.memeFeed()
            }
        }
    }
}
