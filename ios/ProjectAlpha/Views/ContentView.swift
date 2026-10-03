import SwiftUI

struct ContentView: View {
    @StateObject private var service = GiphyService()
    @State private var query = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading && service.gifs.isEmpty {
                    ProgressView("Loading GIFs…")
                } else if let error = service.errorMessage, service.gifs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text(error)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(service.gifs) { gif in
                                NavigationLink(destination: GifDetailView(gif: gif)) {
                                    AnimatedGifView(url: gif.previewURL)
                                        .frame(height: 150)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .navigationTitle("Project Alpha")
            .searchable(text: $query, prompt: "Search GIFs")
            .onSubmit(of: .search) { service.search(query) }
            .onAppear { service.trending() }
        }
    }
}

#Preview {
    ContentView()
}
