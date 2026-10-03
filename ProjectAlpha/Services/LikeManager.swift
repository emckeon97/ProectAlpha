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

    func isLiked(id: String) -> Bool {
        likedIDs.contains(id)
    }

    func isLiked(_ gif: Gif) -> Bool {
        isLiked(id: gif.id)
    }

    func toggleLike(id: String, title: String) {
        if likedIDs.contains(id) {
            likedIDs.remove(id)
            adjustKeywords(from: title, by: -1)
        } else {
            likedIDs.insert(id)
            adjustKeywords(from: title, by: 1)
        }
        save()
    }

    func toggleLike(_ gif: Gif) {
        toggleLike(id: gif.id, title: gif.title)
    }

    /// How strongly an item matches your liked keywords. Higher = show first.
    func score(id: String, title: String) -> Double {
        keywords(from: title).reduce(0) { $0 + (keywordScores[$1] ?? 0) }
    }

    func score(_ gif: Gif) -> Double {
        score(id: gif.id, title: gif.title)
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
