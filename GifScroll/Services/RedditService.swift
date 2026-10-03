import Foundation

/// Meme feed powered by the Arctic Shift Reddit mirror.
/// Free, no API key, no login — Reddit's own endpoints now bot-block
/// unauthenticated requests, so we go through the mirror instead.
@MainActor
final class RedditService: ObservableObject {
    @Published private(set) var items: [FeedItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    var likeManager: LikeManager?

    private let subreddits = ["memes", "dankmemes", "funny"]

    func memeFeed() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }

            do {
                let sub = subreddits.randomElement() ?? "memes"
                var components = URLComponents(string: "https://arctic-shift.photon-reddit.com/api/posts/search")!
                components.queryItems = [
                    URLQueryItem(name: "subreddit", value: sub),
                    URLQueryItem(name: "sort", value: "desc"),
                    URLQueryItem(name: "limit", value: "50")
                ]

                let request = URLRequest(url: components.url!)

                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw RedditServiceError.invalidResponse
                }

                let result = try JSONDecoder().decode(ArcticShiftResponse.self, from: data)
                let fetchedItems = (result.data ?? []).compactMap { FeedItem(post: $0) }

                // Drop dead media in the background before anything is shown.
                let liveItems = await Self.filterDeadMedia(fetchedItems)

                if let likeManager {
                    items = liveItems.sorted {
                        likeManager.score(id: $0.id, title: $0.title) > likeManager.score(id: $1.id, title: $1.title)
                    }
                } else {
                    items = liveItems
                }

                if items.isEmpty {
                    throw RedditServiceError.invalidResponse
                }
            } catch {
                errorMessage = "Couldn't load memes. Check your connection and try again."
            }
        }
    }

    // MARK: - Dead media filtering

    /// HEAD-checks every media URL concurrently and drops the dead ones.
    /// Fail-open: timeouts, network errors, and servers that don't support
    /// HEAD (405/501) keep the item — only definitive 4xx/5xx drops it.
    private static func filterDeadMedia(_ items: [FeedItem]) async -> [FeedItem] {
        let kept: [FeedItem] = await withTaskGroup(of: FeedItem?.self) { group in
            for item in items {
                group.addTask { await Self.urlIsAlive(item.url) ? item : nil }
            }
            var alive: [FeedItem] = []
            for await item in group {
                if let item { alive.append(item) }
            }
            return alive
        }
        // Task groups finish out of order — restore the original order.
        let order = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.id, $0) })
        return kept.sorted { (order[$0.id] ?? 0) < (order[$1.id] ?? 0) }
    }

    private static func urlIsAlive(_ url: URL) async -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 6
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return true }
            let code = http.statusCode
            if code == 405 || code == 501 { return true } // HEAD not supported — keep
            return (200..<400).contains(code)
        } catch {
            return true // fail open on timeouts / network errors
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
        // Skip NSFW, stickied mod posts, deleted/removed posts, text posts, and gallery albums.
        guard !(post.over18 ?? false), !(post.stickied ?? false), !(post.isGallery ?? false) else { return nil }
        let title = post.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, title != "[deleted]", title != "[removed]", post.postHint != "self" else { return nil }

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
        self.title = title
        self.url = url
        self.kind = kind
    }
}

private struct ArcticShiftResponse: Decodable {
    let data: [RedditPost]?
}

private struct RedditPost: Decodable {
    let id: String
    let title: String
    let url: String?
    let urlOverriddenByDestination: String?
    let postHint: String?
    let isVideo: Bool
    let isGallery: Bool?
    let over18: Bool?
    let stickied: Bool?
    let media: RedditMedia?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case urlOverriddenByDestination = "url_overridden_by_dest"
        case postHint = "post_hint"
        case isVideo = "is_video"
        case isGallery = "is_gallery"
        case over18 = "over_18"
        case stickied
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
