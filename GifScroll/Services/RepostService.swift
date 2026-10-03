import Foundation

/// The user's "Shared" collection: feed memes reposted to their personal page.
/// Local-first; syncs to Supabase when signed in. Anonymous users get a
/// device-local collection under the "local" uid.
@MainActor
final class RepostService: ObservableObject {
    @Published private(set) var reposts: [Repost] = []

    private let supabase = SupabaseManager.shared
    private var userId = "local"

    private func key(for uid: String) -> String { "gifscroll.reposts.\(uid)" }

    func isShared(itemId: String) -> Bool {
        reposts.contains { $0.itemId == itemId }
    }

    func share(item: FeedItem, userId: String?) {
        let uid = userId ?? "local"
        if uid != self.userId {
            self.userId = uid
            loadCached()
        }
        guard !isShared(itemId: item.id) else { return }

        let repost = Repost(item: item)
        reposts.insert(repost, at: 0)
        saveCached()

        guard uid != "local" else { return }
        Task {
            do {
                let saved = try await supabase.insertRepost(repost, userId: uid)
                if let idx = reposts.firstIndex(where: { $0.id == repost.id }) {
                    reposts[idx] = saved
                    saveCached()
                }
            } catch {
                // Stays local-only; refresh() will pick up the server copy later.
            }
        }
    }

    func unshare(_ repost: Repost) {
        reposts.removeAll { $0.id == repost.id }
        saveCached()
        guard userId != "local" else { return }
        let id = repost.id
        Task { try? await supabase.deleteRepost(id: id) }
    }

    func refresh(userId: String?) async {
        let uid = userId ?? "local"
        if uid != self.userId { self.userId = uid }
        guard uid != "local" else {
            loadCached()
            return
        }
        do {
            reposts = try await supabase.fetchReposts(userId: uid)
            saveCached()
        } catch {
            loadCached()
        }
    }

    // MARK: - Private

    private func loadCached() {
        guard let data = UserDefaults.standard.data(forKey: key(for: userId)),
              let decoded = try? JSONDecoder().decode([Repost].self, from: data)
        else {
            reposts = []
            return
        }
        reposts = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func saveCached() {
        if let data = try? JSONEncoder().encode(reposts) {
            UserDefaults.standard.set(data, forKey: key(for: userId))
        }
    }
}
