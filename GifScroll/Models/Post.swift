import Foundation

struct Post: Identifiable, Codable {
    let id: String
    let imageFileName: String?  // local-only posts
    let imageURL: String?       // Supabase-hosted posts
    let caption: String
    let createdAt: Date
    var likeCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case imageFileName
        case imageURL = "image_url"
        case caption
        case createdAt = "created_at"
        case likeCount = "like_count"
    }
}

extension Post {
    /// Builds a Post from a Supabase PostgREST row dictionary.
    static func fromSupabase(_ dict: [String: Any]) -> Post? {
        guard let id = dict["id"] as? String,
              let imageURL = dict["image_url"] as? String
        else { return nil }

        let caption = dict["caption"] as? String ?? ""
        let likeCount = dict["like_count"] as? Int ?? 0
        var createdAt = Date()
        if let raw = dict["created_at"] as? String {
            createdAt = ISO8601DateFormatter().date(from: raw) ?? Date()
        }
        return Post(
            id: id,
            imageFileName: nil,
            imageURL: imageURL,
            caption: caption,
            createdAt: createdAt,
            likeCount: likeCount
        )
    }
}
