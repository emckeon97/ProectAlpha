import Foundation

/// Owns the Supabase auth session: sign up, sign in, sign out.
/// The session token is persisted so sign-in survives app restarts.
@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var email: String?
    @Published private(set) var displayName: String?
    @Published private(set) var isSignedIn = false

    private let tokenKey = "gifscroll.authToken"
    private let emailKey = "gifscroll.authEmail"
    private let nameKey = "gifscroll.authName"

    init() {
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            SupabaseManager.shared.authToken = token
            email = UserDefaults.standard.string(forKey: emailKey)
            displayName = UserDefaults.standard.string(forKey: nameKey)
            isSignedIn = true
        }
    }

    var currentDisplayName: String { displayName ?? "anon" }

    /// Returns true when signed in immediately, false when email confirmation is pending.
    func signUp(email: String, password: String, displayName: String) async throws -> Bool {
        let result = try await SupabaseManager.shared.signUp(
            email: email, password: password, displayName: displayName
        )
        guard let token = result.accessToken else { return false }
        persist(token: token, email: result.email ?? email, displayName: displayName)
        return true
    }

    func signIn(email: String, password: String) async throws {
        let result = try await SupabaseManager.shared.signIn(email: email, password: password)
        guard let token = result.accessToken else { throw SupabaseError.badPayload }
        let name = (result.email ?? email).split(separator: "@").first.map(String.init) ?? "anon"
        persist(token: token, email: result.email ?? email, displayName: name)
    }

    func signOut() {
        SupabaseManager.shared.authToken = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
        email = nil
        displayName = nil
        isSignedIn = false
    }

    // MARK: - Private

    private func persist(token: String, email: String, displayName: String) {
        SupabaseManager.shared.authToken = token
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(displayName, forKey: nameKey)
        self.email = email
        self.displayName = displayName
        isSignedIn = true
    }
}
