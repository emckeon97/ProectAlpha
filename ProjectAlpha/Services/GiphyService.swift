import Foundation

@MainActor
final class GiphyService: ObservableObject {
    @Published var gifs: [Gif] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Get a free key at https://developers.giphy.com/dashboard/
    // and paste it here.
    private let apiKey = "Rkyhk3U1aH2DlElFrmuYauK4EU7OHLEJ"

    /// Set this to rank fetched GIFs by the user's liked keywords.
    var likeManager: LikeManager?

    private var currentTask: Task<Void, Never>?

    func trending() {
        fetch(path: "trending", extraItems: [])
    }

    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { trending(); return }
        fetch(path: "search", extraItems: [URLQueryItem(name: "q", value: trimmed)])
    }

    private func fetch(path: String, extraItems: [URLQueryItem]) {
        currentTask?.cancel()

        guard apiKey != "YOUR_GIPHY_API_KEY" else {
            errorMessage = "Add your free Giphy API key in GiphyService.swift to load GIFs."
            return
        }

        isLoading = true
        errorMessage = nil

        currentTask = Task {
            do {
                var components = URLComponents(string: "https://api.giphy.com/v1/gifs/\(path)")!
                components.queryItems = [
                    URLQueryItem(name: "api_key", value: apiKey),
                    URLQueryItem(name: "limit", value: "25"),
                    URLQueryItem(name: "rating", value: "pg-13")
                ] + extraItems

                let (data, _) = try await URLSession.shared.data(from: components.url!)
                let decoded = try JSONDecoder().decode(GiphyResponse.self, from: data)
                let fetched = decoded.data
                if let ranker = likeManager {
                    // Algorithm: most-liked-keyword-matching GIFs first.
                    gifs = fetched.sorted { ranker.score($0) > ranker.score($1) }
                } else {
                    gifs = fetched
                }
            } catch is CancellationError {
                // Superseded by a newer request; ignore.
            } catch {
                errorMessage = "Couldn't load GIFs. Check your connection and API key."
            }
            isLoading = false
        }
    }
}
