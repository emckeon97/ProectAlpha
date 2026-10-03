import Foundation

/// Thin REST client for Supabase — no SDK dependency.
/// Uses the project's publishable key, which is designed to ship in clients.
final class SupabaseManager {
    private let projectURL = URL(string: "https://btfbjmdtnjntqkybpqrk.supabase.co")!
    private let apiKey = "sb_publishable_NM4BBwTL1kRxlAjnNkGW9g_U0q-VDCF"

    private var baseHeaders: [String: String] {
        [
            "apikey": apiKey,
            "Authorization": "Bearer \(apiKey)",
        ]
    }

    // MARK: - Posts

    func fetchPosts() async throws -> [Post] {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("rest/v1/posts"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "100"),
        ]
        var req = URLRequest(url: comps.url!)
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badStatus
        }
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return array.compactMap(Post.fromSupabase)
    }

    func insertPost(imageURL: String, caption: String) async throws -> Post {
        var req = URLRequest(url: projectURL.appendingPathComponent("rest/v1/posts"))
        req.httpMethod = "POST"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONSerialization.data(
            withJSONObject: ["image_url": imageURL, "caption": caption]
        )

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 201 else {
            throw SupabaseError.badStatus
        }
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        guard let post = array.first.flatMap(Post.fromSupabase) else {
            throw SupabaseError.badPayload
        }
        return post
    }

    // MARK: - Storage

    /// Uploads JPEG bytes to the public `post-images` bucket. Returns the public URL.
    func uploadImage(_ data: Data) async throws -> String {
        let name = "\(UUID().uuidString).jpg"
        var req = URLRequest(
            url: projectURL.appendingPathComponent("storage/v1/object/post-images/\(name)")
        )
        req.httpMethod = "POST"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        req.httpBody = data

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badStatus
        }
        return projectURL
            .appendingPathComponent("storage/v1/object/public/post-images/\(name)")
            .absoluteString
    }
}

enum SupabaseError: Error {
    case badStatus
    case badPayload
}
