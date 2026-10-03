import SwiftUI

struct ContentView: View {
    @StateObject private var service = GiphyService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if service.isLoading && service.gifs.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else if let error = service.errorMessage, service.gifs.isEmpty {
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
                                ForEach(service.gifs) { gif in
                                    GifPageView(gif: gif)
                                        .containerRelativeFrame(.vertical)
                                        .id(gif.id)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging)
                        .ignoresSafeArea()
                        .onChange(of: service.gifs.map(\.id)) { _, _ in
                            if let first = service.gifs.first {
                                withAnimation {
                                    proxy.scrollTo(first.id, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Project Alpha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { service.trending() }
        }
    }
}

#Preview {
    ContentView()
}
