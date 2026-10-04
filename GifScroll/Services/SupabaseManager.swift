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
        let refreshToken: String?
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
            refreshToken: json["refresh_token"] as? String,
            userID: user?["id"] as? String,
            email: user?["email"] as? String
        )
    }

    /// Exchange a refresh token for a new access token.
    func refreshSession(refreshToken: String) async throws -> AuthResult {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("auth/v1/token"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(
            withJSONObject: ["refresh_token": refreshToken]
        )

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badStatus
        }
        return try parseAuth(data)
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

    func insertPost(imageURL: String, caption: String, userId: String? = nil) async throws -> Post {
        var req = URLRequest(url: projectURL.appendingPathComponent("rest/v1/posts"))
        req.httpMethod = "POST"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        var payload: [String: Any] = ["image_url": imageURL, "caption": caption]
        if let userId { payload["user_id"] = userId }
        req.httpBody = try JSONSerialization.data(
            withJSONObject: payload
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

    // MARK: - Reposts ("Shared" tab on the personal page)

    func fetchReposts(userId: String) async throws -> [Repost] {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("rest/v1/reposts"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "200"),
        ]
        var req = URLRequest(url: comps.url!)
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badStatus
        }
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return array.compactMap(Repost.fromSupabase)
    }

    func insertRepost(_ repost: Repost, userId: String) async throws -> Repost {
        var req = URLRequest(url: projectURL.appendingPathComponent("rest/v1/reposts"))
        req.httpMethod = "POST"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        let payload: [String: Any] = [
            "id": repost.id,
            "user_id": userId,
            "item_id": repost.itemId,
            "title": repost.title,
            "url": repost.url?.absoluteString ?? "",
            "kind": repost.kind,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 201 else {
            throw SupabaseError.badStatus
        }
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        guard let saved = array.first.flatMap(Repost.fromSupabase) else {
            throw SupabaseError.badPayload
        }
        return saved
    }

    func deleteRepost(id: String) async throws {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("rest/v1/reposts"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [URLQueryItem(name: "id", value: "eq.\(id)")]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "DELETE"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 204 else {
            throw SupabaseError.badStatus
        }
    }

    // MARK: - Likes ("Favorites" tab on the personal page)

    func fetchLikes(userId: String) async throws -> [LikedItem] {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("rest/v1/likes"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
            URLQueryItem(name: "select", value: "item_id,title,url,kind"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "500"),
        ]
        var req = URLRequest(url: comps.url!)
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badStatus
        }
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return array.compactMap { d in
            guard let id = d["item_id"] as? String else { return nil }
            return LikedItem(
                id: id,
                title: d["title"] as? String ?? "",
                url: d["url"] as? String,
                kind: d["kind"] as? String
            )
        }
    }

    func insertLike(userId: String, item: LikedItem) async throws {
        var req = URLRequest(url: projectURL.appendingPathComponent("rest/v1/likes"))
        req.httpMethod = "POST"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        var payload: [String: Any] = [
            "user_id": userId,
            "item_id": item.id,
            "title": item.title,
        ]
        if let url = item.url { payload["url"] = url }
        if let kind = item.kind { payload["kind"] = kind }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 201 || code == 200 else {
            throw SupabaseError.badStatus
        }
    }

    func deleteLike(userId: String, itemId: String) async throws {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("rest/v1/likes"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "item_id", value: "eq.\(itemId)"),
        ]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "DELETE"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 204 else {
            throw SupabaseError.badStatus
        }
    }

    func deletePost(id: String) async throws {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("rest/v1/posts"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [URLQueryItem(name: "id", value: "eq.\(id)")]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "DELETE"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 204 else {
            throw SupabaseError.badStatus
        }
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

    func fetchComments(postID: String? = nil, gifID: String? = nil) async throws -> [Comment] {
        var comps = URLComponents(
            url: projectURL.appendingPathComponent("rest/v1/comments"),
            resolvingAgainstBaseURL: false
        )!
        var items = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.asc"),
        ]
        if let postID {
            items.append(URLQueryItem(name: "post_id", value: "eq.\(postID)"))
        } else if let gifID {
            items.append(URLQueryItem(name: "gif_id", value: "eq.\(gifID)"))
        }
        comps.queryItems = items
        var req = URLRequest(url: comps.url!)
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badStatus
        }
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return array.compactMap(Comment.fromSupabase)
    }

    func insertComment(
        postID: String? = nil,
        gifID: String? = nil,
        body: String,
        displayName: String
    ) async throws -> Comment {
        var req = URLRequest(url: projectURL.appendingPathComponent("rest/v1/comments"))
        req.httpMethod = "POST"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        var payload: [String: Any] = [
            "body": body,
            "display_name": displayName,
        ]
        if let postID { payload["post_id"] = postID }
        if let gifID { payload["gif_id"] = gifID }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

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

    func insertReport(
        postID: String? = nil,
        gifID: String? = nil,
        commentID: String? = nil,
        reason: String,
        details: String,
        reporterName: String
    ) async throws {
        var req = URLRequest(url: projectURL.appendingPathComponent("rest/v1/reports"))
        req.httpMethod = "POST"
        baseHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload: [String: Any] = [
            "reason": reason,
            "details": details,
            "reporter_name": reporterName,
        ]
        if let postID { payload["post_id"] = postID }
        if let gifID { payload["gif_id"] = gifID }
        if let commentID { payload["comment_id"] = commentID }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 201 else {
            throw SupabaseError.badStatus
        }
    }
}

enum SupabaseError: Error {
    case badStatus
    case badPayload
}
