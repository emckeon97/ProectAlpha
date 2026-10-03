import Foundation

// MARK: - Reddit JSON

struct RedditListing: Decodable {
    let data: RedditListingData
}

struct RedditListingData: Decodable {
    let children: [RedditChild]
}

struct RedditChild: Decodable {
    let data: RedditPost
}

struct RedditPost: Decodable {
    let id: String
    let title: String
    let url: String?
    let postHint: String?
    let isVideo: Bool?
    let over18: Bool?
    let stickied: Bool?
    let media: RedditMedia?

    enum CodingKeys: String, CodingKey {
        case id, title, url, media, stickied
        case postHint = "post_hint"
        case isVideo = "is_video"
        case over18 = "over_18"
    }
}

struct RedditMedia: Decodable {
    let redditVideo: RedditVideo?

    enum CodingKeys: String, CodingKey {
        case redditVideo = "reddit_video"
    }
}

struct RedditVideo: Decodable {
    let fallbackUrl: String?

    enum CodingKeys: String, CodingKey {
        case fallbackUrl = "fallback_url"
    }
}

// MARK: - Service

/// The main feed: funny memes, GIFs, and videos from Reddit's meme
/// communities. Free, no API key — Reddit's public JSON endpoints.
@MainActor
final class RedditService: ObservableObject {
    @Published var items: [FeedItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Set this to rank fetched memes by the user's liked keywords.
    var likeManager: LikeManager?

    private var currentTask: Task<Void, Never>?
    private let subreddits = ["memes", "dankmemes", "funny"]

    /// The main feed: meme communities, subreddit rotated for variety.
    func memeFeed() {
        currentTask?.cancel()
        isLoading = true
        errorMessage = nil

        currentTask = Task {
            do {
                let sub = subreddits.randomElement() ?? "memes"
                var components = URLComponents(string: "https://www.reddit.com/r/\(sub)/hot.json")!
                components.queryItems = [URLQueryItem(name: "limit", value: "50")]

                var request = URLRequest(url: components.url!)
                // Reddit requires a User-Agent on unauthenticated requests.
                request.setValue("GifScroll/1.0 (by /u/gifscroll)", forHTTPHeaderField: "User-Agent")

                let (data, _) = try await URLSession.shared.data(for: request)
                let decoded = try JSONDecoder().decode(RedditListing.self, from: data)
                var fetched = decoded.data.children.compactMap { FeedItem(reddit: $0.data) }
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
