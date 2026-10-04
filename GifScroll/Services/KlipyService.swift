import Foundation

// MARK: - Klipy JSON

struct KlipyResponse: Decodable {
    let data: KlipyPage
}

struct KlipyPage: Decodable {
    let data: [KlipyItem]
    let hasNext: Bool

    enum CodingKeys: String, CodingKey {
        case data
        case hasNext = "has_next"
    }
}

struct KlipyItem: Decodable {
    let id: Int
    let title: String?
    let file: KlipyFile
}

struct KlipyFile: Decodable {
    let md: KlipyVariant
}

struct KlipyVariant: Decodable {
    let gif: KlipyMedia
}

struct KlipyMedia: Decodable {
    let url: String
}

// MARK: - FeedItem conversion

extension FeedItem {
    /// Build a feed item from a Klipy GIF, or nil if it has no usable media URL.
    init?(klipy item: KlipyItem) {
        guard let url = URL(string: item.file.md.gif.url) else { return nil }
        let title = (item.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(id: String(item.id), title: title, url: url, kind: .gif)
    }
}

// MARK: - Service

/// The main feed: trending GIFs from Klipy (https://api.klipy.com).
@MainActor
final class KlipyService: ObservableObject {
    @Published var items: [FeedItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Set this to rank fetched memes by the user's liked keywords.
    var likeManager: LikeManager?

    private var currentTask: Task<Void, Never>?

    /// The main feed: Klipy's trending GIFs.
    func memeFeed() {
        currentTask?.cancel()
        isLoading = true
        errorMessage = nil

        currentTask = Task {
            do {
                var components = URLComponents(
                    string: "https://api.klipy.com/api/v1/\(Secrets.klipyAPIKey)/gifs/trending"
                )!
                components.queryItems = [
                    URLQueryItem(name: "per_page", value: "50"),
                    URLQueryItem(name: "page", value: "1"),
                ]

                let (data, _) = try await URLSession.shared.data(from: components.url!)
                let decoded = try JSONDecoder().decode(KlipyResponse.self, from: data)
                var fetched = decoded.data.data.compactMap { FeedItem(klipy: $0) }
                if let ranker = likeManager {
                    // Algorithm: most-liked-keyword-matching memes first.
                    fetched.sort { ranker.score(id: $0.id, title: $0.title) > ranker.score(id: $1.id, title: $1.title) }
                }
                items = fetched
            } catch is CancellationError {
                // Superseded by a newer request; ignore.
            } catch {
                errorMessage = "Couldn't load memes. Check your connection."
            }
            isLoading = false
        }
    }
}
