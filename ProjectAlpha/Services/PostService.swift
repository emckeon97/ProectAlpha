import Foundation
import UIKit

/// Local post store. Saves images to the documents directory and post
/// metadata to UserDefaults. Swap this for a Firebase/Supabase-backed
/// implementation later without touching the views.
@MainActor
final class LocalPostService: ObservableObject {
    @Published private(set) var posts: [Post] = []

    private let postsKey = "projectalpha.posts"

    init() {
        load()
    }

    func createPost(imageData: Data, caption: String) throws {
        let id = UUID().uuidString
        let fileName = "\(id).jpg"
        try imageData.write(to: documentsDirectory.appendingPathComponent(fileName))

        let post = Post(
            id: id,
            imageFileName: fileName,
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date(),
            likeCount: 0
        )
        posts.insert(post, at: 0)
        save()
    }

    func image(for post: Post) -> UIImage? {
        UIImage(contentsOfFile: documentsDirectory.appendingPathComponent(post.imageFileName).path)
    }

    // MARK: - Private

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: postsKey),
              let decoded = try? JSONDecoder().decode([Post].self, from: data)
        else { return }
        posts = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(data, forKey: postsKey)
        }
    }
}
