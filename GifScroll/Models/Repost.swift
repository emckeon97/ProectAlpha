import Foundation

/// A feed meme the user reposted to their personal page ("Shared" tab).
struct Repost: Identifiable, Codable {
    let id: String
    let itemId: String
    let title: String
    let url: URL?
    let kind: String   // "image", "gif", or "video"
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case title
        case url
        case kind
        case createdAt = "created_at"
    }

    init(
        id: String = UUID().uuidString,
        itemId: String,
        title: String,
        url: URL?,
        kind: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.title = title
        self.url = url
        self.kind = kind
        self.createdAt = createdAt
    }

    /// Build a Repost from a feed item.
    init(item: FeedItem) {
        let kind: String
        switch item.kind {
        case .image: kind = "image"
        case .gif: kind = "gif"
        case .video: kind = "video"
        }
        self.init(itemId: item.id, title: item.title, url: item.url, kind: kind)
    }
}

extension Repost {
    /// Builds a Repost from a Supabase PostgREST row dictionary.
    static func fromSupabase(_ dict: [String: Any]) -> Repost? {
        guard let id = dict["id"] as? String,
              let itemId = dict["item_id"] as? String
        else { return nil }

        let title = dict["title"] as? String ?? ""
        let kind = dict["kind"] as? String ?? "image"
        var url: URL?
        if let raw = dict["url"] as? String, !raw.isEmpty {
            url = URL(string: raw)
        }
        var createdAt = Date()
        if let raw = dict["created_at"] as? String {
            createdAt = ISO8601DateFormatter().date(from: raw) ?? Date()
        }
        return Repost(id: id, itemId: itemId, title: title, url: url, kind: kind, createdAt: createdAt)
    }
}
