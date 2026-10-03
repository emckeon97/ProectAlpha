import Foundation

struct Comment: Identifiable {
    let id: String
    let postID: String
    let displayName: String
    let body: String
    let createdAt: Date

    /// Builds a Comment from a Supabase PostgREST row dictionary.
    static func fromSupabase(_ dict: [String: Any]) -> Comment? {
        guard let id = dict["id"] as? String,
              let postID = dict["post_id"] as? String,
              let body = dict["body"] as? String
        else { return nil }

        var createdAt = Date()
        if let raw = dict["created_at"] as? String {
            createdAt = ISO8601DateFormatter().date(from: raw) ?? Date()
        }
        return Comment(
            id: id,
            postID: postID,
            displayName: dict["display_name"] as? String ?? "anon",
            body: body,
            createdAt: createdAt
        )
    }
}
