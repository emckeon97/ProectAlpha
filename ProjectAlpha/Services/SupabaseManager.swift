import Foundation

/// Thin REST client for Supabase — no SDK dependency.
/// Uses the project's publishable key, which is designed to ship in clients.
@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    private let projectURL = URL(string: "https://btfbjmdtnjntqkybpqrk.supabase.co")!
    private let apiKey = "sb_publishable_NM4BBwTL1kRxlAjnNkGW9g_U0q-VDCF"

    /// Set after sign-in; used as the Bearer token instead of the anon key.
    var authToken: String?

    private init() {}

    private var bearer: String { authToken ?? apiKey }

    private var baseHeaders: [String: String] {
        [
            "apikey": apiKey,
            "Authorization": "Bearer \(bearer)",
        ]
    }

    // MARK: - Auth

    struct AuthResult {
        let accessToken: String?
        let userID: String?
        let email: String?
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AuthResult {
        var req = URLRequest(url: projectURL.appendingPathComponent("auth/v1/signup"))
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "data": ["display_name": displayName],
        ])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badStatus
        }
        return try parseAuth(data)
    }

    func signIn(email: String, password: String) async throws -> AuthResult {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("auth/v1/token"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(
            withJSONObject: ["email": email, "password": password]
        )

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badStatus
        }
        return try parseAuth(data)
    }

    private func parseAuth(_ data: Data) throws -> AuthResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let user = json["user"] as? [String: Any]
        return AuthResult(
            accessToken: json["access_token"] as? String,
            userID: user?["id"] as? String,
            email: user?["email"] as? String
        )
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

    // MARK: - Comments

    func fetchComments(postID: String) async throws -> [Comment] {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("rest/v1/comments"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "post_id", value: "eq.\(postID)"),
            URLQueryItem(name: "order", value: "created_at.asc"),
        ]
        var req = URLRequest(url: comps.url!)
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badStatus
        }
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return array.compactMap(Comment.fromSupabase)
    }

    func insertComment(postID: String, body: String, displayName: String) async throws -> Comment {
        var req = URLRequest(url: projectURL.appendingPathComponent("rest/v1/comments"))
        req.httpMethod = "POST"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "post_id": postID,
            "body": body,
            "display_name": displayName,
        ])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 201 else {
            throw SupabaseError.badStatus
        }
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        guard let comment = array.first.flatMap(Comment.fromSupabase) else {
            throw SupabaseError.badPayload
        }
        return comment
    }
}

enum SupabaseError: Error {
    case badStatus
    case badPayload
}
