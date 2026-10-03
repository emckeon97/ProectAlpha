import Foundation

@MainActor
final class RedditService: ObservableObject {
    @Published private(set) var items: [FeedItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    var likeManager: LikeManager?

    func memeFeed() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }

            do {
                var components = URLComponents(string: "https://www.reddit.com/r/memes/hot.json")!
                components.queryItems = [
                    URLQueryItem(name: "limit", value: "50"),
                    URLQueryItem(name: "raw_json", value: "1")
                ]

                var request = URLRequest(url: components.url!)
                request.setValue("GifScroll/1.0", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw RedditServiceError.invalidResponse
                }

                let listing = try JSONDecoder().decode(RedditListing.self, from: data)
                let fetchedItems = listing.data.children.compactMap { FeedItem(post: $0.data) }

                if let likeManager {
                    items = fetchedItems.sorted {
                        likeManager.score(id: $0.id, title: $0.title) > likeManager.score(id: $1.id, title: $1.title)
                    }
                } else {
                    items = fetchedItems
                }
            } catch {
                errorMessage = "Couldn't load memes. Check your connection and try again."
            }
        }
    }
}

struct FeedItem: Identifiable {
    enum Kind {
        case image
        case gif
        case video
    }

    let id: String
    let title: String
    let url: URL
    let kind: Kind

    fileprivate init?(post: RedditPost) {
        let mediaURL: String?
        let kind: Kind

        if post.isVideo, let videoURL = post.media?.redditVideo?.fallbackURL {
            mediaURL = videoURL
            kind = .video
        } else {
            mediaURL = post.urlOverriddenByDestination ?? post.url
            kind = post.postHint == "image" ? .image : .gif
        }

        guard let mediaURL, let url = URL(string: mediaURL) else {
            return nil
        }

        self.id = post.id
        self.title = post.title
        self.url = url
        self.kind = kind
    }
}

private struct RedditListing: Decodable {
    let data: RedditListingData
}

private struct RedditListingData: Decodable {
    let children: [RedditChild]
}

private struct RedditChild: Decodable {
    let data: RedditPost
}

private struct RedditPost: Decodable {
    let id: String
    let title: String
    let url: String?
    let urlOverriddenByDestination: String?
    let postHint: String?
    let isVideo: Bool
    let media: RedditMedia?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case urlOverriddenByDestination = "url_overridden_by_dest"
        case postHint = "post_hint"
        case isVideo = "is_video"
        case media
    }
}

private struct RedditMedia: Decodable {
    let redditVideo: RedditVideo?

    enum CodingKeys: String, CodingKey {
        case redditVideo = "reddit_video"
    }
}

private struct RedditVideo: Decodable {
    let fallbackURL: String?

    enum CodingKeys: String, CodingKey {
        case fallbackURL = "fallback_url"
    }
}

private enum RedditServiceError: Error {
    case invalidResponse
}
