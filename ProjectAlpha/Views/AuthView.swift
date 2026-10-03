import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthManager

    @State private var mode = 0 // 0 = sign in, 1 = sign up
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var notice: String?

    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $mode) {
                Text("Sign In").tag(0)
                Text("Sign Up").tag(1)
            }
            .pickerStyle(.segmented)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            if mode == 1 {
                TextField("Display name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            if let notice {
                Text(notice)
                    .foregroundColor(.green)
                    .font(.caption)
            }

            Button { submit() } label: {
                if isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text(mode == 0 ? "Sign In" : "Create Account").bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(
                isWorking || email.isEmpty || password.isEmpty
                    || (mode == 1 && displayName.isEmpty)
            )
        }
        .padding()
    }

    private func submit() {
        isWorking = true
        errorMessage = nil
        notice = nil
        Task {
            do {
                if mode == 0 {
                    try await auth.signIn(email: email, password: password)
                } else {
                    let immediate = try await auth.signUp(
                        email: email, password: password, displayName: displayName
                    )
                    if !immediate {
                        notice = "Account created — check your email to confirm, then sign in."
                    }
                }
            } catch {
                errorMessage = "That didn't work. Check your details and try again."
            }
            isWorking = false
        }
    }
}
