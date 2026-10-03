import SwiftUI

/// The account tab: sign in/up form, or the signed-in profile with sign out.
struct AccountView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        NavigationStack {
            Group {
                if auth.isSignedIn {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text(auth.displayName ?? "anon")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        if let email = auth.email {
                            Text(email)
                                .foregroundColor(.gray)
                        }
                        Button("Sign Out") { auth.signOut() }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        Spacer()
                    }
                    .padding()
                } else {
                    AuthView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("GifScroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
