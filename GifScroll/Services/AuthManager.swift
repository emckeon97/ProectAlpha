import Foundation

/// Owns the Supabase auth session: sign up, sign in, sign out.
/// The session token is persisted so sign-in survives app restarts.
@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var email: String?
    @Published private(set) var displayName: String?
    @Published private(set) var userId: String?
    @Published private(set) var isSignedIn = false

    private let tokenKey = "gifscroll.authToken"
    private let refreshKey = "gifscroll.authRefreshToken"
    private let emailKey = "gifscroll.authEmail"
    private let nameKey = "gifscroll.authName"
    private let userIdKey = "gifscroll.authUserId"

    init() {
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            SupabaseManager.shared.authToken = token
            email = UserDefaults.standard.string(forKey: emailKey)
            displayName = UserDefaults.standard.string(forKey: nameKey)
            userId = UserDefaults.standard.string(forKey: userIdKey)
            isSignedIn = true
            // Refresh the session in the background — access tokens expire after 1 hour.
            Task { await self.refreshSession() }
        }
    }

    var currentDisplayName: String { displayName ?? "anon" }

    /// Returns true when signed in immediately, false when email confirmation is pending.
    func signUp(email: String, password: String, displayName: String) async throws -> Bool {
        let result = try await SupabaseManager.shared.signUp(
            email: email, password: password, displayName: displayName
        )
        guard let token = result.accessToken else { return false }
        persist(token: token, refreshToken: result.refreshToken, email: result.email ?? email, displayName: displayName, userId: result.userID)
        return true
    }

    func signIn(email: String, password: String) async throws {
        let result = try await SupabaseManager.shared.signIn(email: email, password: password)
        guard let token = result.accessToken else { throw SupabaseError.badPayload }
        let name = (result.email ?? email).split(separator: "@").first.map(String.init) ?? "anon"
        persist(token: token, refreshToken: result.refreshToken, email: result.email ?? email, displayName: name, userId: result.userID)
    }

    func signOut() {
        SupabaseManager.shared.authToken = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        email = nil
        displayName = nil
        userId = nil
        isSignedIn = false
    }

    /// Refresh the access token using the stored refresh token.
    /// Call this before sync operations — access tokens expire after 1 hour.
    func refreshSession() async {
        guard let refreshToken = UserDefaults.standard.string(forKey: refreshKey) else { return }
        do {
            let result = try await SupabaseManager.shared.refreshSession(refreshToken: refreshToken)
            guard let token = result.accessToken else { return }
            SupabaseManager.shared.authToken = token
            UserDefaults.standard.set(token, forKey: tokenKey)
            if let newRefresh = result.refreshToken {
                UserDefaults.standard.set(newRefresh, forKey: refreshKey)
            }
        } catch {
            // If refresh fails, sign out — the session is dead.
            signOut()
        }
    }

    // MARK: - Private

    private func persist(token: String, email: String, displayName: String, userId: String?) {
        SupabaseManager.shared.authToken = token
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(displayName, forKey: nameKey)
        if let userId {
            UserDefaults.standard.set(userId, forKey: userIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userIdKey)
        }
        self.email = email
        self.displayName = displayName
        self.userId = userId
        isSignedIn = true
    }

    private func persist(token: String, refreshToken: String?, email: String, displayName: String, userId: String?) {
        if let refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: refreshKey)
        }
        persist(token: token, email: email, displayName: displayName, userId: userId)
    }
}
