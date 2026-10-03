import Foundation

/// Local-only like store + content-based ranking.
/// Learns keywords from the titles of GIFs you like, then scores new
/// GIFs by how closely their titles match. Likes persist across launches.
@MainActor
final class LikeManager: ObservableObject {
    @Published private(set) var likedIDs: Set<String> = []

    private var keywordScores: [String: Double] = [:]

    private let likedKey = "projectalpha.likedIDs"
    private let keywordsKey = "projectalpha.keywordScores"

    init() {
        if let saved = UserDefaults.standard.array(forKey: likedKey) as? [String] {
            likedIDs = Set(saved)
        }
        if let saved = UserDefaults.standard.dictionary(forKey: keywordsKey) as? [String: Double] {
            keywordScores = saved
        }
    }

    func isLiked(_ gif: Gif) -> Bool {
        likedIDs.contains(gif.id)
    }

    func toggleLike(_ gif: Gif) {
        if likedIDs.contains(gif.id) {
            likedIDs.remove(gif.id)
            adjustKeywords(from: gif.title, by: -1)
        } else {
            likedIDs.insert(gif.id)
            adjustKeywords(from: gif.title, by: 1)
        }
        save()
    }

    /// How strongly a GIF matches your liked keywords. Higher = show first.
    func score(_ gif: Gif) -> Double {
        keywords(from: gif.title).reduce(0) { $0 + (keywordScores[$1] ?? 0) }
    }

    // MARK: - Private

    private func adjustKeywords(from title: String, by amount: Double) {
        for word in keywords(from: title) {
            keywordScores[word, default: 0] += amount
        }
        // Prune dead keywords so the table stays small.
        keywordScores = keywordScores.filter { $0.value != 0 }
    }

    private func keywords(from title: String) -> [String] {
        let stopwords: Set<String> = [
            "the", "a", "an", "and", "or", "of", "to", "in", "on", "for",
            "with", "gif", "giphy", "via", "from", "this", "that", "you"
        ]
        return title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !stopwords.contains($0) }
    }

    private func save() {
        UserDefaults.standard.set(Array(likedIDs), forKey: likedKey)
        UserDefaults.standard.set(keywordScores, forKey: keywordsKey)
    }
}
