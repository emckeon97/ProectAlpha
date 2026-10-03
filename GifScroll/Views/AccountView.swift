import SwiftUI

/// The account tab: the personal page when signed in, the auth form otherwise.
struct AccountView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        Group {
            if auth.isSignedIn {
                ProfileView()
            } else {
                NavigationStack {
                    AuthView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.ignoresSafeArea())
                        .navigationTitle("Account")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.black, for: .navigationBar)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                }
            }
        }
    }
}
