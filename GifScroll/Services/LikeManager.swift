import Foundation

/// A meme the user laugh-reacted to, with enough media info to display it.
struct LikedItem: Codable, Identifiable {
    let id: String
    let title: String
    let url: String?
    let kind: String? // "image" | "gif" | "video"
}

/// Like store + content-based ranking. Syncs to Supabase when signed in.
/// Learns keywords from liked meme titles, then ranks similar content.
/// Likes persist across launches.
@MainActor
final class LikeManager: ObservableObject {
    @Published private(set) var likedItems: [LikedItem] = []

    /// IDs only, for quick membership checks (migrated from the old store).
    var likedIDs: Set<String> { Set(likedItems.map(\.id)) }

    private var keywordScores: [String: Double] = [:]

    private let likedKey = "gifscroll.likedItems"
    private let legacyLikedKey = "gifscroll.likedIDs"
    private let keywordsKey = "gifscroll.keywordScores"
    private let supabase = SupabaseManager.shared

    init() {
        if let data = UserDefaults.standard.data(forKey: likedKey),
           let decoded = try? JSONDecoder().decode([LikedItem].self, from: data) {
            likedItems = decoded
        } else if let legacy = UserDefaults.standard.array(forKey: legacyLikedKey) as? [String] {
            // Migrate: old likes had no media, so they count for ranking
            // but can't be shown in the Favorites grid until re-liked.
            likedItems = legacy.map { LikedItem(id: $0, title: "", url: nil, kind: nil) }
            save()
        }
        if let saved = UserDefaults.standard.dictionary(forKey: keywordsKey) as? [String: Double] {
            keywordScores = saved
        }
    }

    func isLiked(id: String) -> Bool {
        likedIDs.contains(id)
    }

    func toggleLike(id: String, title: String) {
        toggleLike(id: id, title: title, url: nil, kind: nil, userId: nil, signedIn: false)
    }

    func toggleLike(id: String, title: String, url: URL?, kind: FeedItem.Kind?, userId: String? = nil, signedIn: Bool = false) {
        let wasLiked = likedItems.contains(where: { $0.id == id })
        if let index = likedItems.firstIndex(where: { $0.id == id }) {
            likedItems.remove(at: index)
            adjustKeywords(from: title, by: -1)
        } else {
            let kindString: String?
            switch kind {
            case .image: kindString = "image"
            case .gif: kindString = "gif"
            case .video: kindString = "video"
            case .none: kindString = nil
            }
            likedItems.append(LikedItem(id: id, title: title, url: url?.absoluteString, kind: kindString))
            adjustKeywords(from: title, by: 1)
        }
        save()
        // Sync to Supabase in the background (best-effort).
        if signedIn, let uid = userId {
            Task {
                do {
                    if wasLiked {
                        try await supabase.deleteLike(userId: uid, itemId: id)
                    } else if let item = likedItems.first(where: { $0.id == id }) {
                        try await supabase.insertLike(userId: uid, item: item)
                    }
                } catch {
                    // Local state is authoritative; remote sync is best-effort.
                }
            }
        }
    }

    /// Loads likes from Supabase when signed in, merging with local likes.
    func refresh(userId: String?, signedIn: Bool) {
        guard signedIn, let uid = userId else { return }
        Task {
            do {
                let remote = try await supabase.fetchLikes(userId: uid)
                var seen = Set(likedItems.map(\.id))
                for item in remote where !seen.contains(item.id) {
                    seen.insert(item.id)
                    likedItems.append(item)
                    adjustKeywords(from: item.title, by: 1)
                }
                save()
            } catch {
                // Keep local state on failure.
            }
        }
    }

    /// How strongly an item matches your liked keywords. Higher = show first.
    func score(id: String, title: String) -> Double {
        keywords(from: title).reduce(0) { $0 + (keywordScores[$1] ?? 0) }
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
            "with", "meme", "via", "from", "this", "that", "you"
        ]
        return title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !stopwords.contains($0) }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(likedItems) {
            UserDefaults.standard.set(data, forKey: likedKey)
        }
        UserDefaults.standard.set(keywordScores, forKey: keywordsKey)
    }
}
