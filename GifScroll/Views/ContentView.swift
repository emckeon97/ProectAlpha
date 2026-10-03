import SwiftUI

struct ContentView: View {
    @StateObject private var service = RedditService()
    @EnvironmentObject var likeManager: LikeManager

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
                                ForEach(service.items) { item in
                                    FeedItemView(item: item, likeManager: likeManager)
                                        .containerRelativeFrame(.vertical)
                                        .id(item.id)
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
