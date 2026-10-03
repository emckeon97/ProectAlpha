import Foundation

/// One item in the meme feed: a captioned image, GIF, or video from Reddit.
struct FeedItem: Identifiable {
    enum Kind { case image, gif, video }

    let id: String
    let title: String
    let kind: Kind
    let url: URL
}

extension String {
    /// Reddit escapes URLs in its JSON (e.g. `&amp;`).
    func decodingHTMLEntities() -> String {
        replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
    }
}

extension FeedItem {
    /// Build a feed item from a Reddit post, or nil if it isn't a usable meme.
    init?(reddit post: RedditPost) {
        guard post.over18 != true, post.stickied != true else { return nil }
        let title = post.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, title != "[deleted]", title != "[removed]" else { return nil }

        // Video posts: use the direct MP4 fallback, not the v.redd.it page URL.
        if post.isVideo == true,
           let raw = post.media?.redditVideo?.fallbackUrl,
           let url = URL(string: raw.decodingHTMLEntities()) {
            self.init(id: post.id, title: title, kind: .video, url: url)
            return
        }

        guard let rawURL = post.url, let url = URL(string: rawURL) else { return nil }
        switch url.pathExtension.lowercased() {
        case "gif":
            self.init(id: post.id, title: title, kind: .gif, url: url)
        case "jpg", "jpeg", "png":
            self.init(id: post.id, title: title, kind: .image, url: url)
        default:
            return nil
        }
    }
}
