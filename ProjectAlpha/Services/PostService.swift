import Foundation
import UIKit

/// Post store backed by Supabase, with a local fallback when the backend
/// isn't reachable (or the table hasn't been created yet).
@MainActor
final class PostService: ObservableObject {
    @Published private(set) var posts: [Post] = []

    private let supabase = SupabaseManager()
    private let imageCache = NSCache<NSString, UIImage>()
    private let postsKey = "projectalpha.posts"
    private var remoteAvailable = true

    init() {
        loadCached()
    }

    // MARK: - Feed

    func refresh() async {
        do {
            posts = try await supabase.fetchPosts()
            remoteAvailable = true
            saveCached()
        } catch {
            remoteAvailable = false
        }
    }

    // MARK: - Posting

    func createPost(imageData: Data, caption: String) async throws {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)

        if remoteAvailable {
            do {
                let url = try await supabase.uploadImage(imageData)
                let post = try await supabase.insertPost(imageURL: url, caption: trimmed)
                posts.insert(post, at: 0)
                saveCached()
                return
            } catch {
                remoteAvailable = false
            }
        }

        // Local fallback: store on-device so the post still works offline.
        let id = UUID().uuidString
        let fileName = "\(id).jpg"
        try imageData.write(to: documentsDirectory.appendingPathComponent(fileName))
        let post = Post(
            id: id,
            imageFileName: fileName,
            imageURL: nil,
            caption: trimmed,
            createdAt: Date(),
            likeCount: 0
        )
        posts.insert(post, at: 0)
        saveCached()
    }

    // MARK: - Images

    func loadImage(for post: Post) async -> UIImage? {
        if let name = post.imageFileName {
            return UIImage(contentsOfFile: documentsDirectory.appendingPathComponent(name).path)
        }
        guard let urlString = post.imageURL, let url = URL(string: urlString) else {
            return nil
        }
        if let cached = imageCache.object(forKey: urlString as NSString) {
            return cached
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data)
        else { return nil }
        imageCache.setObject(image, forKey: urlString as NSString)
        return image
    }

    // MARK: - Private

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func loadCached() {
        guard let data = UserDefaults.standard.data(forKey: postsKey),
              let decoded = try? JSONDecoder().decode([Post].self, from: data)
        else { return }
        posts = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func saveCached() {
        if let data = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(data, forKey: postsKey)
        }
    }
}
